// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {UserVerification} from "../src/UserVerification.sol";
import {Election} from "../src/Election.sol";

contract DeployScript is Script {
    UserVerification public verifier;
    Election public election;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        verifier = new UserVerification();
        election = new Election(address(verifier));

        vm.stopBroadcast();

        console.log("UserVerification deployed at:", address(verifier));
        console.log("Election deployed at:", address(election));
    }
}

// export PRIVATE_KEY=
// export USER_VERIFICATION=
// export ELECTION=

// na FE kopirat abi fileove

/*
Deploy contracts:
forge script script/Deploy.s.sol:DeployScript --rpc-url https://rpc.cardona.zkevm-rpc.com --private-key $PRIVATE_KEY --broadcast --legacy

Add a Candidate:
cast send $ELECTION "addCandidates(uint256[],string[])" "[1,2]" "[\"Alice\",\"Bob\"]" --rpc-url https://rpc.cardona.zkevm-rpc.com --private-key $PRIVATE_KEY --legacy

Start the Election:
cast send $ELECTION "startElection()" --rpc-url https://rpc.cardona.zkevm-rpc.com --private-key $PRIVATE_KEY --legacy

End the Election:
cast send $ELECTION "endElection()" --rpc-url https://rpc.cardona.zkevm-rpc.com --private-key $PRIVATE_KEY --legacy

Create a New Election:
cast send $ELECTION "createNewElection()" --rpc-url https://rpc.cardona.zkevm-rpc.com --private-key $PRIVATE_KEY --legacy

Vote for a Candidate:
cast send $ELECTION "vote(uint256)" 1 --rpc-url https://rpc.cardona.zkevm-rpc.com --private-key $PRIVATE_KEY --legacy

Verify a User (Admin Only):
cast send $USER_VERIFICATION "verifyUser(address)" 0xUserToVerify --rpc-url https://rpc.cardona.zkevm-rpc.com --private-key $PRIVATE_KEY --legacy

Unverify a User (Admin Only):
cast send $USER_VERIFICATION "unverifyUser(address)" 0xUserToUnverify --rpc-url https://rpc.cardona.zkevm-rpc.com --private-key $PRIVATE_KEY --legacy

Self-Verify as a User:
cast send $USER_VERIFICATION "verifySelf()" --rpc-url https://rpc.cardona.zkevm-rpc.com --private-key $PRIVATE_KEY --legacy

Check if a User is Verified:
cast call $USER_VERIFICATION "isUserVerified(address)" 0xUserToCheck --rpc-url https://rpc.cardona.zkevm-rpc.com

Get All Candidates:
cast call $ELECTION "getAllCandidates()" --rpc-url https://rpc.cardona.zkevm-rpc.com

Get Past Election Results:
cast call $ELECTION "getPastElectionResults(uint256)" 1 --rpc-url https://rpc.cardona.zkevm-rpc.com

Get Current Leader:
cast call $ELECTION "getCurrentLeader()" --rpc-url https://rpc.cardona.zkevm-rpc.com

Check if a User Has Voted:
cast call $ELECTION "hasUserVoted(address)" 0xUserToCheck --rpc-url https://rpc.cardona.zkevm-rpc.com
*/