// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";
import "./interfaces/ITinyPoolTogether.sol";

contract TinyPoolTogether is ITinyPoolTogether, Ownable {

  uint256 public pool;
  mapping(address => uint256) public deposits;
  mapping(address => uint256) public tickets;
  address[] userAddressArray;
  address public winner;
  uint256 public ticketPrice;
  uint256 public roundDuration;
  uint256 public roundEnd;
  bool public roundActive;

  constructor(
    uint256 _initialPool,
    uint256 _ticketPrice,
    uint256 _roundDuration
  ){
    pool = _initialPool;
    ticketPrice = _ticketPrice;
    roundDuration = _roundDuration;
    roundEnd = block.timestamp + roundDuration;
    roundActive = true;
  }

  function joinPool() external payable {
    require(msg.value > 0, "Amount must be greater than 0");
    require(roundActive, "Cannot join pool while round is not active");
    deposits[msg.sender] = deposits[msg.sender] + msg.value;
    pool = pool + msg.value;
    userAddressArray.push(msg.sender);
    console.log("joinPool msg.sender: %s", msg.sender);

    // Emit a JoinPool event to notify other users
    emit JoinPool(msg.sender);
  }

  function endRound() onlyOwner external {
    require(pool > 0, "Cannot end round with empty pool");
    require(roundEnd <= block.timestamp, "Cannot end round before it has expired");

    //TODO: for random from chainlink
    uint randomIndex = 0;
    winner = userAddressArray[randomIndex];

    pool = 0;
    tickets[winner] = 0;
    deposits[winner] = 0;
    roundActive = false;

    // Emit a EndRound event to notify other users
    emit EndRound(winner);
  }

  function buyTicket() external payable {
    require(msg.value >= ticketPrice, "Amount must be greater than or equal to the ticket price");
    require(roundActive, "Cannot buy ticket while round is not active");
    require(roundEnd > block.timestamp, "Cannot buy ticket after round has expired");
    tickets[msg.sender] = tickets[msg.sender] + 1;
  }

  function startRound() onlyOwner external {
    require(!roundActive, "Cannot start round while round is already active");
    roundActive = true;
    roundEnd = block.timestamp + roundDuration;
  }

  function withdraw() external {
    require(roundEnd <= block.timestamp, "Cannot withdraw before round has expired");
    require(
      msg.sender != winner,
      "Cannot withdraw if you are the winner"
    );
    uint256 amount = deposits[msg.sender];
    deposits[msg.sender] = 0;
    payable(msg.sender).transfer(amount);
  }

  function claim() external {
    require(roundEnd <= block.timestamp, "Cannot claim before round has expired");
    require(msg.sender == winner, "Cannot claim if you are not the winner");
    uint256 amount = pool*9/10;
    payable(winner).transfer(amount);
    pool = 0;
    roundActive = false;
  }

  function setRoundActive() onlyOwner external{
    roundActive = !roundActive;
  }
}
