// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../util/Ownable.sol";
import "../../util/Pausable.sol";
import "../../util/ERC20.sol";

abstract contract PuffinBridge is Ownable, Pausable {

    uint256 public threshold = 0;
    uint256 public chainId;
    mapping(address => bool) public isVoter;

    address public puffinKYC;
    address public puffinAssets;
    address public puffinWarmWallet;
    address public subnetTokenDeployer;

    mapping(bytes32 => bool) public bridgeInComplete;
    mapping(bytes32 => bool) public bridgeOutComplete;
    mapping(bytes32 => bool) public bridgeIds;
    mapping(bytes32 => bool) public requiresWarmWallet;

    mapping(bytes32 => uint256) public requestCount;
    mapping(address => mapping(bytes32 => bool)) public hasVoted;

    mapping(bytes32 => BridgeRequest) public requestInfo;

    event BridgeIn(address indexed user, address indexed asset, uint256 indexed amount, bytes32 id, uint256 chainId);
    event BridgeOut(address indexed user, address indexed asset, uint256 indexed amount, bytes32 id, uint256 chainId);
    event BridgeOutWarm(address indexed user, address indexed asset, uint256 indexed amount, bytes32 id, uint256 chainId);
    event BridgeOutCanceled(address indexed user, bytes32 indexed id);

    struct BridgeRequest {
        bytes32 id;
        address user;
        address asset;
        uint256 amount;
        uint256 expiry;
    }

    constructor(uint256 _chainId) {
        isVoter[msg.sender] = true;
        puffinWarmWallet = msg.sender;
        chainId = _chainId;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function markInComplete(bytes32 requestId) public {
        require(isVoter[msg.sender]);
        require(!bridgeInComplete[requestId], "PuffinBridge: Request already complete");
        bridgeInComplete[requestId] = true;
    }

    function cancelOut(bytes32 requestId) public onlyOwner {
        require(!bridgeOutComplete[requestId], "PuffinBridge: Request already complete");
        bridgeOutComplete[requestId] = true;
        emit BridgeOutCanceled(msg.sender, requestId);
    }

    function setThreshold(uint256 _threshold) external onlyOwner {
        threshold = _threshold;
    }

    function addVoter(address user) external onlyOwner {
        isVoter[user] = true;
    }

    function removeVoter(address user) external onlyOwner {
        isVoter[user] = false;
    }

    function setKYC(address _contract) external onlyOwner {
        puffinKYC = _contract;
    }

    function setAssets(address _contract) external onlyOwner {
        puffinAssets = _contract;
    }

    function setWarm(address _contract) external onlyOwner {
        puffinWarmWallet = _contract;
    }

    function setSubnetTokenDeployer(address _contract) external onlyOwner {
        subnetTokenDeployer = _contract;
    }

    function transferWarm(address asset, uint256 amount) external onlyOwner {
        IERC20(asset).transfer(puffinWarmWallet, amount);
    }

    function getRequestInfo(
        bytes32 requestId
    ) public view returns (BridgeRequest memory) {
        return requestInfo[requestId];
    }
}
