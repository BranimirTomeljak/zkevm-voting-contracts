// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../src/UserVerification.sol";
import "../src/Election.sol";

contract ElectionTest is Test {
    UserVerification verifier;
    Election election;

    address public owner = address(this);
    address public voter1 = address(0x123);
    address public voter2 = address(0x456);

    function setUp() public {
        // Deploy contracts
        verifier = new UserVerification();
        election = new Election(address(verifier));

        // Verify test users
        verifier.verifyUser(voter1);
        verifier.verifyUser(voter2);
    }

    function testVoting() public {
        // Add candidates
        election.addCandidate(1, "Alice");
        election.addCandidate(2, "Bob");

        // Start election
        election.startElection();

        // Voters vote
        vm.prank(voter1);
        election.vote(1);

        vm.prank(voter2);
        election.vote(2);

        // Check results
        (, uint256 aliceVotes) = election.getCandidate(1);
        (, uint256 bobVotes) = election.getCandidate(2);

        assertEq(aliceVotes, 1, "Alice should have 1 vote");
        assertEq(bobVotes, 1, "Bob should have 1 vote");
    }

    function testUnverifiedUserCannotVote() public {
        // Add candidate and start election
        election.addCandidate(1, "Alice");
        election.startElection();

        // Unverified user tries to vote
        address unverifiedUser = address(0x789);

        vm.prank(unverifiedUser);
        vm.expectRevert("User not verified");
        election.vote(1);
    }

    function testCannotVoteTwice() public {
        // Add candidate and start election
        election.addCandidate(1, "Alice");
        election.startElection();

        // First vote works
        vm.prank(voter1);
        election.vote(1);

        // Second vote fails
        vm.prank(voter1);
        vm.expectRevert("Already voted");
        election.vote(1);
    }

    function testFullElectionLifecycle() public {
        // 1. Add candidates
        election.addCandidate(1, "Alice");
        election.addCandidate(2, "Bob");

        // 2. Start election
        election.startElection();

        // 3. Vote
        vm.prank(voter1);
        election.vote(1);

        vm.prank(voter2);
        election.vote(2);

        // 4. End election
        election.endElection();

        // 5. Verify results are stored
        Election.Candidate[] memory results = election.getPastElectionResults(
            1
        );
        assertEq(results.length, 2, "Should have 2 candidates");
        assertEq(results[0].voteCount, 1, "Alice should have 1 vote");
        assertEq(results[1].voteCount, 1, "Bob should have 1 vote");

        // 6. Create new election
        election.createNewElection();
        assertEq(
            uint(election.getElectionState()),
            uint(Election.ElectionState.Preparing),
            "Should be in preparing state"
        );

        // 7. Add candidates for new election
        election.addCandidate(3, "Charlie");
        election.addCandidate(4, "David");

        // 8. Previous election results should still be accessible
        results = election.getPastElectionResults(1);
        assertEq(
            results.length,
            2,
            "Should still have 2 candidates from previous election"
        );
    }
}
