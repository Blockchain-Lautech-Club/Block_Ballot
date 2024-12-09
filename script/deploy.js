const { ethers } = require("hardhat");

async function main() {
    console.log("Starting deployment...");
    const deployerAddr = "0xE122199bB9617d8B0e814aC903042990155015b4";
    const deployer = await ethers.getSigner(deployerAddr);
  
    console.log(`Deploying contracts with the account: ${deployer.address}`);
    // Compile the contract
    await hre.run("compile");

    // Deploy the contract using deployContract
    console.log("Deploying the contract...");
    const blockBallot = await hre.ethers.deployContract("BlockBallot");
    await blockBallot.waitForDeployment();

    // Log the deployed contract address
    console.log("Contract deployed to:", blockBallot.target);

    // Interact with the deployed contract
   
    // Step 1: Create an Election
    console.log("Creating an election...");
    const createElectionTx = await blockBallot.createElection(
        "Admin Name",                              // Admin name
        "Election Title",                          // Election title
        "Election Description",                    // Election description
        "https://example.com/election-cover.jpg",  // Election cover image
        "Governing Body",                          // Governing body
        "Country",                                 // Country
        "https://example.com/governing-body.jpg",  // Governing body photo
        Math.floor(Date.now() / 1000) + 3600,      // Registration start (1 hour from now)
        Math.floor(Date.now() / 1000) + 7200,      // Registration stop (2 hours from now)
        Math.floor(Date.now() / 1000) + 10800,     // Election start (3 hours from now)
        Math.floor(Date.now() / 1000) + 21600      // Election end (6 hours from now)
    );
    await createElectionTx.wait();
    console.log("Election created successfully!");

    // Step 2: Add Candidates
    console.log("Adding candidates...");
    const addCandidateTx1 = await blockBallot.addCandidate("Candidate 1", "https://example.com/candidate1.jpg");
    await addCandidateTx1.wait();
    console.log("Candidate 1 added successfully!");

    const addCandidateTx2 = await blockBallot.addCandidate("Candidate 2", "https://example.com/candidate2.jpg");
    await addCandidateTx2.wait();
    console.log("Candidate 2 added successfully!");

    // Step 3: Cast Votes
    console.log("Casting votes...");
    const voteTx1 = await blockBallot.vote(0); // Assuming candidate IDs are 0 and 1
    await voteTx1.wait();
    console.log("Vote cast successfully for Candidate 1!");

    const voteTx2 = await blockBallot.vote(1);
    await voteTx2.wait();
    console.log("Vote cast successfully for Candidate 2!");

    console.log("All steps completed successfully!");
}
// Handle errors and execute the script
main().catch((error) => {
    console.error("Error during deployment:", error);
    process.exitCode = 1;
});
