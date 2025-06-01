import { expect } from "chai";
import { ethers } from "hardhat";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { PredictionMarket, PredictionMarketToken } from "../typechain-types";
import {HardhatEthersSigner} from "@nomicfoundation/hardhat-ethers/signers";

describe("PredictionMarket — massive event test", function () {
    let market: PredictionMarket;
    let token: PredictionMarketToken;
    let users: HardhatEthersSigner[];
    let feeRecipient: string;

    const FEE_PERCENT = 500; // 5%
    const EVENT_COUNT = 100;
    const OPTIONS = ["A", "B", "C"];

    beforeEach(async () => {
        const [deployer, ...others] = await ethers.getSigners();
        users = others.slice(0, 20);
        feeRecipient = deployer.address;

        token = await ethers.getContractFactory("PredictionMarketToken").then(t => t.deploy());
        await token.waitForDeployment();

        for (const user of users) {
            await token.connect(deployer).mint(user.address, ethers.parseEther("1000"));
        }
        const tokenAddress = await token.getAddress();
        market = await ethers.getContractFactory("PredictionMarket").then(m => m.deploy(
            tokenAddress,
            feeRecipient,
            FEE_PERCENT // 5% fee
        ));
        await market.waitForDeployment();

        await market.grantRole(await market.EVENT_CREATOR(), deployer.address);
        await market.grantRole(await market.EVENT_RESOLVER(), deployer.address);
    });

    it("should create 100 events, place bets, resolve, and claim with correct fees", async () => {
        const now = await time.latest();
        const deadline = now + 3 * 24 * 60 * 60;

        // 1. Create 100 events
        for (let i = 0; i < EVENT_COUNT; i++) {
            await market.createEvent(`Event ${i + 1}`, OPTIONS, deadline);
        }

        // 2. Users approve & bet randomly
        const bets: Record<number, { user: string; amount: bigint; option: number }[]> = {};
        const betAmount = ethers.parseEther("10");

        for (let eventId = 1; eventId <= EVENT_COUNT; eventId++) {
            bets[eventId] = [];

            for (const user of users) {
                const shouldBet = Math.random() < 0.7; // 70% chance user participates
                if (!shouldBet) continue;

                const option = Math.floor(Math.random() * OPTIONS.length);
                await token.connect(user).approve(await market.getAddress(), betAmount);
                await market.connect(user).placeBet(eventId, option, betAmount);

                bets[eventId].push({ user: user.address, amount: betAmount, option });
            }
        }

        // 3. Fast-forward
        await time.increaseTo(deadline + 100);

        // 4. Resolve with random winners
        const winningOptions: Record<number, number> = {};
        for (let eventId = 1; eventId <= EVENT_COUNT; eventId++) {
            const winningOption = Math.floor(Math.random() * OPTIONS.length);
            await market.resolveEvent(eventId, winningOption);
            winningOptions[eventId] = winningOption;
        }

        // 5. Calculate expected payouts and claim
        const feeTracker: Record<number, bigint> = {};
        let totalFee: bigint = 0n;

        for (let eventId = 1; eventId <= EVENT_COUNT; eventId++) {
            const allBets = bets[eventId];
            const winnerOption = winningOptions[eventId];

            const totalPool = allBets.reduce((sum, b) => sum + b.amount, 0n);
            const winners = allBets.filter(b => b.option === winnerOption);
            const winnerPool = winners.reduce((sum, b) => sum + b.amount, 0n);

            for (const winner of winners) {
                const gross = (winner.amount * totalPool) / winnerPool;
                const fee = (gross * BigInt(FEE_PERCENT)) / 10000n;
                const net = gross - fee;
                totalFee += fee;

                const userSigner = users.find(u => u.address === winner.user)!;
                const before = await token.balanceOf(winner.user);
                const tx = await market.connect(userSigner).claimReward(eventId);
                await tx.wait();
                const after = await token.balanceOf(winner.user);

                expect(after - before).to.equal(net);
            }

            feeTracker[eventId] = (totalPool * BigInt(FEE_PERCENT)) / 10000n;
        }

        // 6. Check total fees collected
        const feeBalance = await token.balanceOf(feeRecipient);
        expect(feeBalance).to.equal(totalFee);
    });
});
