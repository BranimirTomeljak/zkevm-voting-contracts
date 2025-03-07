// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IMockUserVerification {
    function isUserVerified(address user) external view returns (bool);
}

/**
 * @title Election
 * @dev A simple voting contract referencing a mock user verification contract.
 */
contract Election {
    address public owner;

    enum ElectionState {
        Preparing,
        Active,
        Ended,
        Reset
    }
    ElectionState public electionState;

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

    // Track if ID exists to prevent duplicate candidates
    mapping(uint256 => bool) private candidateExists;

    // Track who's registered and who has voted
    mapping(address => bool) public registeredVoters;
    mapping(address => bool) public hasVoted;

    // Track historical elections
    uint256 public electionCount;
    // Modified: store candidates individually for each election
    mapping(uint256 => mapping(uint256 => Candidate))
        public electionResultCandidates;
    mapping(uint256 => uint256) public electionResultCandidateCount;

    event CandidateAdded(uint256 indexed id, string name);
    event VoterRegistered(address indexed voter);
    event VoteCasted(address indexed voter, uint256 candidateId);
    event ElectionStarted(uint256 indexed electionId);
    event ElectionEnded(uint256 indexed electionId);
    event ElectionReset();

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    modifier atState(ElectionState _state) {
        require(
            electionState == _state,
            "Invalid election state for this operation"
        );
        _;
    }

    constructor(address _verifierAddress) {
        require(_verifierAddress != address(0), "Invalid verifier address");
        owner = msg.sender;
        userVerifier = IMockUserVerification(_verifierAddress);
        electionState = ElectionState.Preparing;
    }

    /**
     * @dev Add a single candidate (owner only), but only when preparing the election.
     */
    function addCandidate(
        uint256 _id,
        string memory _name
    ) external onlyOwner atState(ElectionState.Preparing) {
        _addCandidate(_id, _name);
    }

    /**
     * @dev Add multiple candidates in one transaction (owner only).
     * @param _ids Array of candidate IDs
     * @param _names Array of candidate names
     */
    function addCandidatesBatch(
        uint256[] calldata _ids,
        string[] calldata _names
    ) external onlyOwner atState(ElectionState.Preparing) {
        require(_ids.length == _names.length, "Arrays must be the same length");
        require(_ids.length > 0, "Cannot add empty batch");

        for (uint256 i = 0; i < _ids.length; i++) {
            _addCandidate(_ids[i], _names[i]);
        }
    }

    /**
     * @dev Internal function to add a candidate, used by both addCandidate and addCandidatesBatch.
     */
    function _addCandidate(uint256 _id, string memory _name) internal {
        require(bytes(_name).length > 0, "Candidate name cannot be empty");
        require(!candidateExists[_id], "Candidate ID already exists");

        candidates.push(Candidate(_id, _name, 0));
        candidateIndex[_id] = candidates.length - 1;
        candidateExists[_id] = true;

        emit CandidateAdded(_id, _name);
    }

    /**
     * @dev Register to vote, requiring user is "verified" (mock verification).
     */
    function registerToVote() external {
        require(
            electionState == ElectionState.Preparing ||
                electionState == ElectionState.Active,
            "Election is not in a state that allows registration"
        );
        require(!registeredVoters[msg.sender], "Already registered");
        require(userVerifier.isUserVerified(msg.sender), "User not verified");

        registeredVoters[msg.sender] = true;
        emit VoterRegistered(msg.sender);
    }

    /**
     * @dev Start the election (owner only).
     */
    function startElection()
        external
        onlyOwner
        atState(ElectionState.Preparing)
    {
        require(
            candidates.length > 0,
            "Cannot start an election with no candidates"
        );

        electionState = ElectionState.Active;
        electionCount++;

        emit ElectionStarted(electionCount);
    }

    /**
     * @dev End the election (owner only).
     */
    function endElection() external onlyOwner atState(ElectionState.Active) {
        electionState = ElectionState.Ended;

        // Store the results of this election - modified to avoid memory to storage copy
        electionResultCandidateCount[electionCount] = candidates.length;
        for (uint i = 0; i < candidates.length; i++) {
            electionResultCandidates[electionCount][i] = candidates[i];
        }

        emit ElectionEnded(electionCount);
    }

    /**
     * @dev Reset the election to prepare for a new one (owner only).
     */
    function resetElection() external onlyOwner atState(ElectionState.Ended) {
        // Clear candidates
        for (uint256 i = 0; i < candidates.length; i++) {
            candidateExists[candidates[i].id] = false;
        }

        delete candidates;

        electionState = ElectionState.Preparing;

        emit ElectionReset();
    }

    /**
     * @dev Vote for a candidate (must be registered, not voted yet, and election active).
     */
    function vote(uint256 _candidateId) external atState(ElectionState.Active) {
        require(registeredVoters[msg.sender], "Not registered");
        require(!hasVoted[msg.sender], "Already voted");
        require(candidateExists[_candidateId], "Candidate doesn't exist");

        uint256 idx = candidateIndex[_candidateId];
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
        require(candidateExists[_candidateId], "Candidate doesn't exist");

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
     * @dev Get results from a previous election.
     */
    function getPastElectionResults(
        uint256 _electionId
    ) external view returns (Candidate[] memory) {
        require(
            _electionId > 0 && _electionId <= electionCount,
            "Invalid election ID"
        );

        uint256 count = electionResultCandidateCount[_electionId];
        Candidate[] memory results = new Candidate[](count);

        for (uint256 i = 0; i < count; i++) {
            results[i] = electionResultCandidates[_electionId][i];
        }

        return results;
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

    /**
     * @dev Gets the current state of the election.
     */
    function getElectionState() external view returns (ElectionState) {
        return electionState;
    }
}
