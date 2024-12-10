// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract BlockBallotWithSBT is ERC721Enumerable {
    uint256 private tokenIdCounter;
    uint256 private useless;

    constructor() ERC721("ElectionSoulboundToken", "ESBT") {
        tokenIdCounter = 1; // Start token IDs at 1
        useless = 326723; 
        electionCount = 0;
    }

    // Data Structures

    struct Candidate {
        uint256 id; 
        string name;
        string politicalParty;
        uint256 addedTime;
        uint256 voteCount;
        string candidatePhoto;
    }

    struct Voter {
        address voterAddress;
        bool isRegistered;
        bool hasVoted;
        uint256 votedCandidateId;
        uint64 OTP;           
        uint256 phoneNumber;  
        uint256 timeRegister;  
    }

    struct Election {
        ElectionDetails details;
        Candidate[] candidates;
        mapping(address => Voter) voters;
        address[] voterList;
        address[] votersWhoHaveVoted; 
        uint256 winnerId; 
    }

    struct ElectionDetails {
        uint256 electionID;
        address admin;
        string adminName;
        string electionTitle; 
        string electionDescription;
        string electionCoverPhoto;
        uint256 electionStartTime;
        uint256 electionEndTime;
        bool hasStarted;
        bool hasEnded;
        uint256 electionTimeCreated;
        uint256 electionRegistrationStartTime;
        uint256 electionRegistrationEndTime;
        string electionCountry;
        bool electionAvailability; 
        string governingBody;
        string governingBodyCover;
    }

    struct ElectionData {
        ElectionDetails details;
        Candidate[] candidates;
    }

    struct SoulboundToken {
        uint256 tokenId;
        uint256 electionId;
        address owner;
        bool isUsed; // Marks if the token has been used for voting
    }

    mapping(uint256 => Election) public elections;
    mapping(uint256 => uint256) private nextCandidateId;
    mapping(address => uint256[]) private electionsByAdmin;
    mapping(address => SoulboundToken[]) public soulboundTokensByOwner; // Owner's tokens
    mapping(uint256 => mapping(address => uint256)) public electionToToken; // Maps electionId and wallet to tokenId
    mapping(uint256 => SoulboundToken) public soulboundTokens; // Maps tokenId to details

    uint256 public electionCount;

    // Events
    event ElectionCreated(
        uint256 indexed electionId,
        address indexed admin,
        string adminName,
        string title,
        string description,
        string coverPhoto
    );

    event ElectionUpdated(
        uint256 indexed electionId,
        string adminName,
        string title,
        string description,
        string coverPhoto
    );

    event CandidateAdded(
        uint256 indexed electionId,
        uint256 candidateId,
        string name,
        string politicalParty,
        uint256 addedTime
    );

    event CandidateRemoved(uint256 indexed electionId, uint256 candidateId);

    event ElectionStarted(uint256 indexed electionId, uint256 startTime);

    event ElectionEnded(uint256 indexed electionId, uint256 endTime);

    event VoterRegistered(uint256 indexed electionId, address indexed voterAddress);

    event Voted(uint256 indexed electionId, address indexed voterAddress, uint256 candidateId);

    event WinnerAnnounced(uint256 indexed electionId, uint256 indexed winnerId, string winnerName, uint256 voteCount);

    event ElectionClosed(uint256 indexed electionId, uint256 closedTime);

    // Modifiers
    modifier onlyAdmin(uint256 electionId) {
        require(elections[electionId].details.admin == msg.sender, "Only the admin can perform this action.");
        _;
    }
    
    modifier electionExists(uint256 electionId) {
        require(electionId > 0 && electionId <= electionCount, "Election does not exist.");
        _;
    }

    modifier electionAvailable(uint256 electionId) {
        require(elections[electionId].details.electionAvailability, "Election is not available.");
        _;
    }

    // Core Election Functions
    function createElection(
        string memory adminName,
        string memory title,
        string memory description,
        string memory coverPhoto,
        string memory governingBody,
        string memory country, 
        string memory photo, 
        uint256 registrationStart,
        uint256 registrationStop,
        uint256 electionStart,
        uint256 electionEnd
    ) public {
        electionCount++;

        Election storage newElection = elections[electionCount];
        newElection.details = ElectionDetails({
            electionID: electionCount,
            admin: msg.sender,
            adminName: adminName,
            electionTitle: title,
            electionDescription: description,
            electionCoverPhoto: coverPhoto,
            electionStartTime: electionStart,
            electionEndTime: electionEnd,
            hasStarted: false,
            hasEnded: false,
            electionTimeCreated: block.timestamp,
            electionRegistrationStartTime: registrationStart,
            electionRegistrationEndTime: registrationStop,
            electionCountry: country,
            electionAvailability: true,
            governingBody: governingBody,
            governingBodyCover: photo
        });

        nextCandidateId[electionCount] = 1;
        electionsByAdmin[msg.sender].push(electionCount);

        emit ElectionCreated(electionCount, msg.sender, adminName, title, description, coverPhoto);
    }

    // Add Candidate
    function addCandidate(
        uint256 electionId,
        string memory candidateName,
        string memory candidatePoliticalParty,
        string memory candidatePortrait
    ) public electionExists(electionId) onlyAdmin(electionId) {
        require(electionToToken[electionId][msg.sender] == 0, "Registered voter cannot be a candidate.");

        uint256 candidateId = nextCandidateId[electionId];

        elections[electionId].candidates.push(Candidate({
            id: candidateId,
            name: candidateName,
            politicalParty: candidatePoliticalParty,
            addedTime: block.timestamp,
            candidatePhoto: candidatePortrait,
            voteCount: 0
        }));

        nextCandidateId[electionId]++;

        emit CandidateAdded(electionId, candidateId, candidateName, candidatePoliticalParty, block.timestamp);
    }

  function registerVoter(
    uint256 electionId,
    address voterAddress,
    uint64 OTP,
    uint256 phoneNumber,
    uint256 timeRegister
) public electionExists(electionId) {
    require(msg.sender == voterAddress, "Cannot register for others.");
    require(electionToToken[electionId][voterAddress] == 0, "Voter already registered.");
    
    Election storage election = elections[electionId];
    require(!election.voters[voterAddress].isRegistered, "Voter is already registered.");

    // Mint the token directly here
    uint256 tokenId = tokenIdCounter++;
    _safeMint(voterAddress, tokenId);

    soulboundTokens[tokenId] = SoulboundToken({
        tokenId: tokenId,
        electionId: electionId,
        owner: voterAddress,
        isUsed: false
    });

    electionToToken[electionId][voterAddress] = tokenId;

    // Register the voter
    election.voters[voterAddress] = Voter({
        voterAddress: voterAddress,
        isRegistered: true,
        hasVoted: false,
        votedCandidateId: 0,
        OTP: OTP,
        phoneNumber: phoneNumber,
        timeRegister: timeRegister
    });

    election.voterList.push(voterAddress);

    emit VoterRegistered(electionId, voterAddress);
}


    // Voting Function
    function vote(uint256 electionId, uint256 candidateId) public electionExists(electionId) electionAvailable(electionId) {
        uint256 tokenId = electionToToken[electionId][msg.sender];
        require(tokenId > 0, "Voter does not have a token.");
        require(!soulboundTokens[tokenId].isUsed, "Token has already been used.");

        Election storage election = elections[electionId];
        require(!election.voters[msg.sender].hasVoted, "You have already voted.");
        require(block.timestamp >= election.details.electionStartTime, "Election has not started yet.");
        require(block.timestamp <= election.details.electionEndTime, "Election has already ended.");

        election.candidates[candidateId].voteCount++;
        election.voters[msg.sender].hasVoted = true;

        soulboundTokens[tokenId].isUsed = true;

        emit Voted(electionId, msg.sender, candidateId);
    }
    // Retrieve Election Details
    function getElectionDetails(uint256 electionId) 
        public 
        view 
        electionExists(electionId) 
        returns (ElectionData memory) 
    {
        Election storage election = elections[electionId];
        return ElectionData({details: election.details, candidates: election.candidates});
    }

    // Retrieve All Elections for an Admin
    function getElectionsByAdmin(address admin) public view returns (ElectionData[] memory) {
        uint256[] memory adminElectionIds = electionsByAdmin[admin];
        ElectionData[] memory result = new ElectionData[](adminElectionIds.length);

        for (uint256 i = 0; i < adminElectionIds.length; i++) {
            uint256 electionId = adminElectionIds[i];
            result[i] = getElectionDetails(electionId);
        }

        return result;
    }

    // Retrieve Voter Information
    function getVoterInfo(uint256 electionId, address voter) 
        public 
        view 
        electionExists(electionId) 
        returns (Voter memory) 
    {
        return elections[electionId].voters[voter];
    }

    // End Election
    function endElection(uint256 electionId) public electionExists(electionId) onlyAdmin(electionId) {
        Election storage election = elections[electionId];
        require(block.timestamp > election.details.electionEndTime, "Election is still ongoing.");
        require(!election.details.hasEnded, "Election has already ended.");

        election.details.hasEnded = true;

        // Determine winner
        uint256 maxVotes = 0;
        uint256 winnerId = 0;
        string memory winnerName = "";

        for (uint256 i = 0; i < election.candidates.length; i++) {
            if (election.candidates[i].voteCount > maxVotes) {
                maxVotes = election.candidates[i].voteCount;
                winnerId = election.candidates[i].id;
                winnerName = election.candidates[i].name;
            }
        }

        election.winnerId = winnerId;

        emit WinnerAnnounced(electionId, winnerId, winnerName, maxVotes);
        emit ElectionClosed(electionId, block.timestamp);
    }

    // Retrieve All Voters in an Election
    function getAllVoters(uint256 electionId) 
        public 
        view 
        electionExists(electionId) 
        returns (address[] memory) 
    {
        return elections[electionId].voterList;
    }

    // Retrieve All Candidates in an Election
    function getAllCandidates(uint256 electionId) 
        public 
        view 
        electionExists(electionId) 
        returns (Candidate[] memory) 
    {
        return elections[electionId].candidates;
    }

    // Retrieve Token Information
    function getTokenDetails(uint256 tokenId) public view returns (SoulboundToken memory) {
        return soulboundTokens[tokenId];
    }

    // Retrieve All Tokens Owned by a Wallet
    function getTokensByOwner(address owner) public view returns (SoulboundToken[] memory) {
        return soulboundTokensByOwner[owner];
    }

    // Check if a Voter Has Voted
    function hasVoterVoted(uint256 electionId, address voter) public view electionExists(electionId) returns (bool) {
        uint256 tokenId = electionToToken[electionId][voter];
        return soulboundTokens[tokenId].isUsed;
    }

    // Utility Functions
    function isTokenUsed(uint256 tokenId) public view returns (bool) {
        return soulboundTokens[tokenId].isUsed;
    }

    function _transfer(
    address from,
    address to,
    uint256 tokenId
) internal override view {
        require(from == msg.sender && ownerOf(tokenId)==msg.sender,"Only token owner can transfer tokens.");
}

 

    // Burn Tokens for Debugging (Optional)
    function burnToken(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "You can only burn your own tokens.");
        _burn(tokenId);
        delete soulboundTokens[tokenId];
    }
}
