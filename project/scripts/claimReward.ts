import { ethers } from "ethers";
import { abi as MarketAbi } from "../artifacts/contracts/PredictionMarket.sol/PredictionMarket.json";

const PROVIDER_URL = process.env.RPC_URL!;
const PRIVATE_KEY = process.env.PRIVATE_KEY!;
const MARKET_ADDRESS = process.env.MARKET_ADDRESS!;

const provider = new ethers.JsonRpcProvider(PROVIDER_URL);
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);
const market = new ethers.Contract(MARKET_ADDRESS, MarketAbi, wallet);

const eventId = 1;

async function claimReward() {
    console.log(`Claiming reward for event ${eventId}`);
    const tx = await market.claimReward(eventId);
    await tx.wait();
    console.log(`Reward claimed, tx: ${tx.hash}`);
}

claimReward().catch(console.error);
