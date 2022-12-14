// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";
import "../interfaces/ITicket.sol";

contract Ticket is ITicket, Ownable {
    // Ticket number mapping for participant
    mapping(address => uint256) public tickets;
    uint256 public ticketPrice;

    constructor(uint256 _ticketPrice) {
        ticketPrice = _ticketPrice;
    }

    function buyTicket(address participant) external payable override {
        require(
            msg.value >= ticketPrice,
            "Amount must be greater than or equal to the ticket price"
        );
        tickets[participant] = tickets[participant] + 1;

        // Emit a BuyTicket event to notify other users
        emit BuyTicket(participant);
    }

    function clearWinnerTicket(address winner) external override {
        tickets[winner] = 0;
    }
}
