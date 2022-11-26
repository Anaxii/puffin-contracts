// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../util/Ownable.sol";

contract PuffinApprovals is Ownable {

    mapping(address => bool) public isApproved;
    mapping(address => bool) public canApprove;

    event ApprovalUpdate(address indexed user, bool indexed status);

    function approve(address user) external {
        require(canApprove[msg.sender]);
        isApproved[user] = true;
    }

    function remove(address user) external {
        require(canApprove[msg.sender]);
        isApproved[user] = false;
    }

    function allowApprove(address user) external onlyOwner {
        canApprove[user] = true;
        emit ApprovalUpdate(user, true);
    }

    function removeApprove(address user) external onlyOwner {
        canApprove[user] = false;
        emit ApprovalUpdate(user, false);
    }
}
