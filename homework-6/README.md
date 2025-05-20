# Lab-6

## Скрипты

Локальная нода
```shell
npx dotenv -e .env -- npx hardhat node
```

Деплой конкретного контракта
```shell
npx dotenv -e .env -- npx hardhat deploy --network bscTestnet --contract ScamToken --verify
npx dotenv -e .env -- npx hardhat deploy --network polygonAmoy --contract WrappedScamToken --verify
npx dotenv -e .env -- npx hardhat deploy --network bscTestnet --contract BridgeBSC --args '[""]' --verify
npx dotenv -e .env -- npx hardhat deploy --network polygonAmoy --contract BridgePolygon --args '[""]' --verify
```

Запуск бэка моста
```shell
npx dotenv -e .env -- npx ts-node scripts/bridge.ts
```