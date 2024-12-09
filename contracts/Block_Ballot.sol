// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract BlockBallot {
    uint256 private useless;

    constructor() {
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

    struct GeneratedNumber {
        uint256 number;
        uint256 timestamp;
    }

    

    mapping(uint256 => Election) public elections;
    mapping(uint256 => uint256) private nextCandidateId;
    mapping(address => uint256[]) private electionsByAdmin;
    mapping(address => GeneratedNumber[]) private generatedNumbers;

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

    event CandidateRemoved(
        uint256 indexed electionId,
        uint256 candidateId
    );

    event ElectionStarted(
        uint256 indexed electionId,
        uint256 startTime
    );

    event ElectionEnded(
        uint256 indexed electionId,
        uint256 endTime
    );

    event VoterRegistered(
        uint256 indexed electionId,
        address indexed voterAddress
    );

    event Voted(
        uint256 indexed electionId,
        address indexed voterAddress,
        uint256 candidateId
    );

    event WinnerAnnounced(
        uint256 indexed electionId,
        uint256 indexed winnerId,
        string winnerName,
        uint256 voteCount
    );

    event ElectionClosed(
        uint256 indexed electionId,
        uint256 closedTime
    );

    // Modifiers

    modifier onlyAdmin(uint256 electionId) {
        require(elections[electionId].details.admin == msg.sender, "Only the admin can perform this action.");
        _;
    }
    
    modifier onlyOwner(address owner) {
        require(msg.sender == owner, "Invalid user");
        _;
    }

    modifier electionExists(uint256 electionId) {
        require(electionId > 0 && electionId <= electionCount, "Election does not exist.");
        _;
    }

    modifier electionEnded(uint256 electionId) {
        require(elections[electionId].details.hasEnded, "Election has not ended.");
        _;
    }

    modifier electionAvailable(uint256 electionId) {
        require(elections[electionId].details.electionAvailability, "Election is not available.");
        _;
    }

    // Functions

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

        emit ElectionCreated(
            electionCount,
            msg.sender,
            adminName,
            title,
            description,
            coverPhoto
        );
    }

    function updateElection(
        uint256 electionId,
        string memory adminName,
        string memory title,
        string memory description,
        string memory coverPhoto,
        string memory governingBody,
        string memory country, 
        string memory photo, 
        uint256 registrationStart,
        uint256 registrationStop
    ) public electionExists(electionId) onlyAdmin(electionId) {
        require(!elections[electionId].details.hasStarted, "Cannot update election after it has started.");

        ElectionDetails storage details = elections[electionId].details;
        details.adminName = adminName;
        details.electionTitle = title;
        details.electionDescription = description;
        details.electionCoverPhoto = coverPhoto;
        details.electionTimeCreated = block.timestamp;
        details.electionRegistrationStartTime = registrationStart;
        details.electionRegistrationEndTime = registrationStop;
        details.electionCountry = country;
        details.electionAvailability = true;
        details.governingBody = governingBody;
        details.governingBodyCover = photo;

        emit ElectionUpdated(
            electionId,
            adminName,
            title,
            description,
            coverPhoto
        );
    }

    function addCandidate(
        uint256 electionId,
        string memory candidateName,
        string memory candidatePoliticalParty,
        string memory candidatePortrait
    ) public electionExists(electionId) onlyAdmin(electionId) {
        require(!elections[electionId].details.hasStarted, "Cannot add candidates after the election has started.");

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

        emit CandidateAdded(
            electionId,
            candidateId,
            candidateName,
            candidatePoliticalParty,
            block.timestamp
        );
    }

    function removeCandidate(uint256 electionId, uint256 candidateId) public electionExists(electionId) onlyAdmin(electionId) {
        require(!elections[electionId].details.hasStarted, "Cannot remove candidates after the election has started.");

        int256 candidateIndex = -1;
        for (uint256 i = 0; i < elections[electionId].candidates.length; i++) {
            if (elections[electionId].candidates[i].id == candidateId) {
                candidateIndex = int256(i);
                break;
            }
        }

        require(candidateIndex >= 0, "Candidate does not exist.");

        uint256 index = uint256(candidateIndex);
        uint256 lastIndex = elections[electionId].candidates.length - 1;

        if (index != lastIndex) {
            elections[electionId].candidates[index] = elections[electionId].candidates[lastIndex];
        }

        elections[electionId].candidates.pop();

        emit CandidateRemoved(
            electionId,
            candidateId
        );
    }

    function changeElectionAdmin(uint256 electionId, address newAdmin) 
    public 
    electionExists(electionId) 
    onlyAdmin(electionId) 
{
    require(newAdmin != address(0), "New admin address cannot be zero.");
    elections[electionId].details.admin = newAdmin;
}

    function getElectionSummary(uint256 electionId) 
    public 
    view 
    electionExists(electionId) 
    returns (
        string memory title, 
        uint256 totalCandidates, 
        uint256 totalVoters, 
        uint256 votersWhoVoted
    ) 
{
    Election storage election = elections[electionId];
    return (
        election.details.electionTitle,
        election.candidates.length,
        election.voterList.length,
        election.votersWhoHaveVoted.length
    );
}


    function generateRandomNumber() public returns (uint256) {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 900000;
        generatedNumbers[msg.sender].push(GeneratedNumber({
            number: randomNumber,
            timestamp: block.timestamp
        }));
        return randomNumber;
    }

    function announceWinner(uint256 electionId) internal electionExists(electionId) electionEnded(electionId) {
        uint256 winningVoteCount = 0;
        uint256 winnerId = 0;

        for (uint256 i = 0; i < elections[electionId].candidates.length; i++) {
            if (elections[electionId].candidates[i].voteCount > winningVoteCount) {
                winningVoteCount = elections[electionId].candidates[i].voteCount;
                winnerId = elections[electionId].candidates[i].id;
            }
        }

        elections[electionId].winnerId = winnerId;

        emit WinnerAnnounced(
            electionId,
            winnerId,
            elections[electionId].candidates[winnerId].name,
            winningVoteCount
        );
    }

    function closeElection(uint256 electionId) public electionExists(electionId) onlyAdmin(electionId) {
        require(elections[electionId].details.electionAvailability == true, "Election is already closed.");
        elections[electionId].details.electionAvailability = false;
        emit ElectionClosed(
            electionId,
            block.timestamp
        );
    }

   function registerVoter(
    uint256 electionId, 
    address voterAddress, 
    uint64 OTP, 
    uint256 phoneNumber, 
    uint256 timeRegister
) 
    public 
    electionExists(electionId) 
{
    require(msg.sender == voterAddress, "you can't register for others");
    require(OTP == generatedNumbers[msg.sender][generatedNumbers[msg.sender].length - 1].number);
    require(block.timestamp >= elections[electionId].details.electionRegistrationStartTime, "Registration has not started.");
    require(block.timestamp <= elections[electionId].details.electionRegistrationEndTime, "Registration has ended.");
    require(!elections[electionId].details.hasStarted, "Cannot register voters after the election has started.");

    Election storage election = elections[electionId];
    require(!election.voters[voterAddress].isRegistered, "Voter is already registered.");

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

    emit VoterRegistered(
        electionId,
        voterAddress
    );
}


  function vote(uint256 electionId, uint256 candidateId) public electionExists(electionId) electionAvailable(electionId) {
    Election storage election = elections[electionId];
    Voter storage voter = election.voters[msg.sender];

    require(voter.isRegistered, "You are not registered to vote.");
    require(!voter.hasVoted, "You have already voted.");
    require(block.timestamp >= election.details.electionStartTime, "Election has not started yet.");
    require(block.timestamp <= election.details.electionEndTime, "Election has already ended.");

    bool candidateExists = false;
    for (uint256 i = 0; i < election.candidates.length; i++) {
        if (election.candidates[i].id == candidateId) {
            candidateExists = true;
            break;
        }
    }
    require(candidateExists, "Candidate does not exist.");

    election.candidates[candidateId].voteCount++;
    voter.hasVoted = true;
    voter.votedCandidateId = candidateId;

    election.votersWhoHaveVoted.push(msg.sender);

    emit Voted(
        electionId,
        msg.sender,
        candidateId
    );

    if (block.timestamp >= election.details.electionEndTime) {
        election.details.hasEnded = true;
        emit ElectionEnded(electionId, block.timestamp);
        announceWinner(electionId);
    }
}


    function getElectionDetails(uint256 electionId) 
    public 
    view 
    electionExists(electionId) 
    returns (ElectionDetails memory, Candidate[] memory) 
{
    ElectionDetails memory electionDetails = elections[electionId].details;
    Candidate[] memory electionCandidates = elections[electionId].candidates;
    return (electionDetails, electionCandidates);
}
function getCandidateInfo(uint256 electionId, uint256 candidateId) 
    public 
    view 
    electionExists(electionId) 
    returns (Candidate memory) 
{
    require(candidateId < elections[electionId].candidates.length, "Invalid candidate ID");
    return elections[electionId].candidates[candidateId];
}



    // Function to return all elections with details and candidate information
   function getAllElections() public view returns (ElectionData[] memory) {
    ElectionData[] memory allElections = new ElectionData[](electionCount);

    for (uint256 i = 1; i <= electionCount; i++) {
        allElections[i - 1] = ElectionData({
            details: elections[i].details,
            candidates: elections[i].candidates
        });
    }

    return allElections;
}


    // Function to return all elections a voter is registered for
    function getElectionsForVoter(address voter) public view returns (uint256[] memory) {
        uint256[] memory electionIds = electionsByAdmin[voter];
        return electionIds;
    }

    function getCandidates(uint256 electionId) public view electionExists(electionId) returns (Candidate[] memory) {
        return elections[electionId].candidates;
    }

    function getVoterInfo(uint256 electionId, address voterAddress) 
    public 
    view 
    electionExists(electionId) 
    returns (
        address _voterAddress,
        uint256 _phoneNumber,
        uint256 _timeRegister
    ) 
{
    Election storage election = elections[electionId];
    
    
    require(election.voters[voterAddress].isRegistered, "Voter is not registered.");

    Voter memory voter = election.voters[voterAddress];

    return (
        voter.voterAddress,
        voter.phoneNumber,
        voter.timeRegister
    );
}

function getVotersWhoHaveVoted(uint256 electionId) public view electionExists(electionId) returns (address[] memory) {
    return elections[electionId].votersWhoHaveVoted;
}

    function getVoterList(uint256 electionId) public view electionExists(electionId) returns (address[] memory) {
        return elections[electionId].voterList;
    }

    function getGeneratedNumbers() public view returns (GeneratedNumber[] memory) {
        return generatedNumbers[msg.sender];
    }
}
