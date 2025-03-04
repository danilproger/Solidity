const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");

const initialSupply = BigNumber.from("1000000000000000000000000");
const decimals = BigNumber.from("18");

describe("ScamToken", function () {
    let token, owner, addr1, addr2;

    beforeEach(async function () {
        [owner, addr1, addr2] = await ethers.getSigners();
        const scamToken = await ethers.getContractFactory("ScamToken");
        token = await scamToken.connect(owner).deploy();
    });

    it("Should set name and symbol", async function () {
        expect(await token.name()).to.equal("ScamToken1337");
        expect(await token.symbol()).to.equal("SCM");
    });

    it("Should set totalSupply and decimals", async function () {
        expect(await token.totalSupply()).to.equal(initialSupply);
        expect(await token.balanceOf(owner.address)).to.equal(initialSupply);
        expect(await token.decimals()).to.equal(decimals);
    });

    it("Should correct transfer", async function () {
        const amount = BigNumber.from("100000");
        await token.transfer(addr1.address, amount);
        expect(await token.balanceOf(addr1.address)).to.equal(amount);
        expect(await token.balanceOf(owner.address)).to.equal(initialSupply.sub(amount));
    });

    it("Should not transfer if amount less", async function () {
        const largeAmount = initialSupply.add(BigNumber.from("1"));
        await expect(token.connect(addr1).transfer(owner.address, largeAmount))
            .to.be.revertedWith("Balance decrease zero isn't allowed");
    });

    it("Should approve and transferFrom", async function () {
        const amount = BigNumber.from("100000");
        await token.approve(addr1.address, amount);
        await token.connect(addr1).transferFrom(owner.address, addr2.address, amount);

        expect(await token.balanceOf(addr2.address)).to.equal(amount);
        expect(await token.balanceOf(owner.address)).to.equal(initialSupply.sub(amount));
    });

    it("Should not transferFrom without approve", async function () {
        const amount = BigNumber.from("100000");
        await expect(token.connect(addr1).transferFrom(owner.address, addr2.address, amount))
            .to.be.revertedWith("Allowance decrease zero isn't allowed");
    });

    it("Should not transferFrom if amount larger", async function () {
        const amount = BigNumber.from("100000");
        await token.approve(addr1.address, amount.sub(BigNumber.from("1")));

        await expect(token.connect(addr1).transferFrom(owner.address, addr2.address, amount))
            .to.be.revertedWith("Allowance decrease zero isn't allowed");
    });
});