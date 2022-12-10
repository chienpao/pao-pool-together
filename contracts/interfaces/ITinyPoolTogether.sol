// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ITinyPoolTogether{
    // Define the event for when someone join the pool
  event JoinPool(address user);

  // Define the event for when a round ends with a winner
  event EndRound(address winner);
}