import { ethers } from "ethers";
import { abi as PredictionMarketAbi } from "../artifacts/contracts/PredictionMarket.sol/PredictionMarket.json";

const PROVIDER_URL = process.env.RPC_URL!;
const PRIVATE_KEY = process.env.PRIVATE_KEY!;
const MARKET_ADDRESS = process.env.MARKET_ADDRESS!;

const provider = new ethers.JsonRpcProvider(PROVIDER_URL);
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);
const predictionMarket = new ethers.Contract(MARKET_ADDRESS, PredictionMarketAbi, wallet);

const events = [
    { description: "UEFA Euro 2025: Winner", options: ["France", "Germany", "Spain", "England", "Italy"] },
    { description: "NBA Finals 2025: Champion", options: ["Celtics", "Lakers", "Nuggets", "Bucks"] },
];

async function createEvents() {
    const txs = [];
    for (let i = 0; i < events.length; i++) {
        const ev = events[i];
        const deadline = Math.floor(Date.now() / 1000) + (i + 900);

        console.log(`Creating event ${i + 1}/${events.length}: ${ev.description}`);
        const tx = await predictionMarket.createEvent(ev.description, ev.options, deadline);
        txs.push(tx);
        console.log(`Event ${i + 1} created, tx: ${tx.hash}`);
    }
    await Promise.all(txs.map(tx => tx.wait()));
}

createEvents().catch(console.error);
