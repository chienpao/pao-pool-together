// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";
import "./interfaces/ITinyPoolTogether.sol";
import "./interfaces/IPrizePool.sol";
import "./interfaces/IVRFv2Consumer.sol";
import "./interfaces/ITicket.sol";

contract TinyPoolTogether is ITinyPoolTogether, Ownable {
    // The participant deposits
    mapping(address => uint256) public deposits;

    // The participant list
    address[] participantList;

    // The round winner
    address public winner;

    // Round related
    uint256 public roundDuration;
    uint256 public roundEnd;
    bool public roundActive;

    // The prize pool contract
    IPrizePool public immutable prizePool;

    // The vrf contract
    IVRFv2Consumer public immutable vrf;
    uint256 requestId;

    // The prize pool contract
    ITicket public immutable ticket;

    constructor(
        IPrizePool _prizePool,
        IVRFv2Consumer _vrf,
        ITicket _ticket,
        uint256 _roundDuration
    ) {
        prizePool = _prizePool;
        vrf = _vrf;
        ticket = _ticket;
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
        // console.log("joinPool msg.sender: %s", msg.sender);

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

        // get request id for random number
        requestId = vrf.requestRandomWordsMock();

        roundActive = false;

        // Emit a EndRound event to notify other users
        emit EndRound();
    }

    function chooseWinner() external onlyOwner {
        require(prizePool.getBalance() > 0, "Cannot end round with empty pool");
        require(requestId > 0, "Cannot choose winner with invalid request id");

        (bool fulfilled, uint256[1] memory randomWords) = vrf
            .getRequestStatusMock(requestId);

        require(fulfilled, "Still waiting to choose winner");

        uint256 winnerIndex = randomWords[0] % participantList.length;
        winner = participantList[winnerIndex];
        ticket.clearWinnerTicket(winner);
        delete participantList;
        // console.log("winner: %s", winner);

        requestId = 0;
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

    function buyTicket() external payable{
        require(roundActive, "Cannot buy ticket while round is not active");
        require(
            roundEnd > block.timestamp,
            "Cannot buy ticket after round has expired"
        );
        ticket.buyTicket{value: msg.value}(msg.sender);
    }

    function withdraw() external {
        require(
            roundEnd <= block.timestamp,
            "Cannot withdraw before round has expired"
        );
        uint256 amount = deposits[msg.sender];
        deposits[msg.sender] = 0;
        prizePool.transferTo(payable(msg.sender), amount);

        // Emit a WithDraw event to notify other users
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

        // Emit a Claim event to notify other users
        emit Claim(winner);
    }
}
