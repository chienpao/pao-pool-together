// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IPrizePool {
    // This function allows users to contribute to the pool.
    function contribute() external payable;

    // This function allows users to withdraw money from the pool.
    function withdraw(uint256 amount) external;

    // This function get current balance.
    function getBalance() external view returns (uint256 balance);

    // This function transfer to target
    function transferTo(address target, uint256 amount) external;

    // This function transfer reward to target
    function transferRewardTo(address target) external;

    // This function get current balance.
    function mockStakingAfterOneWeek() external;

    //****** Interactive with Compound *******/
    // function staking() external;
}
