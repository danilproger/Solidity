import {task} from "hardhat/config";
import {HardhatRuntimeEnvironment} from "hardhat/types";

task("deploy", "Deploys a contract")
    .addParam("contract", "The contract name")
    .addOptionalParam("args", "Constructor arguments (JSON array)", "[]")
    .addFlag("verify", "Need to verify after deploy")
    .setAction(async (taskArgs: {
        contract: string;
        args: string;
        verify?: boolean
    }, hre: HardhatRuntimeEnvironment) => {
        const contractName: string = taskArgs.contract;
        const constructorArgs: any[] = JSON.parse(taskArgs.args);

        console.log("🧹 Cleaning old build artifacts...");
        await hre.run("clean");

        console.log("🔨 Compiling contracts...");
        await hre.run("compile");

        const [deployer] = await hre.ethers.getSigners();
        console.log(`🚀 Deploying contract: ${contractName} with the account: ${deployer.address}`);
        console.log(`🔧 Constructor arguments:`, constructorArgs);

        const contract = await hre.ethers.getContractFactory(contractName);
        const contractDeploy = await contract.deploy(...constructorArgs);

        await contractDeploy.waitForDeployment();
        const address: string = await contractDeploy.getAddress();
        console.log(`✅ Contract deployed at: ${address}`);

        if (taskArgs.verify) {
            console.log("⌛ Waiting for Etherscan to register the contract...");
            await new Promise(resolve => setTimeout(resolve, 60000));

            console.log("🔍 Verifying contract on Etherscan...");
            try {
                await hre.run("verify:verify", {
                    address: address,
                    constructorArguments: constructorArgs,
                });
                console.log("✅ Contract verified!");
            } catch (error) {
                console.error("❌ Verification failed:", error);
            }
        }
    });

export {};