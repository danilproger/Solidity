import {createPublicClient, createWalletClient, Hex, http} from 'viem';
import {privateKeyToAccount} from 'viem/accounts';
import {bscTestnet, polygonAmoy} from 'viem/chains';

import {bridgeBSCAbi} from './abi/bridgeBSCAbi';
import {bridgePolygonAbi} from './abi/bridgePolygonAbi';

const PRIVATE_KEY_BSC = process.env.PRIVATE_KEY_BSC!;
const PRIVATE_KEY_POLYGON = process.env.PRIVATE_KEY_POLYGON!;
const BSC_BRIDGE_ADDRESS = process.env.BSC_BRIDGE_ADDRESS! as Hex;
const POLYGON_BRIDGE_ADDRESS = process.env.POLYGON_BRIDGE_ADDRESS! as Hex;

const accountBsc = privateKeyToAccount(`0x${PRIVATE_KEY_BSC}`);
const accountPolygon = privateKeyToAccount(`0x${PRIVATE_KEY_POLYGON}`);

const bscWalletClient = createWalletClient({chain: bscTestnet, transport: http(), account: accountBsc});
const polygonWalletClient = createWalletClient({chain: polygonAmoy, transport: http(), account: accountPolygon});

const bscPublic = createPublicClient({chain: bscTestnet, transport: http()});
const polygonPublic = createPublicClient({chain: polygonAmoy, transport: http('https://polygon-amoy.drpc.org')});

async function main(): Promise<void> {
    // Слушаем lock в BSC -> mint в Polygon
    bscPublic.watchContractEvent({
        address: BSC_BRIDGE_ADDRESS,
        abi: bridgeBSCAbi,
        eventName: 'Locked',
        onLogs: async (logs) => {
            for (const log of logs) {
                const {to, amount} = log.args;
                console.log(`[BSC] Locked: ${amount}, ${to} -> Mint on Polygon`);
                await polygonWalletClient.writeContract({
                    address: POLYGON_BRIDGE_ADDRESS,
                    abi: bridgePolygonAbi,
                    functionName: 'mint',
                    args: [to!, amount!],
                });
            }
        }
    });

    // Слушаем burn в Polygon -> release в BSC
    polygonPublic.watchContractEvent({
        address: POLYGON_BRIDGE_ADDRESS,
        abi: bridgePolygonAbi,
        eventName: 'Burned',
        onLogs: async (logs) => {
            for (const log of logs) {
                const {to, amount} = log.args;
                console.log(`[Polygon] Burned: ${amount}, ${to} -> Release on BSC`);
                await bscWalletClient.writeContract({
                    address: BSC_BRIDGE_ADDRESS,
                    abi: bridgeBSCAbi,
                    functionName: 'release',
                    args: [to!, amount!],
                });
            }
        }
    });
    console.log('Listening for events...');
}

// Run the main function
main().catch(console.error);