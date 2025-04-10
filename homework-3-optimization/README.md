# Lab-3 Optimization

## Скрипты

Локальная нода
```shell
npx dotenv -e .env -- npx hardhat node
```

Деплой конкретного контракта
```shell
npx dotenv -e .env -- npx hardhat deploy --network local --contract BookStorage
```
```shell
npx dotenv -e .env -- npx hardhat deploy --network sepolia --contract BookStorage --verify
```

Тесты
```shell
npx dotenv -e .env -- npx hardhat test
```

## Оптимизации

### До оптимизаций

```
·------------------------------------|----------------------------|-------------|-----------------------------·
|        Solc version: 0.8.28        ·  Optimizer enabled: false  ·  Runs: 200  ·  Block limit: 30000000 gas  │
·····································|····························|·············|······························
|  Methods                                                                                                    │
················|····················|··············|·············|·············|···············|··············
|  Contract     ·  Method            ·  Min         ·  Max        ·  Avg        ·  # calls      ·  usd (avg)  │
················|····················|··············|·············|·············|···············|··············
|  BookStorage  ·  addBook           ·      165750  ·     182946  ·     177173  ·           12  ·          -  │
················|····················|··············|·············|·············|···············|··············
|  BookStorage  ·  averagePageCount  ·           -  ·          -  ·      31938  ·            2  ·          -  │
················|····················|··············|·············|·············|···············|··············
|  BookStorage  ·  getBook           ·           -  ·          -  ·      40399  ·            2  ·          -  │
················|····················|··············|·············|·············|···············|··············
|  BookStorage  ·  totalCost         ·           -  ·          -  ·      31548  ·            2  ·          -  │
················|····················|··············|·············|·············|···············|··············
|  BookStorage  ·  updatePrice       ·           -  ·          -  ·      34542  ·            2  ·          -  │
················|····················|··············|·············|·············|···············|··············
|  Deployments                       ·                                          ·  % of limit   ·             │
·····································|··············|·············|·············|···············|··············
|  BookStorage                       ·           -  ·          -  ·     967151  ·        4.1 %  ·          -  │
·------------------------------------|--------------|-------------|-------------|---------------|-------------·
```

### 1. Упаковка структуры и типы

До
```solidity
struct Book {
    string title;
    string author;
    uint256 pageCount;
    string genre;
    uint256 publicationYear;
    uint256 price;
}
```
После
```solidity
struct Book {
    string title;
    string author;
    uint256 price;
    uint16 pageCount;
    uint16 genre;
    uint16 publicationYear;
}
```

Genre можно заменить как uint, тк количество жанров обычно ограничено

```
·------------------------------------|----------------------------|-------------|-----------------------------·
|        Solc version: 0.8.28        ·  Optimizer enabled: false  ·  Runs: 200  ·  Block limit: 30000000 gas  │
·····································|····························|·············|······························
|  Methods                                                                                                    │
················|····················|··············|·············|·············|···············|··············
|  Contract     ·  Method            ·  Min         ·  Max        ·  Avg        ·  # calls      ·  usd (avg)  │
················|····················|··············|·············|·············|···············|··············
|  BookStorage  ·  addBook           ·      120727  ·     137887  ·     132136  ·           12  ·          -  │
················|····················|··············|·············|·············|···············|··············
|  BookStorage  ·  averagePageCount  ·           -  ·          -  ·      32064  ·            2  ·          -  │
················|····················|··············|·············|·············|···············|··············
|  BookStorage  ·  getBook           ·           -  ·          -  ·      35625  ·            2  ·          -  │
················|····················|··············|·············|·············|···············|··············
|  BookStorage  ·  totalCost         ·           -  ·          -  ·      31548  ·            2  ·          -  │
················|····················|··············|·············|·············|···············|··············
|  BookStorage  ·  updatePrice       ·           -  ·          -  ·      34542  ·            2  ·          -  │
················|····················|··············|·············|·············|···············|··············
|  Deployments                       ·                                          ·  % of limit   ·             │
·····································|··············|·············|·············|···············|··············
|  BookStorage                       ·           -  ·          -  ·    997038   ·        4.3 %  ·          -  │
·------------------------------------|--------------|-------------|-------------|---------------|-------------·
```

| Метод            | До     | После  |
|------------------|--------|--------|
| addBook          | 177173 | 132136 |
| averagePageCount | 31938  | 32064  |
| getBook          | 40399  | 35625  |
| totalCost        | 31548  | 31548  |
| updatePrice      | 34542  | 34542  |
| deploy           | 967151 | 997038 |

- addBook, getBook значительно снизились по цене

### 2. Calldata в аргументах

До
```solidity
function addBook(
    string memory title,
    string memory author,
    uint16 pageCount,
    uint16 genre,
    uint16 publicationYear,
    uint256 price
)
```
После
```solidity
function addBook(
    string calldata title,
    string calldata author,
    uint16 pageCount,
    uint16 genre,
    uint16 publicationYear,
    uint256 price
)
```

```
·------------------------------------|----------------------------|-------------|-----------------------------·
|        Solc version: 0.8.28        ·  Optimizer enabled: false  ·  Runs: 200  ·  Block limit: 30000000 gas  │
·····································|····························|·············|······························
|  Methods                                                                                                    │
················|····················|··············|·············|·············|···············|··············
|  Contract     ·  Method            ·  Min         ·  Max        ·  Avg        ·  # calls      ·  usd (avg)  │
················|····················|··············|·············|·············|···············|··············
|  BookStorage  ·  addBook           ·      120169  ·     137329  ·     131578  ·           12  ·          -  │
················|····················|··············|·············|·············|···············|··············
|  BookStorage  ·  averagePageCount  ·           -  ·          -  ·      32064  ·            2  ·          -  │
················|····················|··············|·············|·············|···············|··············
|  BookStorage  ·  getBook           ·           -  ·          -  ·      35625  ·            2  ·          -  │
················|····················|··············|·············|·············|···············|··············
|  BookStorage  ·  totalCost         ·           -  ·          -  ·      31548  ·            2  ·          -  │
················|····················|··············|·············|·············|···············|··············
|  BookStorage  ·  updatePrice       ·           -  ·          -  ·      34542  ·            2  ·          -  │
················|····················|··············|·············|·············|···············|··············
|  Deployments                       ·                                          ·  % of limit   ·             │
·····································|··············|·············|·············|···············|··············
|  BookStorage                       ·           -  ·          -  ·    992061   ·        4.3 %  ·          -  │
·------------------------------------|--------------|-------------|-------------|---------------|-------------·
```

| Метод            | До     | После  |
|------------------|--------|--------|
| addBook          | 132136 | 131578 |
| averagePageCount | 32064  | 32064  |
| getBook          | 35625  | 35625  |
| totalCost        | 31548  | 31548  |
| updatePrice      | 34542  | 34542  |
| deploy           | 997038 | 992061 |

- addBook снизился по цене

### 3. Оптимизация структуры хранения

До
```solidity
Book[] public books;
```
После
```solidity
mapping(uint256 => Book) public books;
uint256 public booksCount;
```

```
·------------------------------------|----------------------------|-------------|-----------------------------·
|        Solc version: 0.8.28        ·  Optimizer enabled: false  ·  Runs: 200  ·  Block limit: 30000000 gas  │
·····································|····························|·············|······························
|  Methods                                                                                                    │
················|····················|··············|·············|·············|···············|··············
|  Contract     ·  Method            ·  Min         ·  Max        ·  Avg        ·  # calls      ·  usd (avg)  │
················|····················|··············|·············|·············|···············|··············
|  BookStorage  ·  addBook           ·      120274  ·     137434  ·     130545  ·           10  ·          -  │
················|····················|··············|·············|·············|···············|··············
|  BookStorage  ·  averagePageCount  ·           -  ·          -  ·      31562  ·            2  ·          -  │
················|····················|··············|·············|·············|···············|··············
|  BookStorage  ·  getBook           ·           -  ·          -  ·      35482  ·            2  ·          -  │
················|····················|··············|·············|·············|···············|··············
|  BookStorage  ·  totalCost         ·           -  ·          -  ·      31177  ·            2  ·          -  │
················|····················|··············|·············|·············|···············|··············
|  BookStorage  ·  updatePrice       ·           -  ·          -  ·      34542  ·            2  ·          -  │
················|····················|··············|·············|·············|···············|··············
|  Deployments                       ·                                          ·  % of limit   ·             │
·····································|··············|·············|·············|···············|··············
|  BookStorage                       ·           -  ·          -  ·     934241  ·        3.1 %  ·          -  │
·------------------------------------|--------------|-------------|-------------|---------------|-------------·
```

| Метод            | До     | После  |
|------------------|--------|--------|
| addBook          | 131578 | 130545 |
| averagePageCount | 32064  | 31562  |
| getBook          | 35625  | 35482  |
| totalCost        | 31548  | 31177  |
| updatePrice      | 34542  | 34542  |
| deploy           | 992061 | 934241 |

- все методы, кроме updatePrice, включая деплой уменьшились в цене

### 4. Использование unchecked

До
```solidity
function averagePageCount() public returns (uint256) {
    require(booksCount > 0, "No books available");
    uint256 totalPages = 0;
    for (uint256 i = 0; i < booksCount; i++) {
        totalPages += books[i].pageCount;
    }
    return totalPages / booksCount;
}

function totalCost() public returns (uint256) {
    uint256 sum = 0;
    for (uint256 i = 0; i < booksCount; i++) {
        sum += books[i].price;
    }
    return sum;
}
```
После
```solidity
function totalCost() public returns (uint256) {
    unchecked {
        uint256 sum = 0;
        for (uint256 i = 0; i < booksCount; i++) {
            sum += books[i].price;
        }
        return sum;
    }
}

function averagePageCount() public returns (uint256) {
    unchecked {
        uint256 totalPages = 0;
        for (uint256 i = 0; i < booksCount; i++) {
            totalPages += books[i].pageCount;
        }
        return totalPages / booksCount;
    }
}
```

```
·------------------------------------|----------------------------|-------------|-----------------------------·
|        Solc version: 0.8.28        ·  Optimizer enabled: false  ·  Runs: 200  ·  Block limit: 30000000 gas  │
·····································|····························|·············|······························
|  Methods                                                                                                    │
················|····················|··············|·············|·············|···············|··············
|  Contract     ·  Method            ·  Min         ·  Max        ·  Avg        ·  # calls      ·  usd (avg)  │
················|····················|··············|·············|·············|···············|··············
|  BookStorage  ·  addBook           ·      120274  ·     137434  ·     130545  ·           10  ·          -  │
················|····················|··············|·············|·············|···············|··············
|  BookStorage  ·  averagePageCount  ·           -  ·          -  ·      30976  ·            2  ·          -  │
················|····················|··············|·············|·············|···············|··············
|  BookStorage  ·  getBook           ·           -  ·          -  ·      35482  ·            2  ·          -  │
················|····················|··············|·············|·············|···············|··············
|  BookStorage  ·  totalCost         ·           -  ·          -  ·      30631  ·            2  ·          -  │
················|····················|··············|·············|·············|···············|··············
|  BookStorage  ·  updatePrice       ·           -  ·          -  ·      34542  ·            2  ·          -  │
················|····················|··············|·············|·············|···············|··············
|  Deployments                       ·                                          ·  % of limit   ·             │
·····································|··············|·············|·············|···············|··············
|  BookStorage                       ·           -  ·          -  ·     932141  ·          3 %  ·          -  │
·------------------------------------|--------------|-------------|-------------|---------------|-------------·
```

| Метод            | До     | После  |
|------------------|--------|--------|
| addBook          | 130545 | 130545 |
| averagePageCount | 31562  | 30976  |
| getBook          | 35482  | 35482  |
| totalCost        | 31177  | 30631  |
| updatePrice      | 34542  | 34542  |
| deploy           | 934241 | 932141 |

- totalCost и averagePageCount уменьшились в цене

### 5. При обновлении одного поля не тянуть всю структуру (memory vs storage)

До
```solidity
function updatePrice(uint256 index, uint256 newPrice) public {
    require(index < booksCount, "Index out of bounds");
    Book memory book = books[index];
    book.price = newPrice;
}
```

После
```solidity
function updatePrice(uint256 index, uint256 newPrice) public {
    require(index < booksCount, "Index out of bounds");
    Book storage book = books[index];
    book.price = newPrice;
}
```

```
·------------------------------------|----------------------------|-------------|-----------------------------·
|        Solc version: 0.8.28        ·  Optimizer enabled: false  ·  Runs: 200  ·  Block limit: 30000000 gas  │
·····································|····························|·············|······························
|  Methods                                                                                                    │
················|····················|··············|·············|·············|···············|··············
|  Contract     ·  Method            ·  Min         ·  Max        ·  Avg        ·  # calls      ·  usd (avg)  │
················|····················|··············|·············|·············|···············|··············
|  BookStorage  ·  addBook           ·      120274  ·     137434  ·     130545  ·           10  ·          -  │
················|····················|··············|·············|·············|···············|··············
|  BookStorage  ·  averagePageCount  ·           -  ·          -  ·      30976  ·            2  ·          -  │
················|····················|··············|·············|·············|···············|··············
|  BookStorage  ·  getBook           ·           -  ·          -  ·      35482  ·            2  ·          -  │
················|····················|··············|·············|·············|···············|··············
|  BookStorage  ·  totalCost         ·           -  ·          -  ·      30631  ·            2  ·          -  │
················|····················|··············|·············|·············|···············|··············
|  BookStorage  ·  updatePrice       ·           -  ·          -  ·      29227  ·            2  ·          -  │
················|····················|··············|·············|·············|···············|··············
|  Deployments                       ·                                          ·  % of limit   ·             │
·····································|··············|·············|·············|···············|··············
|  BookStorage                       ·           -  ·          -  ·     933329  ·        3.1 %  ·          -  │
·------------------------------------|--------------|-------------|-------------|---------------|-------------·
```

| Метод            | До     | После  |
|------------------|--------|--------|
| addBook          | 130545 | 130545 |
| averagePageCount | 30976  | 30976  |
| getBook          | 35482  | 35482  |
| totalCost        | 30631  | 30631  |
| updatePrice      | 34542  | 29227  |
| deploy           | 932141 | 933329 |

- updatePrice уменьшился в цене

### 6. Оптимизация компиляции

```javascript
solidity: {
    version: "0.8.28",
    settings: {
        optimizer: {
            enabled: true,
            runs: 200
        }
    }
}
```

```
·------------------------------------|---------------------------|-------------|-----------------------------·
|        Solc version: 0.8.28        ·  Optimizer enabled: true  ·  Runs: 200  ·  Block limit: 30000000 gas  │
·····································|···························|·············|······························
|  Methods                                                                                                   │
················|····················|·············|·············|·············|···············|··············
|  Contract     ·  Method            ·  Min        ·  Max        ·  Avg        ·  # calls      ·  usd (avg)  │
················|····················|·············|·············|·············|···············|··············
|  BookStorage  ·  addBook           ·     118649  ·     135809  ·     128920  ·           10  ·          -  │
················|····················|·············|·············|·············|···············|··············
|  BookStorage  ·  averagePageCount  ·          -  ·          -  ·      30680  ·            2  ·          -  │
················|····················|·············|·············|·············|···············|··············
|  BookStorage  ·  getBook           ·          -  ·          -  ·      34404  ·            2  ·          -  │
················|····················|·············|·············|·············|···············|··············
|  BookStorage  ·  totalCost         ·          -  ·          -  ·      30431  ·            2  ·          -  │
················|····················|·············|·············|·············|···············|··············
|  BookStorage  ·  updatePrice       ·          -  ·          -  ·      28862  ·            2  ·          -  │
················|····················|·············|·············|·············|···············|··············
|  Deployments                       ·                                         ·  % of limit   ·             │
·····································|·············|·············|·············|···············|··············
|  BookStorage                       ·          -  ·          -  ·     642083  ·        2.1 %  ·          -  │
·------------------------------------|-------------|-------------|-------------|---------------|-------------·
```

| Метод            | До     | После  |
|------------------|--------|--------|
| addBook          | 130545 | 128920 |
| averagePageCount | 30976  | 30680  |
| getBook          | 35482  | 34404  |
| totalCost        | 30631  | 30431  |
| updatePrice      | 29227  | 28862  |
| deploy           | 933329 | 642083 |

- все методы уменьшились в цене, деплой сильно уменьшился

### Итоги

| Метод            | До     | После  |
|------------------|--------|--------|
| addBook          | 177173 | 128920 |
| averagePageCount | 31938  | 30680  |
| getBook          | 40399  | 34404  |
| totalCost        | 31548  | 30431  |
| updatePrice      | 34542  | 28862  |
| deploy           | 967151 | 642083 |

Получилось уменьшить по стоимости газа все методы