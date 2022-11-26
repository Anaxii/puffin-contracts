// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./PuffinBridge.sol";
import "../../util/IERC20.sol";
import "../../util/ReentrancyGuard.sol";
import "../../util/IAllowList.sol";
import "../puffin_tokens/PuffinERC20Deployer.sol";

contract PuffinSubnetbridge is PuffinBridge, ReentrancyGuard  {

    constructor(uint256 _chainId) PuffinBridge(_chainId) {

    }

    function proposeOut(
        address asset,
        address user,
        uint256 amount,
        bytes32 requestId,
        uint256 fromChainId
    ) public whenNotPaused nonReentrant {
        require(!bridgeOutComplete[requestId], "PuffinBridge: Request already complete");
        require(isVoter[msg.sender], "PuffinBridge: Not a voter");
        require(!hasVoted[msg.sender][requestId], "PuffinBridge: User has voted");

        hasVoted[msg.sender][requestId] = true;

        if (threshold == 0)
            require(msg.sender == owner(), "PuffinBridge: Threshold 0 not owner");

        if (requestCount[requestId] == 0) {
            requestInfo[requestId] = BridgeRequest(requestId, user, asset, amount, (block.timestamp + (1 days)));
            requestCount[requestId] ++;
        } else {
            require(requestInfo[requestId].user == user && requestInfo[requestId].asset == asset && requestInfo[requestId].amount == amount, "PuffinBridge: Invalid input");
            requestCount[requestId] ++;
        }

        if (requestCount[requestId] >= threshold) {
            bridgeOutComplete[requestId] = true;
            PuffinERC20Deployer(subnetTokenDeployer).mint(asset, user, amount, 1);
            emit BridgeOut(user, asset, amount, requestId, fromChainId);
        }
    }

    function bridgeIn(
        uint256 amount,
        address asset,
        uint256 chainId
    ) public whenNotPaused {
        require(IAllowList(0x0200000000000000000000000000000000000002).readAllowList(msg.sender) > 0, "PuffinBridge: User is not KYC approved");
        require(amount > 0, "PuffinBridge: Amount == 0");

        bytes32 id = keccak256(abi.encodePacked(amount, msg.sender, block.timestamp, asset));
        require(!bridgeIds[id], "PuffinBridge: Invalid ID, try again");
        bridgeIds[id] = true;
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
        IERC20(asset).approve(subnetTokenDeployer, amount);
        PuffinERC20Deployer(subnetTokenDeployer).burn(asset, address(this), amount, 0);
        emit BridgeIn(msg.sender, PuffinERC20Deployer(subnetTokenDeployer).subnetToMainnetTokenAddress(asset, chainId), amount, id, chainId);
    }
}
