// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface ITicket {
    // Define the event for when someone buy the ticket
    event BuyTicket(address user);

    // Buy ticket for get more change to win the lottery
    function buyTicket(address participant) external payable;

    // Clear winner ticket for end round
    function clearWinnerTicket(address winner) external;
}
