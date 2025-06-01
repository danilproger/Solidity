import {expect} from "chai";
import {ethers} from "hardhat";
import {time} from "@nomicfoundation/hardhat-network-helpers";
import {PredictionMarket, PredictionMarketToken} from "../typechain-types";
import {HardhatEthersSigner} from "@nomicfoundation/hardhat-ethers/signers";

describe("PredictionMarket full flow", function () {
    let market: PredictionMarket;
    let token: PredictionMarketToken;
    let owner: HardhatEthersSigner;
    let users: HardhatEthersSigner[];

    beforeEach(async () => {
        const [deployer, ...others] = await ethers.getSigners();
        owner = deployer;
        users = others.slice(0, 20); // 20 юзеров

        // Deploy ERC20Permit Token
        token = await ethers.getContractFactory("PredictionMarketToken").then(t => t.deploy());
        await token.waitForDeployment();

        // Mint токены всем
        for (const user of users) {
            await token.connect(owner).mint(user.address, ethers.parseEther("1000"));
        }

        // Deploy PredictionMarket
        const tokenAddress = await token.getAddress();
        market = await ethers.getContractFactory("PredictionMarket").then(m => m.deploy(
            tokenAddress,
            deployer.address,
            500 // 5% fee
        ));
        await market.waitForDeployment();

        // Grant roles
        const CREATOR = await market.EVENT_CREATOR();
        const RESOLVER = await market.EVENT_RESOLVER();
        await market.grantRole(CREATOR, deployer.address);
        await market.grantRole(RESOLVER, deployer.address);
    });

    it("should run full prediction flow", async function () {
        const now = await time.latest();
        const deadline1 = now + 3 * 24 * 60 * 60; // +3 дня
        const deadline2 = now + 4 * 24 * 60 * 60; // +4 дня

        // Create 2 events
        await market.createEvent("Match 1: Who wins?", ["Team A", "Team B", "Draw"], deadline1);
        await market.createEvent("Match 2: Goals?", ["<2", "2-3", "4+"], deadline2);

        // Users approve and place bets
        for (let i = 0; i < users.length; i++) {
            const user = users[i];
            const betAmount = ethers.parseEther("10");

            await token.connect(user).approve(await market.getAddress(), betAmount);

            const eventId = i < 10 ? 1 : 2;
            const option = i % 3;

            await market.connect(user).placeBet(eventId, option, betAmount);
        }

        // Fast forward to after both deadlines
        await time.increaseTo(deadline2 + 10);

        // Resolve events
        await market.resolveEvent(1, 1); // Team B wins
        await market.resolveEvent(2, 2); // "4+" goals wins

        // Users claim rewards (those who chose correct option)
        for (let i = 0; i < users.length; i++) {
            const user = users[i];
            const eventId = i < 10 ? 1 : 2;
            const chosenOption = i % 3;
            const winningOption = eventId === 1 ? 1 : 2;

            if (chosenOption === winningOption) {
                const before = await token.balanceOf(user.address);
                await market.connect(user).claimReward(eventId);
                const after = await token.balanceOf(user.address);

                expect(after).to.be.gt(before);
            } else {
                await expect(market.connect(user).claimReward(eventId)).to.be.revertedWith(
                    "Not winner"
                );
            }
        }
    });
});
