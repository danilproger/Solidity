// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
  * Простая игра с ботом "Камень, Ножницы, Бумага" с использованием Chainlink VRF для генерации случайных чисел.
  */
contract RockPaperScissors is VRFConsumerBaseV2Plus {
    enum Move { Rock, Paper, Scissors }
    /**
    * Структура для хранения информации об игре.
    * @param player Адрес игрока.
    * @param playerMove Ход игрока.
    * @param completed Завершена ли игра.
    * @param result Результат игры.
    */
    struct Game {
        address player;
        Move playerMove;
        bool completed;
        string result;
    }

    uint256 private subscriptionId;
    bytes32 private keyHash;
    uint32 private callbackGasLimit = 100000;
    uint16 private requestConfirmations = 3;
    uint32 private numWords = 1;

    mapping(uint256 => Game) public games;

    event GameStarted(uint256 requestId, address indexed player, Move move);
    event GameCompleted(uint256 requestId, Move botMove, string result);

    constructor(
        uint256 _subscriptionId,
        address _vrfCoordinator,
        bytes32 _keyHash
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
    }

    // Начинало игру, отправляет шаг и запрос на случайное число и сохраняет информацию об игре.
    function play(Move move) external returns (uint256 requestId) {
        requestId = s_vrfCoordinator.requestRandomWords(VRFV2PlusClient.RandomWordsRequest({
            keyHash: keyHash,
            subId: subscriptionId,
            requestConfirmations: requestConfirmations,
            callbackGasLimit: callbackGasLimit,
            numWords: numWords,
            extraArgs: ""
        }));

        games[requestId] = Game({
            player: msg.sender,
            playerMove: move,
            completed: false,
            result: "Game Started"
        });

        emit GameStarted(requestId, msg.sender, move);
    }

    // Обработка случайного числа, полученного от Chainlink VRF.
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        Game storage game = games[requestId];
        require(!game.completed, "Already completed");

        Move botMove = Move(randomWords[0] % 3);
        string memory result;

        if (botMove == game.playerMove) {
            result = "Draw";
        } else if (
            (game.playerMove == Move.Rock && botMove == Move.Scissors) ||
            (game.playerMove == Move.Paper && botMove == Move.Rock) ||
            (game.playerMove == Move.Scissors && botMove == Move.Paper)
        ) {
            result = "Player Wins";
        } else {
            result = "Bot Wins";
        }

        game.completed = true;
        game.result = result;

        emit GameCompleted(requestId, botMove, result);
    }
}
