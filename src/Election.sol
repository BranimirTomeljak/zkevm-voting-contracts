// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface IMockUserVerification {
    function isUserVerified(address user) external view returns (bool);
}

/**
 * @title Election
 * @dev A simple voting contract referencing a mock user verification contract.
 */
contract Election {
    address public owner;
    bool public isElectionActive;

    // Reference to a mock user verification contract (whitelisting / gating)
    IMockUserVerification public userVerifier;

    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
    }

    // Array of candidates
    Candidate[] public candidates;

    // Maps candidate ID -> index in the `candidates` array
    mapping(uint256 => uint256) private candidateIndex;

    // Track who’s registered and who has voted
    mapping(address => bool) public registeredVoters;
    mapping(address => bool) public hasVoted;

    event CandidateAdded(uint256 indexed id, string name);
    event VoterRegistered(address indexed voter);
    event VoteCasted(address indexed voter, uint256 candidateId);
    event ElectionStarted();
    event ElectionEnded();

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    modifier onlyWhenActive() {
        require(isElectionActive, "Election is not active");
        _;
    }

    constructor(address _verifierAddress) {
        require(_verifierAddress != address(0), "Invalid verifier address");
        owner = msg.sender;
        userVerifier = IMockUserVerification(_verifierAddress);
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function getElectionStatus() external view returns (bool) {
        return isElectionActive;
    }

    /**
     * @dev Add a candidate (owner only), but only before the election starts.
     */
    function addCandidate(uint256 _id, string memory _name) external onlyOwner {
        require(
            !isElectionActive,
            "Cannot add candidates while election is active"
        );
        candidates.push(Candidate(_id, _name, 0));
        candidateIndex[_id] = candidates.length - 1;
        emit CandidateAdded(_id, _name);
    }

    /**
     * @dev Register to vote, requiring user is "verified" (mock verification).
     */
    function registerToVote() external {
        require(!registeredVoters[msg.sender], "Already registered");
        require(userVerifier.isUserVerified(msg.sender), "User not verified");

        registeredVoters[msg.sender] = true;
        emit VoterRegistered(msg.sender);
    }

    /**
     * @dev Start the election (owner only).
     */
    function startElection() external onlyOwner {
        require(!isElectionActive, "Election already active");
        isElectionActive = true;
        emit ElectionStarted();
    }

    /**
     * @dev End the election (owner only).
     */
    function endElection() external onlyOwner {
        require(isElectionActive, "Election is not active");
        isElectionActive = false;
        emit ElectionEnded();
    }

    /**
     * @dev Vote for a candidate (must be registered, not voted yet, and election active).
     */
    function vote(uint256 _candidateId) external onlyWhenActive {
        require(registeredVoters[msg.sender], "Not registered");
        require(!hasVoted[msg.sender], "Already voted");

        uint256 idx = candidateIndex[_candidateId];
        require(
            bytes(candidates[idx].name).length != 0,
            "Candidate doesn't exist"
        );

        candidates[idx].voteCount++;
        hasVoted[msg.sender] = true;

        emit VoteCasted(msg.sender, _candidateId);
    }

    /**
     * @dev Returns how many candidates currently exist.
     */
    function getCandidatesCount() external view returns (uint256) {
        return candidates.length;
    }

    /**
     * @dev Get candidate info by ID (returns name and voteCount).
     */
    function getCandidate(
        uint256 _candidateId
    ) external view returns (string memory, uint256) {
        uint256 idx = candidateIndex[_candidateId];
        Candidate memory c = candidates[idx];
        return (c.name, c.voteCount);
    }

    /**
     * @dev Return the entire list of candidates and their vote counts.
     */
    function getAllCandidates() external view returns (Candidate[] memory) {
        return candidates;
    }

    /**
     * @dev Gets the current leading candidate (winner).
     */
    function getCurrentLeader()
        external
        view
        returns (
            uint256 leaderId,
            string memory leaderName,
            uint256 leaderVotes
        )
    {
        require(candidates.length > 0, "No candidates available");

        uint256 highestVotes = 0;
        uint256 leaderIdx = 0;

        for (uint256 i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount > highestVotes) {
                highestVotes = candidates[i].voteCount;
                leaderIdx = i;
            }
        }

        leaderId = candidates[leaderIdx].id;
        leaderName = candidates[leaderIdx].name;
        leaderVotes = candidates[leaderIdx].voteCount;
    }
}
