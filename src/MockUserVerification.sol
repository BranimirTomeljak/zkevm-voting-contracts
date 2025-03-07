// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract MockUserVerification {
    // State variables
    address public owner;

    mapping(address => bool) public isUserVerified;

    // Events
    event UserVerified(address indexed user);
    event UserUnverified(address indexed user);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    // Constructor
    constructor() {
        owner = msg.sender;
    }

    // ============ Admin Functions ============

    function verifyUser(address _user) external onlyOwner {
        isUserVerified[_user] = true;
        emit UserVerified(_user);
    }

    function unverifyUser(address _user) external onlyOwner {
        isUserVerified[_user] = false;
        emit UserUnverified(_user);
    }
}
