// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IUserVerification {
    function isUserVerified(address user) external view returns (bool);
}

contract Election {
    enum ElectionState {
        Preparing,
        Active,
        Ended
    }

    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
    }

    // Administrative variables
    address public immutable owner;
    ElectionState public electionState;
    IUserVerification public immutable userVerifier;
    uint256 public electionCount;

    // Candidate management
    Candidate[] public candidates;
    mapping(uint256 => uint256) private candidateIndex;
    mapping(uint256 => bool) private candidateExists;

    // Voter tracking
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // Historical election data
    mapping(uint256 => Candidate[]) public electionResults;

    // Events
    event CandidateAdded(uint256 indexed id, string name);
    event VoteCasted(address indexed voter, uint256 candidateId);
    event ElectionStarted(uint256 indexed electionId);
    event ElectionEnded(uint256 indexed electionId, uint256 totalVotes);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    modifier atState(ElectionState _state) {
        require(electionState == _state, "Invalid election state");
        _;
    }

    // Constructor
    constructor(address _verifierAddress) {
        require(_verifierAddress != address(0), "Invalid verifier address");
        owner = msg.sender;
        userVerifier = IUserVerification(_verifierAddress);
        electionState = ElectionState.Preparing;
    }

    // ============ Admin Functions ============

    function addCandidate(
        uint256 _id,
        string calldata _name
    ) external onlyOwner atState(ElectionState.Preparing) {
        _addCandidate(_id, _name);
    }

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

    function startElection()
        external
        onlyOwner
        atState(ElectionState.Preparing)
    {
        require(candidates.length > 0, "Cannot start with no candidates");

        electionState = ElectionState.Active;
        electionCount++;

        emit ElectionStarted(electionCount);
    }

    function endElection() external onlyOwner atState(ElectionState.Active) {
        electionState = ElectionState.Ended;

        // Store election results
        electionResults[electionCount] = candidates;

        // Calculate total votes for the event
        uint256 totalVotes = 0;
        for (uint i = 0; i < candidates.length; i++) {
            totalVotes += candidates[i].voteCount;
        }

        emit ElectionEnded(electionCount, totalVotes);
    }

    function createNewElection()
        external
        onlyOwner
        atState(ElectionState.Ended)
    {
        // Reset for a new election
        for (uint256 i = 0; i < candidates.length; i++) {
            candidateExists[candidates[i].id] = false;
        }

        delete candidates;
        electionState = ElectionState.Preparing;
    }

    // ============ Voter Functions ============

    function vote(uint256 _candidateId) external atState(ElectionState.Active) {
        require(userVerifier.isUserVerified(msg.sender), "User not verified");
        require(!hasVoted[electionCount][msg.sender], "Already voted");
        require(candidateExists[_candidateId], "Candidate doesn't exist");

        uint256 idx = candidateIndex[_candidateId];
        candidates[idx].voteCount++;
        hasVoted[electionCount][msg.sender] = true;

        emit VoteCasted(msg.sender, _candidateId);
    }

    // ============ View Functions ============

    function getCandidatesCount() external view returns (uint256) {
        return candidates.length;
    }

    function getCandidate(
        uint256 _candidateId
    ) external view returns (string memory, uint256) {
        require(candidateExists[_candidateId], "Candidate doesn't exist");

        uint256 idx = candidateIndex[_candidateId];
        Candidate memory c = candidates[idx];
        return (c.name, c.voteCount);
    }

    function getAllCandidates() external view returns (Candidate[] memory) {
        return candidates;
    }

    function getPastElectionResults(
        uint256 _electionId
    ) external view returns (Candidate[] memory) {
        require(
            _electionId > 0 && _electionId <= electionCount,
            "Invalid election ID"
        );
        return electionResults[_electionId];
    }

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

    function isVerifiedToVote(address _voter) external view returns (bool) {
        return userVerifier.isUserVerified(_voter);
    }

    function getElectionState() external view returns (ElectionState) {
        return electionState;
    }

    function hasUserVoted(address _user) external view returns (bool) {
        return hasVoted[electionCount][_user];
    }

    // ============ Internal Functions ============

    function _addCandidate(uint256 _id, string memory _name) internal {
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(!candidateExists[_id], "Candidate ID already exists");

        candidates.push(Candidate(_id, _name, 0));
        candidateIndex[_id] = candidates.length - 1;
        candidateExists[_id] = true;

        emit CandidateAdded(_id, _name);
    }
}
