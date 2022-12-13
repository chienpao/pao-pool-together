// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface ITinyPoolTogether {
    // Define the event for when someone join the pool
    event JoinPool(address user);

    // Define the event for when a round ends
    event EndRound();

    // Define the event for round winner
    event EndRoundWinner(address winner);

    // Define the event for when someone buy the ticket
    event BuyTicket(address user);

    // Define the event for when start a new round
    event StartRound();

    // Define the event for when someone withdraw
    event WithDraw(address user);

    // Define the event for when winner claim
    event Claim(address winner);
}
