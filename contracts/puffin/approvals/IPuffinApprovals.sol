// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


interface IPuffinApprovals {
    function isApproved(address user) external view returns (bool);
    function canApprove(address user) external view returns (bool);
}
