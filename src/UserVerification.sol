// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract UserVerification {
    // State variables
    address public immutable owner;

    // Verified users mapping
    mapping(address => bool) private _verifiedUsers;

    // Events
    event UserVerified(address indexed user);
    event UserUnverified(address indexed user);
    event SelfVerified(address indexed user);

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
        require(_user != address(0), "Invalid address");
        _verifiedUsers[_user] = true;
        emit UserVerified(_user);
    }

    function verifyUsersBatch(address[] calldata _users) external onlyOwner {
        require(_users.length > 0, "Empty batch");

        for (uint i = 0; i < _users.length; i++) {
            require(_users[i] != address(0), "Invalid address");
            _verifiedUsers[_users[i]] = true;
            emit UserVerified(_users[i]);
        }
    }

    function unverifyUser(address _user) external onlyOwner {
        require(_user != address(0), "Invalid address");
        _verifiedUsers[_user] = false;
        emit UserUnverified(_user);
    }

    // ============ Self-Verification Function ============

    function verifySelf() external {
        require(msg.sender != address(0), "Invalid address");
        _verifiedUsers[msg.sender] = true;
        emit SelfVerified(msg.sender);
    }

    // ============ View Functions ============

    function isUserVerified(address _user) external view returns (bool) {
        return _verifiedUsers[_user];
    }
}
