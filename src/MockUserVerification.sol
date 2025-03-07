// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * @title MockUserVerification
 * @dev Mocks user verification logic.
 * In a real app, you'd do KYC, ID checks, or on-chain proofs.
 * Here, we simply store booleans in a mapping.
 */
contract MockUserVerification {
    address public owner;

    // Tracks which users are considered "verified"
    mapping(address => bool) public isUserVerified;

    event UserVerified(address indexed user);
    event UserUnverified(address indexed user);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Mock a user verification.
     * In real scenario, you'd do checks/off-chain logic, etc.
     */
    function verifyUser(address _user) external onlyOwner {
        isUserVerified[_user] = true;
        emit UserVerified(_user);
    }

    /**
     * @dev Unverify a user (for example, if they fail some subsequent check).
     */
    function unverifyUser(address _user) external onlyOwner {
        isUserVerified[_user] = false;
        emit UserUnverified(_user);
    }
}
