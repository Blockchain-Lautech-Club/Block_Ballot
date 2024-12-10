// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Block_Ballot.sol";

contract ElectionFactory {
    // Array to store all deployed Election contracts
    BlockBallotWithSBT[] public elections;

    // Event emitted when a new election contract is deployed
    event ElectionCreated(address electionAddress);

    // Function to create a new Election contract
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
        // Deploy a new instance of BlockBallotWithSBT contract
        BlockBallotWithSBT newElection = new BlockBallotWithSBT();

        // Call the createElection function of the newly deployed contract
        newElection.createElection(
            adminName,
            title,
            description,
            coverPhoto,
            governingBody,
            country,
            photo,
            registrationStart,
            registrationStop,
            electionStart,
            electionEnd
        );

        // Add the new election contract to the elections array
        elections.push(newElection);

        // Emit the ElectionCreated event
        emit ElectionCreated(address(newElection));
    }

    // Retrieve all deployed elections
    function getAllElections() public view returns (BlockBallotWithSBT[] memory) {
        return elections;
    }

    // Retrieve the count of deployed elections
    function getElectionCount() public view returns (uint256) {
        return elections.length;
    }
}
