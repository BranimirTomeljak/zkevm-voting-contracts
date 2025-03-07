// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../src/MockUserVerification.sol";
import "../src/Election.sol";

contract ElectionTest is Test {
    MockUserVerification verifier;
    Election election;

    address user = address(0x123);

    function setUp() public {
        // Deploy verifier
        verifier = new MockUserVerification();

        // Deploy election referencing the verifier
        election = new Election(address(verifier));
    }

    function testRegisterAndVote() public {
        // 1. Owner verifies user
        verifier.verifyUser(user);

        // 2. user registers
        vm.prank(user);
        election.registerToVote();

        // 3. owner adds candidate, starts election
        election.addCandidate(1, "Alice");
        election.startElection();

        // 4. user votes
        vm.prank(user);
        election.vote(1);

        // check candidate's vote count
        (, uint256 voteCount) = election.getCandidate(1);
        assertEq(voteCount, 1, "Candidate should have 1 vote");
    }

    function testCannotRegisterIfNotVerified() public {
        // user tries to register but hasn't been verified
        vm.prank(user);
        vm.expectRevert(bytes("User not verified"));
        election.registerToVote();
    }
}
