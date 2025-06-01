import { ethers } from "ethers";
import { abi as MarketAbi } from "../artifacts/contracts/PredictionMarket.sol/PredictionMarket.json";

const PROVIDER_URL = process.env.RPC_URL!;
const PRIVATE_KEY = process.env.PRIVATE_KEY!;
const MARKET_ADDRESS = process.env.MARKET_ADDRESS!;

const provider = new ethers.JsonRpcProvider(PROVIDER_URL);
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);
const market = new ethers.Contract(MARKET_ADDRESS, MarketAbi, wallet);

const eventId = 1;
const winningOption = 0;

async function resolveEvent() {
    console.log(`Resolving event #${eventId} with option ${winningOption}`);
    const tx = await market.resolveEvent(eventId, winningOption);
    await tx.wait();
    console.log(`Event ${eventId} resolved. Tx: ${tx.hash}`);
}

resolveEvent().catch(console.error);