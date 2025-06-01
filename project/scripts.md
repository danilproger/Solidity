## Скрипты

Деплой конкретного контракта
```shell
npx dotenv -e .env -- npx hardhat deploy --network sepolia --contract PredictionMarketToken --verify
npx dotenv -e .env -- npx hardhat deploy --network sepolia --contract PredictionMarket --args '["", "", ]' --verify
```