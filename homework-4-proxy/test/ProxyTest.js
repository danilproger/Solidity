const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("BeaconProxy Upgrade flow, Factory create", function () {

    it("Deploying V1 and upgrade to V2", async function () {
        // Deploy V1
        const implV1 = await ethers.getContractFactory("ImplV1").then((factory) => factory.deploy());
        await implV1.waitForDeployment();
        const implV1Address = await implV1.getAddress();

        // Deploy Beacon with beacon-V1 address
        const beacon = await ethers.getContractFactory("Beacon").then((factory) => factory.deploy(implV1Address));
        await beacon.waitForDeployment();
        const beaconAddress = await beacon.getAddress();

        // Deploy Factory with beacon address
        const factory = await ethers.getContractFactory("Factory").then((factory) => factory.deploy(beaconAddress));
        await factory.waitForDeployment();

        // Create proxy via factory
        const tx = await factory.create();
        const receipt = await tx.wait();
        const proxyAddress = receipt.logs[0].args.proxy;
        const proxyAsV1 = await ethers.getContractAt("ImplV1", proxyAddress);

        // Use V1 logic
        await proxyAsV1.increment();
        expect(await proxyAsV1.value()).to.equal(1);

        // Deploy V2 and upgrade Beacon
        const implV2 = await ethers.getContractFactory("ImplV2").then((factory) => factory.deploy());
        await beacon.upgradeTo(await implV2.getAddress());

        // Now Proxy uses V2
        const proxyAsV2 = await ethers.getContractAt("ImplV2", proxyAddress);
        await proxyAsV2.increment();
        expect(await proxyAsV2.value()).to.equal(16);
    });
});
