// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../util/Ownable.sol";
import "../../util/ERC20.sol";
import "../../util/IAllowList.sol";
import "./IPuffinERC20Deployer.sol";

contract PuffinERC20 is ERC20, Ownable {

    bool public isPuffinERC20 = true;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {

    }

    function mint(uint256 amount) external onlyOwner {
        _mint(owner(), amount);
    }

    function burn(uint256 amount) external onlyOwner {
        _burn(owner(), amount);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) override public returns (bool) {
        require(IAllowList(0x0200000000000000000000000000000000000002).readAllowList(recipient) > 0, "PuffinERC20: User unauthorized");
        require(!IPuffinERC20Deployer(owner()).isGlobalPaused(), "PuffinERC20: Global Pause");
        require(!IPuffinERC20Deployer(owner()).isUserPaused(_msgSender()), "PuffinERC20: User Pause");
        require(!IPuffinERC20Deployer(owner()).isTokenPaused(address(this)), "PuffinERC20: Token Pause");
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        require(!IPuffinERC20Deployer(owner()).isGlobalPaused(), "PuffinERC20: Global Pause");
        require(!IPuffinERC20Deployer(owner()).isUserPaused(_msgSender()), "PuffinERC20: User Pause");
        require(!IPuffinERC20Deployer(owner()).isUserPaused(recipient), "PuffinERC20: Recipient Pause");
        require(!IPuffinERC20Deployer(owner()).isTokenPaused(address(this)), "PuffinERC20: Token Pause");
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
    }
    _transfer(sender, recipient, amount);

    return true;
    }
}
