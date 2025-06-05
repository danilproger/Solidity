import {expect} from "chai";
import {ethers} from "hardhat";
import {time} from "@nomicfoundation/hardhat-network-helpers";
import {PredictionMarket, PredictionMarketToken} from "../typechain-types";
import {HardhatEthersSigner} from "@nomicfoundation/hardhat-ethers/signers";
import {Signature} from "ethers";

describe("PredictionMarket full flow", function () {
    let market: PredictionMarket;
    let token: PredictionMarketToken;
    let owner: HardhatEthersSigner;
    let users: HardhatEthersSigner[];

    beforeEach(async () => {
        const [deployer, ...others] = await ethers.getSigners();
        owner = deployer;
        users = others.slice(0, 20); // 20 users

        // Deploy ERC20 Token
        token = await ethers.getContractFactory("PredictionMarketToken").then(t => t.deploy());
        await token.waitForDeployment();

        // Mint
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

    it("should run full prediction flow with permit", async function () {
        const now = await time.latest();
        const deadline1 = now + 3 * 24 * 60 * 60;
        const deadline2 = now + 4 * 24 * 60 * 60;

        await market.createEvent("Match 1: Who wins?", ["Team A", "Team B", "Draw"], deadline1);
        await market.createEvent("Match 2: Goals?", ["<2", "2-3", "4+"], deadline2);

        const marketAddress = await market.getAddress();
        const tokenAddress = await token.getAddress();
        const chainId = (await ethers.provider.getNetwork()).chainId;

        for (let i = 0; i < users.length; i++) {
            const user = users[i];
            const betAmount = ethers.parseEther("10");
            const eventId = i < 10 ? 1 : 2;
            const option = i % 3;
            const permitDeadline = (await time.latest()) + 3600;

            const nonce = await token.nonces(user.address);

            const domain = {
                name: "PredictionMarketToken",
                version: "1",
                chainId,
                verifyingContract: tokenAddress,
            };

            const types = {
                Permit: [
                    {name: "owner", type: "address"},
                    {name: "spender", type: "address"},
                    {name: "value", type: "uint256"},
                    {name: "nonce", type: "uint256"},
                    {name: "deadline", type: "uint256"},
                ],
            };

            const values = {
                owner: user.address,
                spender: marketAddress,
                value: betAmount,
                nonce,
                deadline: permitDeadline,
            };

            const signature = await user.signTypedData(domain, types, values);
            const {v, r, s} = Signature.from(signature);

            await market.connect(user).placeBetWithPermit(eventId, option, betAmount, permitDeadline, v, r, s);
        }

        await time.increaseTo(deadline2 + 10);

        await market.resolveEvent(1, 1);
        await market.resolveEvent(2, 2);

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
                await expect(market.connect(user).claimReward(eventId)).to.be.revertedWith("Not winner");
            }
        }
    });

    it("should expose event data via view functions", async function () {
        const now = await time.latest();
        const deadline = now + 3 * 24 * 60 * 60; // +3 days

        // Create one event
        await market.createEvent("Match: A vs B", ["A", "B", "Draw"], deadline);

        expect(await market.getEventCount()).to.equal(2n);

        const eventId = 1n;

        // Users approve and place bets
        for (let i = 0; i < users.length; i++) {
            const user = users[i];
            const betAmount = ethers.parseEther("10");
            const option = i % 3;

            await token.connect(user).approve(await market.getAddress(), betAmount).then(tx => tx.wait());
            await market.connect(user).placeBet(eventId, option, betAmount).then(tx => tx.wait());

            const userBet = await market.getUserBet(eventId, user.address);
            expect(userBet.amount).to.equal(betAmount);
            expect(userBet.option).to.equal(option);
            expect(userBet.claimed).to.equal(false);
        }

        // Check event options
        const options = await market.getEventOptions(eventId);
        expect(options).to.deep.equal(["A", "B", "Draw"]);

        // Check option bets totals
        const optionTotals = await market.getOptionBets(eventId);
        const sum = optionTotals.reduce((acc, x) => acc + x, 0n);
        expect(sum).to.equal(ethers.parseEther((10 * users.length).toString())); // 20 users * 10 PMT

        // Check individual option amounts
        const expectedCounts = [0n, 0n, 0n];
        for (let i = 0; i < users.length; i++) {
            expectedCounts[i % 3] += ethers.parseEther("10");
        }
        expect(optionTotals).to.deep.equal(expectedCounts);

        // Check event data
        const ev = await market.getMarketEvent(eventId);
        expect(ev.description).to.equal("Match: A vs B");
        expect(ev.totalBets).to.equal(ethers.parseEther((10 * users.length).toString()));
        expect(ev.resolved).to.be.false;
        expect(ev.deadline).to.equal(BigInt(deadline));
    });

});
