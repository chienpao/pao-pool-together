const { expect } = require("chai");
const { Contract, providers } = require("ethers");
const { HardhatRuntimeEnvironment } = require("hardhat/types");
const hre = require("hardhat");
const ethers = hre.ethers

const INITIAL_POOL_SIZE = 1000;
const TICKET_PRICE = 100;
const ROUND_DURATION = 60 * 60 * 24 * 7; // 1 week

describe("PoolTogether", () => {
  let contract;
  let owner;
  let user1;
  let user2;

  beforeEach(async function () {
    this.timeout(60000);

    const tinyPoolTogetherFactory = await ethers.getContractFactory("TinyPoolTogether");
    contract = await tinyPoolTogetherFactory.deploy(
      "PoolTogether",
      "PT",
      18,
      INITIAL_POOL_SIZE,
      TICKET_PRICE,
      ROUND_DURATION,
    );
    const [ownerEther, user1Ether, user2Ether] = await ethers.getSigners();
    owner = ownerEther;
    user1 = user1Ether;
    user2 = user2Ether;
  });

  it("should allow users to join the pool", async () => {
    await contract.connect(user1).joinPool({ value: INITIAL_POOL_SIZE });
    const deposit = await contract.deposits(user1.address);
    expect(deposit).to.equal(INITIAL_POOL_SIZE);
  });

  it("should select a random winner from the pool of users", async () => {
    await contract.connect(user1).joinPool({ value: INITIAL_POOL_SIZE });
    await contract.connect(user2).joinPool({ value: INITIAL_POOL_SIZE });

    // increase 1 week for evm
    await ethers.provider.send("evm_increaseTime", [ROUND_DURATION]);
    await contract.endRound();

    const winner = await contract.winner();
    expect(winner).to.be.oneOf([user1.address, user2.address]);
  });
});
