// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract PredictionMarket is AccessControl, ReentrancyGuard {
    bytes32 public constant EVENT_CREATOR = keccak256("EVENT_CREATOR");
    bytes32 public constant EVENT_RESOLVER = keccak256("EVENT_RESOLVER");

    struct Bet {
        uint256 amount;
        uint256 option;
        bool claimed;
    }

    struct Event {
        string description;
        string[] options;
        uint256 deadline;
        uint256 winningOption;
        uint256 totalBets;
        mapping(uint256 => uint256) optionBets;
        mapping(address => Bet) bets;
        bool resolved;
    }

    event EventCreated(uint256 indexed eventId);
    event BetPlaced(uint256 indexed eventId, address indexed user, uint256 option, uint256 amount);
    event EventResolved(uint256 indexed eventId, uint256 winningOption);
    event RewardClaimed(uint256 indexed eventId, address indexed user, uint256 amount);

    ERC20Permit public token;
    uint256 public eventCounter;
    mapping(uint256 => Event) public events;

    uint256 public feePercent;
    address public feeRecipient;

    constructor(
        address _token,
        address _feeRecipient,
        uint256 _feePercent
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(EVENT_CREATOR, msg.sender);
        setFeePercent(_feePercent);
        setFeeRecipient(_feeRecipient);
        token = ERC20Permit(_token);
        eventCounter = 1;
    }

    modifier eventExists(uint256 eventId) {
        require(eventId < eventCounter, "Invalid event");
        _;
    }

    function createEvent(
        string memory description,
        string[] memory options,
        uint256 deadline
    ) public onlyRole(EVENT_CREATOR) {
        require(deadline > block.timestamp, "Deadline must be in future");
        require(2 <= options.length && options.length <= 5, "Two-five options required");

        Event storage e = events[eventCounter];
        e.description = description;
        e.deadline = deadline;
        e.options = options;

        emit EventCreated(eventCounter);
        eventCounter++;
    }

    /// Place bet using permit (gasless approval)
    function placeBetWithPermit(
        uint256 eventId,
        uint256 optionIndex,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant {
        token.permit(msg.sender, address(this), amount, deadline, v, r, s);
        token.transferFrom(msg.sender, address(this), amount);
        _placeBet(eventId, optionIndex, amount, msg.sender);
    }

    /// Place bet using normal approve + transferFrom
    function placeBet(
        uint256 eventId,
        uint256 optionIndex,
        uint256 amount
    ) external nonReentrant {
        token.transferFrom(msg.sender, address(this), amount);
        _placeBet(eventId, optionIndex, amount, msg.sender);
    }

    function _placeBet(
        uint256 eventId,
        uint256 optionIndex,
        uint256 amount,
        address bettor
    ) internal eventExists(eventId) {
        Event storage e = events[eventId];
        require(block.timestamp < e.deadline, "Betting closed");
        require(optionIndex < e.options.length, "Invalid option");
        require(amount > 0, "Amount must be > 0");
        require(e.bets[bettor].amount == 0, "Already placed a bet");

        e.bets[bettor] = Bet({
            amount: amount,
            option: optionIndex,
            claimed: false
        });

        e.optionBets[optionIndex] += amount;
        e.totalBets += amount;

        emit BetPlaced(eventId, bettor, optionIndex, amount);
    }

    function resolveEvent(
        uint256 eventId,
        uint256 winningOption
    ) external onlyRole(EVENT_RESOLVER) eventExists(eventId) {
        Event storage e = events[eventId];
        require(block.timestamp >= e.deadline, "Deadline not reached");
        require(!e.resolved, "Already resolved");
        require(winningOption < e.options.length, "Invalid option");

        e.resolved = true;
        e.winningOption = winningOption;

        emit EventResolved(eventId, winningOption);
    }

    function claimReward(
        uint256 eventId
    ) external eventExists(eventId) nonReentrant {
        Event storage e = events[eventId];
        require(e.resolved, "Event not resolved");
        Bet storage userBet = e.bets[msg.sender];
        require(userBet.amount > 0, "No bet");
        require(!userBet.claimed, "Already claimed");
        require(userBet.option == e.winningOption, "Not winner");

        uint256 winnerPool = e.optionBets[e.winningOption];
        uint256 grossReward = (userBet.amount * e.totalBets) / winnerPool;
        uint256 fee = (grossReward * feePercent) / 10000;
        uint256 netReward = grossReward - fee;

        userBet.claimed = true;

        if (fee > 0) {
            token.transfer(feeRecipient, fee);
        }

        token.transfer(msg.sender, netReward);

        emit RewardClaimed(eventId, msg.sender, netReward);
    }

    // 🔧 Admin fee config
    function setFeeRecipient(address _recipient) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_recipient != address(0), "Invalid address");
        feeRecipient = _recipient;
    }

    // _feePercent between 0 and 100 (0% to 100%) in double, e.g. 11 == 0.11%, 10000 == 100%, 500 == 5%
    function setFeePercent(uint256 _feePercent) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(1 <= _feePercent && _feePercent <= 10000, "Fee percent must be between 1 and 10000");
        feePercent = _feePercent;
    }

    // View Functions
    function getMarketEvent(
        uint256 eventId
    ) external view eventExists(eventId) returns (
        string memory description,
        string[] memory options,
        uint256 deadline,
        uint256 winningOption,
        uint256 totalBets,
        bool resolved
    ) {
        Event storage e = events[eventId];
        return (
            e.description,
            e.options,
            e.deadline,
            e.winningOption,
            e.totalBets,
            e.resolved
        );
    }

    function getEventCount() external view returns (uint256) {
        return eventCounter;
    }

    function getOptionBets(uint256 eventId) external view eventExists(eventId) returns (uint256[] memory) {
        Event storage e = events[eventId];
        uint256[] memory betsPerOption = new uint256[](e.options.length);
        for (uint256 i = 0; i < e.options.length; i++) {
            betsPerOption[i] = e.optionBets[i];
        }
        return betsPerOption;
    }

    function getUserBet(
        uint256 eventId,
        address user
    ) external view eventExists(eventId) returns (
        uint256 amount,
        uint256 option,
        bool claimed
    ) {
        Bet storage b = events[eventId].bets[user];
        return (b.amount, b.option, b.claimed);
    }

    function getEventOptions(uint256 eventId) external view eventExists(eventId) returns (string[] memory) {
        return events[eventId].options;
    }
}