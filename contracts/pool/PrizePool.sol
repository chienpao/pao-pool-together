// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";
import "../interfaces/IPrizePool.sol";

contract PrizePool is IPrizePool, Ownable {
    // The balance of the pool.
    uint256 public poolBalance;

    constructor(uint256 _initialPool) {
        poolBalance = _initialPool;
    }

    // This function allows users to contribute to the pool.
    function contribute() external payable override {
        require(msg.value > 0, "Must contribute a positive amount.");

        poolBalance += msg.value;
        console.log("contribute poolBalance: %s", poolBalance);
    }

    // This function allows users to withdraw money from the pool.
    function withdraw(uint256 amount) external override {
        require(
            amount > 0 && amount <= poolBalance,
            "Invalid withdrawal amount."
        );

        poolBalance -= amount;
        payable(msg.sender).transfer(amount);
    }

    // This function get current balance.
    function getBalance() external view override returns (uint256 balance) {
        return poolBalance;
    }

    // This function transfer to target
    function transferTo(address target, uint256 amount) external override {
        console.log("transferTo: %s", amount);
        payable(target).transfer(amount);
    }

    // This function transfer reward to target
    function transferRewardTo(address target) external override {
        console.log("transferRewardTo poolBalance: %s", poolBalance);
        payable(target).transfer(getReward());
    }

    function mockStakingAfterOneWeek() override external {
        poolBalance +=1000;
    }

    function getReward() private view returns (uint256 reward) {
        //TODO: retrieve fee as global parameter
        return (poolBalance * 5) / 10;
    }
}
