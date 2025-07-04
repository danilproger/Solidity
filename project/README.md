# Prediction Market

## 📜 Описание

**Prediction Market** — это децентрализованная платформа, позволяющая пользователям делать ставки на исход различных событий: спортивных матчей, политических выборов, новостей и др.

Каждое событие создаётся администратором и имеет:
- фиксированный дедлайн;
- от 2 до 5 вариантов исходов;
- разрешается вручную по истечении времени.

Участники делают ставки в токенах, и победители получают вознаграждение, пропорциональное своей ставке, с вычетом комиссии.

---

## 👨‍🎓 Автор

- **Имя**: *Ваулин Данил*
- **Дата**: 01.06.2025

---

## ⚙️ Технологии

- **Solidity (0.8.20)** — реализация смарт-контракта
- **Hardhat** — среда разработки и тестирования
- **Ethers v6 + TypeScript** — взаимодействие и скрипты
- **OpenZeppelin** — библиотека готовых контрактов (`AccessControl`, `ERC20Permit`, `ReentrancyGuard`)
- **Chai + Mocha** — тестирование

---

## 🧩 Основные функции смарт-контракта

### `createEvent(string description, string[] options, uint256 deadline)`
Создание нового события:

- `description`: описание события
- `options`: варианты исходов (2–5 строк)
- `deadline`: Unix-время, до которого можно ставить

> Только адреса с ролью `EVENT_CREATOR` могут вызывать эту функцию.

---

### `placeBet(uint256 eventId, uint256 optionIndex, uint256 amount)`
Пользователь делает ставку, предварительно вызвав `approve()`:

- `eventId`: ID события
- `optionIndex`: выбранный вариант (0-индексация)
- `amount`: ставка в токенах

Также доступен аналог `placeBetWithPermit(...)` для использования gasless-approve.

---

### `resolveEvent(uint256 eventId, uint256 winningOption)`
Разрешает событие:

- Доступно только после дедлайна
- `winningOption` — индекс выигравшего варианта

> Только для адресов с ролью `EVENT_RESOLVER`.

---

### `claimReward(uint256 eventId)`
Пользователь получает награду, если он выбрал правильный вариант и событие разрешено.

---

## 🧮 Математика & Токеномика

### 📈 Расчёт наград:

Пусть:
- `T` — общий пул ставок (`totalBets`)
- `W` — сумма ставок на выигравший исход (`winnerPool`)
- `U` — ставка пользователя

Тогда:
- **Gross reward** = `(U * T) / W`
- **Fee** = `grossReward * feePercent / 10000`
- **Net reward** = `grossReward - fee`

### 📊 Комиссия:
- Устанавливается в процентах (0–100%) с точностью до сотых:
- `500` = 5%
- `100` = 1%
- Комиссия начисляется **только при `claimReward`**, а не во время ставок.

---

## 🧪 Тестирование

Тестирование охватывает:
- Массовое создание событий (100+)
- Разные ставки от 20 пользователей
- Проверку корректности:
- Начисления наград
- Учёта комиссии
- Прав доступа (create / resolve / claim)
- Проверка баланса `feeRecipient`

---

## 🚀 Возможные улучшения

### 🧠 Децентрализованные оракулы
- Подключение **Chainlink Functions** для автоматического получения результата событий (например, спортивных матчей, выборов).

### 📊 Графовая индексация
- Интеграция **The Graph**
- Индексация событий
- Отображение ставок и истории пользователя
- Фильтрация и поиск

### 🌐 Фронтенд
- Интерфейс на **React + Tailwind + Wagmi + Viem**
- Создание, просмотр, ставки, награды
- Web3-взаимодействие с MetaMask

### 🧩 Децентрализация модерации
- Добавление механизма DAO-голосования за исход события вместо ручного `resolve`
- Добавление механизма DAO-голосования для создания событий

---

## 📂 Структура проекта

```
project/
├── contracts/
│   ├── PredictionMarket.sol
│   └── PredictionMarketToken.sol
│
├── scripts/
│   ├── claimReward.ts
│   ├── createEvent.ts
│   ├── deploy.ts
│   ├── placeBet.ts
│   └── resolveEvent.ts
│
├── test/
│   ├── PredictionMarketMassiveTest.ts
│   └── PredictionMarketTest.ts
│
├── typechain-types/
│   └── (сгенерированные типы для контрактов)
│
├── .gitignore
├── hardhat.config.ts
├── package.json
└── tsconfig.json

```

## 🏁 Запуск проекта

```bash
npm install
npx hardhat compile
npx hardhat test
npx hardhat coverage
```
