import {expect} from "chai";
import {ethers} from "hardhat";
import {PredictionMarketToken} from "../typechain-types";

describe("PredictionMarketToken", function () {
    let token: PredictionMarketToken;
    let deployer: any;
    let user1: any;
    let user2: any;

    const MINTER_ROLE = ethers.id("MINTER_ROLE");
    const BURNER_ROLE = ethers.id("BURNER_ROLE");

    beforeEach(async function () {
        [deployer, user1, user2] = await ethers.getSigners();

        const Token = await ethers.getContractFactory("PredictionMarketToken");
        token = await Token.deploy();
        await token.waitForDeployment();
    });

    it("should have correct name and symbol", async function () {
        expect(await token.name()).to.equal("PredictionMarketToken");
        expect(await token.symbol()).to.equal("PMT");
    });

    it("deployer should have default admin, minter, and burner roles", async function () {
        expect(await token.hasRole(MINTER_ROLE, deployer.address)).to.be.true;
        expect(await token.hasRole(BURNER_ROLE, deployer.address)).to.be.true;
        expect(await token.hasRole(await token.DEFAULT_ADMIN_ROLE(), deployer.address)).to.be.true;
    });

    it("should allow minter to mint tokens", async function () {
        await expect(token.connect(deployer).mint(user1.address, 1000))
            .to.emit(token, "Transfer")
            .withArgs(ethers.ZeroAddress, user1.address, 1000);

        expect(await token.balanceOf(user1.address)).to.equal(1000);
    });

    it("should not allow non-minter to mint", async function () {
        await expect(token.connect(user1).mint(user1.address, 1000)).to.be.revertedWithCustomError(
            token, "AccessControlUnauthorizedAccount"
        );
    });

    it("should allow burner to burn tokens", async function () {
        await token.connect(deployer).mint(user1.address, 1000);
        expect(await token.balanceOf(user1.address)).to.equal(1000);

        await token.connect(deployer).burn(user1.address, 500);
        expect(await token.balanceOf(user1.address)).to.equal(500);
    });

    it("should not allow non-burner to burn", async function () {
        await token.connect(deployer).mint(user1.address, 1000);

        await expect(token.connect(user1).burn(user1.address, 500)).to.be.revertedWithCustomError(
            token, "AccessControlUnauthorizedAccount"
        );
    });

    it("should allow transfer between accounts", async function () {
        await token.connect(deployer).mint(user1.address, 1000);

        await token.connect(user1).transfer(user2.address, 400);
        expect(await token.balanceOf(user2.address)).to.equal(400);
        expect(await token.balanceOf(user1.address)).to.equal(600);
    });

    it("should allow approve and transferFrom", async function () {
        await token.connect(deployer).mint(user1.address, 1000);
        await token.connect(user1).approve(user2.address, 500);

        await token.connect(user2).transferFrom(user1.address, user2.address, 300);
        expect(await token.balanceOf(user2.address)).to.equal(300);
        expect(await token.balanceOf(user1.address)).to.equal(700);
    });

    it("should not allow transferFrom more than approved", async function () {
        await token.connect(deployer).mint(user1.address, 1000);
        await token.connect(user1).approve(user2.address, 200);

        await expect(
            token.connect(user2).transferFrom(user1.address, user2.address, 300)
        ).to.be.revertedWithCustomError(token, "ERC20InsufficientAllowance");
    });

    it("should emit Transfer event on mint and burn", async function () {
        await expect(token.connect(deployer).mint(user1.address, 1234))
            .to.emit(token, "Transfer")
            .withArgs(ethers.ZeroAddress, user1.address, 1234);

        await expect(token.connect(deployer).burn(user1.address, 234))
            .to.emit(token, "Transfer")
            .withArgs(user1.address, ethers.ZeroAddress, 234);
    });
});
