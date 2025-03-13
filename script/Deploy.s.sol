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

// prvo: export PRIVATE_KEY=placeholder
// pa za provjeru: echo $PRIVATE_KEY
// forge build
// na FE kopirat abi fileove (i okruzit ih s [])
// forge script script/Deploy.s.sol:DeployScript --rpc-url https://rpc.cardona.zkevm-rpc.com --private-key $PRIVATE_KEY --broadcast --legacy
// forge script script/Deploy.s.sol --profile cardonaZkEVM --broadcast

/*
Add a Candidate:
cast send 0xElectionAddress "addCandidate(uint256,string)" 1 "Alice" --rpc-url https://rpc.cardona.zkevm-rpc.com --private-key $PRIVATE_KEY

Start the Election:
cast send 0xElectionAddress "startElection()" --rpc-url https://rpc.cardona.zkevm-rpc.com --private-key $PRIVATE_KEY

Verify a User:
cast send 0xVerifierAddress "verifyUser(address)" 0xUserToVerify --rpc-url https://rpc.cardona.zkevm-rpc.com --private-key $PRIVATE_KEY

User then calls registerToVote() and vote(...) from their own address. They can do it either in a front-end dApp or via cast.
*/
