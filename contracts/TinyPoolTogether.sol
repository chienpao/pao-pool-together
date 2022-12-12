// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";
import "./interfaces/ITinyPoolTogether.sol";
import "./interfaces/IPrizePool.sol";

contract TinyPoolTogether is ITinyPoolTogether, Ownable {
    
    // The participant deposits
    mapping(address => uint256) public deposits;

    // The participant list
    address[] participantList;

    // The round winner
    address public winner;

    // Round
    uint256 public roundDuration;
    uint256 public roundEnd;
    bool public roundActive;

    // The prize pool contract
    IPrizePool public immutable prizePool;

    // Ticket mapping for preparation
    mapping(address => uint256) public tickets;
    uint256 public ticketPrice;

    constructor(
        IPrizePool _prizePool,
        uint256 _ticketPrice,
        uint256 _roundDuration
    ) {
        prizePool = _prizePool;
        ticketPrice = _ticketPrice;
        roundDuration = _roundDuration;
        roundEnd = block.timestamp + roundDuration;
        roundActive = true;
    }

    function joinPool() external payable {
        require(msg.value > 0, "Amount must be greater than 0");
        require(roundActive, "Cannot join pool while round is not active");
        deposits[msg.sender] = deposits[msg.sender] + msg.value;
        prizePool.contribute{value: msg.value}();
        participantList.push(msg.sender);
        console.log("joinPool msg.sender: %s", msg.sender);

        // Emit a JoinPool event to notify other users
        emit JoinPool(msg.sender);
    }

    function endRound() external onlyOwner {
        require(prizePool.getBalance() > 0, "Cannot end round with empty pool");
        require(
            roundEnd <= block.timestamp,
            "Cannot end round before it has expired"
        );

        prizePool.mockStakingAfterOneWeek();

        //TODO: for random from chainlink
        uint256 randomIndex = 0;
        winner = participantList[randomIndex];
        console.log("winner: %s", winner);

        tickets[winner] = 0;
        deposits[winner] = 0;
        delete participantList;
        roundActive = false;

        // Emit a EndRound event to notify other users
        emit EndRound(winner);
    }

    function buyTicket() external payable {
        require(
            msg.value >= ticketPrice,
            "Amount must be greater than or equal to the ticket price"
        );
        require(roundActive, "Cannot buy ticket while round is not active");
        require(
            roundEnd > block.timestamp,
            "Cannot buy ticket after round has expired"
        );
        tickets[msg.sender] = tickets[msg.sender] + 1;

        // Emit a BuyTicket event to notify other users
        emit BuyTicket(msg.sender);
    }

    function startRound() external onlyOwner {
        require(
            !roundActive,
            "Cannot start round while round is already active"
        );
        roundActive = true;
        roundEnd = block.timestamp + roundDuration;

        // Emit a StartRound event to notify other users
        emit StartRound();
    }

    function withdraw() external {
        require(
            roundEnd <= block.timestamp,
            "Cannot withdraw before round has expired"
        );
        uint256 amount = deposits[msg.sender];
        deposits[msg.sender] = 0;
        prizePool.transferTo(payable(msg.sender), amount);

        // Emit a BuyTicket event to notify other users
        emit WithDraw(msg.sender);
    }

    function claim() external {
        require(
            roundEnd <= block.timestamp,
            "Cannot claim before round has expired"
        );
        require(msg.sender == winner, "Cannot claim if you are not the winner");

        //TODO: pool's not include everyone's balance, only staking revenue
        prizePool.transferRewardTo(payable(winner));
        roundActive = false;

        emit Claim(winner);
    }

    function setRoundActive() external onlyOwner {
        roundActive = !roundActive;
    }
}
