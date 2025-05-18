# Lab-5

## Скрипты

Локальная нода
```shell
npx dotenv -e .env -- npx hardhat node
```

Деплой конкретного контракта
```shell
npx dotenv -e .env -- npx hardhat deploy --network local --contract ScamToken
```
```shell
npx dotenv -e .env -- npx hardhat deploy --network sepolia --contract ScamToken --verify
```

Тесты
```shell
npx dotenv -e .env -- npx hardhat test
```