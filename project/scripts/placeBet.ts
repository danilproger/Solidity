import { ethers } from "ethers";
import { abi as MarketAbi } from "../artifacts/contracts/PredictionMarket.sol/PredictionMarket.json";
import { abi as TokenAbi } from "../artifacts/contracts/PredictionMarketToken.sol/PredictionMarketToken.json"; // замените на ваш токен

const PROVIDER_URL = process.env.RPC_URL!;
const PRIVATE_KEY = process.env.PRIVATE_KEY!;
const MARKET_ADDRESS = process.env.MARKET_ADDRESS!;
const TOKEN_ADDRESS = process.env.TOKEN_ADDRESS!;

const provider = new ethers.JsonRpcProvider(PROVIDER_URL);
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

const market = new ethers.Contract(MARKET_ADDRESS, MarketAbi, wallet);
const token = new ethers.Contract(TOKEN_ADDRESS, TokenAbi, wallet);

const eventId = 25;
const optionIndex = 0;
const amount = ethers.parseUnits("100", 18);

async function placeBet() {
    console.log(`Approve tokens on ${amount}`);
    const approveTx = await token.approve(MARKET_ADDRESS, amount);
    await approveTx.wait();
    console.log(`Approve tx hash: ${approveTx.hash}`);

    console.log(`Place bet on event ${eventId}, option ${optionIndex}`);
    const betTx = await market.placeBet(eventId, optionIndex, amount);
    await betTx.wait();
    console.log(`Bet placed, tx: ${betTx.hash}`);
}

placeBet().catch(console.error);
