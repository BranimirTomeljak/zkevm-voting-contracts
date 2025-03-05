// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import "../src/MockUserVerification.sol";
import "../src/Election.sol";

contract DeployScript is Script {
    function run() external {
        // 1. Start broadcast (tell Foundry to sign tx with our private key)
        vm.startBroadcast();

        // 2. Deploy MockUserVerification
        MockUserVerification verifier = new MockUserVerification();

        // 3. Deploy Election, referencing the verifier
        Election election = new Election(address(verifier));

        // 4. Stop broadcast
        vm.stopBroadcast();

        // Optionally, log the addresses
        console.log("MockUserVerification deployed at:", address(verifier));
        console.log("Election deployed at:", address(election));
    }
}

// prvo: export FOUNDRY_PVT_KEY=0xPlaceholder
// pa za provjeru: echo $FOUNDRY_PVT_KEY
// forge script script/Deploy.s.sol --profile cardonaZkEVM --broadcast

/*
Add a Candidate:
cast send 0xElectionAddress "addCandidate(uint256,string)" 1 "Alice" --rpc-url https://rpc.cardona.zkevm-rpc.com --private-key $FOUNDRY_PVT_KEY

Start the Election:
cast send 0xElectionAddress "startElection()" --rpc-url https://rpc.cardona.zkevm-rpc.com --private-key $FOUNDRY_PVT_KEY

Verify a User:
cast send 0xVerifierAddress "verifyUser(address)" 0xUserToVerify --rpc-url https://rpc.cardona.zkevm-rpc.com --private-key $FOUNDRY_PVT_KEY

User then calls registerToVote() and vote(...) from their own address. They can do it either in a front-end dApp or via cast.
*/