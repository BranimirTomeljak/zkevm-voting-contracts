# zkEVM Voting: Contracts

[![CI](https://github.com/BranimirTomeljak/zkevm-voting-contracts/actions/workflows/test.yml/badge.svg)](https://github.com/BranimirTomeljak/zkevm-voting-contracts/actions/workflows/test.yml)

Solidity contracts for the on-chain voting system built for my MSc thesis, *Non-interactive Zero-Knowledge proofs in blockchain* (FER Zagreb, 2025). They were deployed to the Polygon zkEVM Cardona testnet. The React client is in [zkevm-voting-app](https://github.com/BranimirTomeljak/zkevm-voting-app).

## Contracts

**`Election.sol`** runs one election at a time through three states: Preparing, Active and Ended.

- The owner adds candidates, starts and ends the election, and can open a new one. Results of every ended election stay on-chain.
- Each address can vote once per election, and only if the verification contract reports it as verified.
- Events are emitted for added candidates, votes, and the start and end of each election.

**`UserVerification.sol`** decides who may vote. The owner verifies and unverifies addresses.

> **Demo simplification.** For the thesis demo, `verifySelf()` lets any address verify itself, so eligibility is not actually restricted. A production version would replace the list with a zero-knowledge proof of eligibility, such as a Semaphore-style group membership proof with a nullifier, so a voter proves they are allowed to vote, and vote only once, without revealing which identity they are.

## Where zero knowledge comes in

Polygon zkEVM is a ZK rollup: every batch of transactions, votes included, is proven correct with a validity proof that is verified on Ethereum. The contracts themselves use no ZK cryptography. The thesis covers the proof systems behind this, and the note above describes the application-level ZK step a real election would need.

## Development

Built with [Foundry](https://book.getfoundry.sh/) (Solidity 0.8.20, optimizer on).

```bash
forge build
forge test      # voting, double-vote and unverified-voter checks, full election lifecycle
forge fmt --check
```

CI runs the format check, build and tests on every push and pull request.

### Deploy and operate

```bash
export PRIVATE_KEY=...
export CARDONA_RPC=https://rpc.cardona.zkevm-rpc.com

forge script script/Deploy.s.sol:DeployScript --rpc-url $CARDONA_RPC --private-key $PRIVATE_KEY --broadcast --legacy

export ELECTION=<election address> USER_VERIFICATION=<verifier address>
cast send $ELECTION "addCandidates(uint256[],string[])" "[1,2]" "[\"Alice\",\"Bob\"]" --rpc-url $CARDONA_RPC --private-key $PRIVATE_KEY --legacy
cast send $ELECTION "startElection()" --rpc-url $CARDONA_RPC --private-key $PRIVATE_KEY --legacy
cast send $ELECTION "vote(uint256)" 1 --rpc-url $CARDONA_RPC --private-key $PRIVATE_KEY --legacy
cast send $ELECTION "endElection()" --rpc-url $CARDONA_RPC --private-key $PRIVATE_KEY --legacy
```

The remaining `cast` commands (new election, verifying and unverifying users) are listed at the end of `script/Deploy.s.sol`.

### Thesis deployment (Cardona testnet, 2025)

| Contract | Address |
|---|---|
| Election | `0x3de7139645A8045ed77d1c7094Ed4f4F10Cb644e` |
| UserVerification | `0x03c8Bac7bfe9EC8A59B7b3F0040838c36c2569c7` |
