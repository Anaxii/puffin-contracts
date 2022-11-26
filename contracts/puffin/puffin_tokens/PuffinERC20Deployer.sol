// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../util/Ownable.sol";
import "../approvals/IPuffinApprovals.sol";
import "./PuffinERC20.sol";

contract PuffinERC20Deployer is Ownable {

    address public puffinApprovedAssets;

    bool public isGlobalPaused;

    mapping(address => bool) public isUserPaused;
    mapping(address => bool) public isTokenPaused;
    mapping(address => bool) public isMinter;

    mapping(address => uint256) public mainnetTokenChainID;

    mapping(address => address) public mainnetToSubnetTokenAddress;
    mapping(uint256 => address) public chainIdToMainnetTokenAddress;
    mapping(address => mapping(uint256 => address)) public subnetToMainnetTokenAddress;

    event NewToken(address indexed mainnetToken, address indexed subnetToken, uint256 indexed chainId);
    event NewMainnetToken(address indexed mainnetToken, address indexed subnetToken, uint256 indexed chainId);
    event Mint(address indexed token, address indexed user, uint256 indexed amount);
    event Burn(address indexed token, address indexed user, uint256 indexed amount);

    function setNewMainnetToken(
        address mainnetToken,
        address subnetToken,
        uint256 chainId,
        string memory name,
        string memory symbol
    ) external onlyOwner {
        if (mainnetToken == subnetToken) {
            require(IPuffinApprovals(puffinApprovedAssets).isApproved(mainnetToken), "PuffinERC20Deployer: Token isnt allowed");
            require(mainnetToSubnetTokenAddress[mainnetToken] == address(0), "PuffinERC20Deployer: Subnet token already exists");
            PuffinERC20 newToken = new PuffinERC20(name, symbol);
            require(subnetToMainnetTokenAddress[address(newToken)][chainId] == address(0), "PuffinERC20Deployer: ChainID already exists");
            subnetToMainnetTokenAddress[address(newToken)][chainId] = mainnetToken;
            mainnetToSubnetTokenAddress[mainnetToken] = address(newToken);
            mainnetTokenChainID[mainnetToken] = chainId;
            chainIdToMainnetTokenAddress[chainId] = mainnetToken;
            emit NewToken(mainnetToken, subnetToken, chainId);
        } else {
            require(PuffinERC20(subnetToken).isPuffinERC20());
            require(IPuffinApprovals(puffinApprovedAssets).isApproved(mainnetToken), "PuffinERC20Deployer: Token isnt allowed");
            require(subnetToMainnetTokenAddress[subnetToken][chainId] == address(0), "PuffinERC20Deployer: ChainID already exists");
            subnetToMainnetTokenAddress[subnetToken][chainId] = mainnetToken;
            mainnetToSubnetTokenAddress[mainnetToken] = subnetToken;
            mainnetTokenChainID[mainnetToken] = chainId;
            chainIdToMainnetTokenAddress[chainId] = mainnetToken;
            emit NewMainnetToken(mainnetToken, subnetToken, chainId);
        }
    }

    function mint(
        address token,
        address recipient,
        uint256 amount,
        uint256 _type
    ) external {
        require(isMinter[_msgSender()], "PuffinERC20Deployer: Sender is not a minter");
        PuffinERC20 _contract;
        if (_type == 0) {
            _contract = PuffinERC20(token);
        } else {
            _contract = PuffinERC20(mainnetToSubnetTokenAddress[token]);
        }
        _contract.mint(amount);
        _contract.transfer(recipient, amount);
        emit Mint(address(_contract), recipient, amount);
    }

    function burn(
        address token,
        address from,
        uint256 amount,
        uint256 _type
    ) external {
        require(isMinter[_msgSender()], "PuffinERC20Deployer: Sender is not a minter");
        PuffinERC20 _contract;
        if (_type == 0) {
            _contract = PuffinERC20(token);
        } else {
            _contract = PuffinERC20(mainnetToSubnetTokenAddress[token]);
        }
        _contract.transferFrom(from, address(this), amount);
        _contract.burn(amount);
        emit Burn(address(_contract), from, amount);
    }

    function setPuffinApprovedAssets(address _contract) external onlyOwner {
        puffinApprovedAssets = _contract;
    }

    function setMinter(address _minter, bool status) external onlyOwner {
        isMinter[_minter] = status;
    }

    function setPause(uint256 _type, address account, bool pauseStatus) external onlyOwner {
        if (_type == 0) {
            isGlobalPaused = pauseStatus;
        } else if (_type == 1) {
            isTokenPaused[account] = pauseStatus;
        } else if (_type == 2) {
            isUserPaused[account] = pauseStatus;
        }
    }
}
