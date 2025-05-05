const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ScamToken AccessControl, MetaTx, Permit", function () {
    let token, forwarder;
    let owner, user1, user2;

    beforeEach(async () => {
        [owner, user1, user2] = await ethers.getSigners();

        forwarder = await ethers.getContractFactory("MetaTxForwarder").then((factory => factory.deploy("MetaTxForwarder", "0.0.1")));
        await forwarder.waitForDeployment();
        const forwarderAddress = await forwarder.getAddress();

        token = await ethers.getContractFactory("ScamToken").then((factory) => factory.deploy(forwarderAddress));
        await token.waitForDeployment();
    });

    it("mints tokens with access control (success)", async () => {
        await token.grantRole(await token.MINTER_ROLE(), user1.address);
        await token.connect(user1).mint(user2.address, ethers.parseUnits("100", 18));

        expect(await token.balanceOf(user2.address)).to.equal(ethers.parseUnits("100", 18));
    });

    it("mints tokens with access control (failure, no access)", async () => {
        await expect(token.connect(user2).mint(user2.address, ethers.parseUnits("100", 18)))
            .to.be.revertedWithCustomError(token, "AccessControlUnauthorizedAccount")
            .withArgs(user2.address, await token.MINTER_ROLE());
    });

    it("allows permit approvals", async () => {
        const nonce = await token.nonces(user1.address);
        const deadline = Math.floor(Date.now() / 1000) + 3600;

        const domain = {
            name: "ScamToken",
            version: "0.0.1",
            chainId: (await ethers.provider.getNetwork()).chainId,
            verifyingContract: await token.getAddress(),
        };

        const types = {
            Permit: [
                { name: "owner", type: "address" },
                { name: "spender", type: "address" },
                { name: "value", type: "uint256" },
                { name: "nonce", type: "uint256" },
                { name: "deadline", type: "uint256" },
            ],
        };

        const value = {
            owner: user1.address,
            spender: user2.address,
            value: ethers.parseUnits("50", 18),
            nonce,
            deadline,
        };

        const signature = await user1.signTypedData(domain, types, value);
        const { v, r, s } = ethers.Signature.from(signature);

        await token.permit(user1.address, user2.address, value.value, deadline, v, r, s);

        expect(await token.allowance(user1.address, user2.address)).to.equal(value.value);
    });

    it("executes meta-transaction via forwarder", async () => {
        const nonce = await forwarder.nonces(owner.address);
        const gas = 1_000_000;
        const data = token.interface.encodeFunctionData("transfer", [user1.address, ethers.parseUnits("10", 18)]);

        const deadline = Math.floor(Date.now() / 1000) + 60;
        const request = {
            from: owner.address,
            to: await token.getAddress(),
            value: 0,
            gas,
            nonce,
            deadline,
            data,
        };

        const domain = {
            name: "MetaTxForwarder",
            version: "0.0.1",
            chainId: (await ethers.provider.getNetwork()).chainId,
            verifyingContract: await forwarder.getAddress(),
        };

        const types = {
            ForwardRequest: [
                { name: "from", type: "address" },
                { name: "to", type: "address" },
                { name: "value", type: "uint256" },
                { name: "gas", type: "uint256" },
                { name: "nonce", type: "uint256" },
                { name: "deadline", type: "uint256" },
                { name: "data", type: "bytes" },
            ],
        };

        const signature = await owner.signTypedData(domain, types, request);

        await forwarder.execute(request, signature);
        expect(await token.balanceOf(user1.address)).to.equal(ethers.parseUnits("10", 18));
    });
});
