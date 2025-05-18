import {
    createPublicClient,
    createWalletClient,
    http,
    parseEther,
    formatEther,
    formatGwei,
    erc20Abi,
    formatUnits
} from 'viem';
import {sepolia} from 'viem/chains';
import {privateKeyToAccount} from 'viem/accounts';

const PRIVATE_KEY = process.env.PRIVATE_KEY_SEPOLIA;
const ERC_20_TOKEN_ADDRESS = process.env.TOKEN_ADDRESS;
const RECIPIENT_ADDRESS = process.env.RECIPIENT_ADDRESS;

const account = privateKeyToAccount(`0x${PRIVATE_KEY}`);

// Публичный клиент для чтения данных
const publicClient = createPublicClient({
    chain: sepolia,
    transport: http(),
});

// Клиент кошелька для отправки транзакций
const walletClient = createWalletClient({
    account,
    chain: sepolia,
    transport: http(),
});

async function main() {
    // Мета-информация о токене
    const [name, symbol, decimals, balance] = await Promise.all([
        publicClient.readContract({address: ERC_20_TOKEN_ADDRESS, abi: erc20Abi, functionName: 'name'}),
        publicClient.readContract({address: ERC_20_TOKEN_ADDRESS, abi: erc20Abi, functionName: 'symbol'}),
        publicClient.readContract({address: ERC_20_TOKEN_ADDRESS, abi: erc20Abi, functionName: 'decimals'}),
        publicClient.readContract({
            address: ERC_20_TOKEN_ADDRESS,
            abi: erc20Abi,
            functionName: 'balanceOf',
            args: [account.address]
        }),
    ]);

    console.log(`Token: ${name} (${symbol}), Decimals: ${decimals}`);
    console.log(`Balance of ${account.address}: ${formatUnits(balance, decimals)} ${symbol}`);

    // Перевод 100 токенов
    const amount = BigInt(100 * 10 ** decimals);
    const transferErc20TxHash = await walletClient.writeContract({
        address: ERC_20_TOKEN_ADDRESS,
        abi: erc20Abi,
        functionName: 'transfer',
        args: [RECIPIENT_ADDRESS, amount],
    });

    console.log(`Transfer erc20 transaction hash: ${transferErc20TxHash}`)

    // Баланс ETH
    const ethBalance = await publicClient.getBalance({address: account.address});
    console.log(`ETH Balance: ${formatEther(ethBalance)} ETH`);

    // Цена газа
    const gasPrice = await publicClient.getGasPrice();
    console.log(`Gas Price: ${formatGwei(gasPrice)} Gwei`);

    // Перевод эфира
    const sendEthTxHash = await walletClient.sendTransaction({
        to: RECIPIENT_ADDRESS,
        value: parseEther('0.001'),
    });

    console.log(`Send eth transaction hash: ${sendEthTxHash}`);

    await publicClient.waitForTransactionReceipt(
        { hash: sendEthTxHash }
    )
}

main().catch(console.error);
