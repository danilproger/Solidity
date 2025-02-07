const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();

    console.log(`Deploying contracts with the account: ${deployer.address}`);
    const bankContract = await hre.ethers.getContractFactory("Bank");
    const bankContractDeploy = await bankContract.deploy();

    await bankContractDeploy.deployed();
    console.log(`✅ Contract deployed to: ${bankContractDeploy.address}`);

    console.log("⌛ Waiting for Etherscan to register the contract...");
    await new Promise(resolve => setTimeout(resolve, 60000));

    console.log("🔍 Verifying contract on Etherscan...");
    try {
        await hre.run("verify:verify", {
            address: bankContractDeploy.address,
            constructorArguments: [],
        });
        console.log("✅ Contract verified on Etherscan!");
    } catch (error) {
        console.error("❌ Verification failed:", error);
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });