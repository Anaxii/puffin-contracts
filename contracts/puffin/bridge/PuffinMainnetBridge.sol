// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./PuffinBridge.sol";
import "../../util/ReentrancyGuard.sol";
import "../../util/IERC20.sol";
import "../approvals/IPuffinApprovals.sol";

contract PuffinMainnetbridge is PuffinBridge, ReentrancyGuard  {

    constructor(uint256 _chainId) PuffinBridge(_chainId) {

    }

    function proposeOut(
        address asset,
        address user,
        uint256 amount,
        bytes32 requestId,
        uint256 fromChainId
    ) external whenNotPaused nonReentrant {
        require(IPuffinApprovals(puffinAssets).isApproved(asset), "PuffinBridge: Asset is not approved");
        require(!bridgeOutComplete[requestId], "PuffinBridge: Request already complete");
        require(isVoter[msg.sender], "PuffinBridge: Not a voter");
        require(!hasVoted[msg.sender][requestId], "PuffinBridge: User has voted");

        hasVoted[msg.sender][requestId] = true;

        if (threshold == 0)
            require(msg.sender == owner());

        if (requestCount[requestId] == 0) {
            requestInfo[requestId] = BridgeRequest(requestId, user, asset, amount, (block.timestamp + (1 days)));
            requestCount[requestId] ++;
        } else {
            require(requestInfo[requestId].user == user && requestInfo[requestId].asset == asset && requestInfo[requestId].amount == amount, "PuffinBridge: Invalid input");
            requestCount[requestId] ++;
        }

        if (requestCount[requestId] >= threshold) {
            bridgeOutComplete[requestId] = true;
            if (IERC20(asset).balanceOf(address(this)) < amount) {
                emit BridgeOutWarm(user, asset, amount, requestId, fromChainId);
                requiresWarmWallet[requestId] = true;
                return;
            }
            emit BridgeOut(user, asset, amount, requestId, fromChainId);

            IERC20(asset).transfer(user, amount);
        }
    }

    function bridgeIn(
        uint256 amount,
        address asset
    ) public whenNotPaused {
        require(IPuffinApprovals(puffinKYC).isApproved(msg.sender), "PuffinBridge: User is not KYC approved");
        require(IPuffinApprovals(puffinAssets).isApproved(asset), "PuffinBridge: Asset is not approved");
        require(amount > 0);

        bytes32 id = keccak256(abi.encodePacked(amount, msg.sender, block.timestamp, asset));
        require(!bridgeIds[id], "PuffinBridge: Invalid ID, try again");
        bridgeIds[id] = true;
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
        emit BridgeIn(msg.sender, asset, amount, id, chainId);
    }
}
