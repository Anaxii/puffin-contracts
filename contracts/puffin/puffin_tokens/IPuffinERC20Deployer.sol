// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPuffinERC20Deployer {
    function isGlobalPaused() external view returns (bool);
    function isUserPaused(address user) external view returns (bool);
    function isTokenPaused(address user) external view returns (bool);
}
