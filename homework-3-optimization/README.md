# Lab-3 Optimization

Локальная нода
```shell
npx dotenv -e .env -- npx hardhat node
```

Деплой конкретного контракта
```shell
npx dotenv -e .env -- npx hardhat deploy --network local --contract
```
```shell
npx dotenv -e .env -- npx hardhat deploy --network sepolia --contract --verify
```

Тесты
```shell
npx dotenv -e .env -- npx hardhat test
```