// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ITinyPoolTogether {
    // Define the event for when someone join the pool
    event JoinPool(address user);

    // Define the event for when a round ends with a winner
    event EndRound(address winner);

    // Define the event for when someone buy the ticket
    event BuyTicket(address user);

    // Define the event for when start a new round
    event StartRound();

    // Define the event for when someone buy the ticket
    event WithDraw(address user);

    // Define the event for when start a new round
    event Claim(address winner);

    
}
