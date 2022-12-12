const { expect } = require("chai");
const { Contract, providers } = require("ethers");
const { HardhatRuntimeEnvironment } = require("hardhat/types");
const hre = require("hardhat");
const ethers = hre.ethers

const INITIAL_POOL_SIZE = 1000;
const TICKET_PRICE = 100;
const ROUND_DURATION = 60 * 60 * 24 * 7; // 1 week

describe("PoolTogether", () => {
  let tinyPoolTogetherContract;
  let prizePoolContract;
  let owner;
  let user1;
  let user2;

  beforeEach(async function () {
    const prizePoolFactory = await ethers.getContractFactory("PrizePool");
    prizePoolContract = await prizePoolFactory.deploy(
      INITIAL_POOL_SIZE
    );

    const tinyPoolTogetherFactory = await ethers.getContractFactory("TinyPoolTogether");
    tinyPoolTogetherContract = await tinyPoolTogetherFactory.deploy(
      prizePoolContract.address,
      TICKET_PRICE,
      ROUND_DURATION,
    );
    const [ownerEther, user1Ether, user2Ether] = await ethers.getSigners();
    owner = ownerEther;
    user1 = user1Ether;
    user2 = user2Ether;
  });

  it("should allow users to join the pool", async () => {
    await tinyPoolTogetherContract.connect(user1).joinPool({ value: INITIAL_POOL_SIZE });
    const deposit = await tinyPoolTogetherContract.deposits(user1.address);
    expect(deposit).to.equal(INITIAL_POOL_SIZE);
  });

  it("should select a random winner from the pool of users", async () => {
    await tinyPoolTogetherContract.connect(user1).joinPool({ value: INITIAL_POOL_SIZE });
    await tinyPoolTogetherContract.connect(user2).joinPool({ value: INITIAL_POOL_SIZE });

    // increase 1 week for evm
    await ethers.provider.send("evm_increaseTime", [ROUND_DURATION]);
    await tinyPoolTogetherContract.endRound();

    const winner = await tinyPoolTogetherContract.winner();
    expect(winner).to.be.oneOf([user1.address, user2.address]);
  });

  it("should reset the pool and user deposits when a round ends", async () => {
    await tinyPoolTogetherContract.connect(user1).joinPool({ value: INITIAL_POOL_SIZE });

    // increase 1 week for evm
    await ethers.provider.send("evm_increaseTime", [ROUND_DURATION]);
    await tinyPoolTogetherContract.endRound();

    // const pool = await tinyPoolTogetherContract.pool();
    // expect(pool).to.equal(0);
    const deposit = await tinyPoolTogetherContract.deposits(user1.address);
    expect(deposit).to.equal(0);
  });

  it("should allow users to purchase tickets and enter the lottery multiple times", async () => {
    await tinyPoolTogetherContract.connect(user1).buyTicket({ value: TICKET_PRICE });
    await tinyPoolTogetherContract.connect(user1).buyTicket({ value: TICKET_PRICE });
    const tickets = await tinyPoolTogetherContract.tickets(user1.address);
    expect(tickets).to.equal(2);
  });

  it("should reset the user's ticket count when a round ends", async () => {
    await tinyPoolTogetherContract.connect(user1).joinPool({ value: INITIAL_POOL_SIZE });
    await tinyPoolTogetherContract.connect(user1).buyTicket({ value: TICKET_PRICE });

    // increase 1 week for evm
    await ethers.provider.send("evm_increaseTime", [ROUND_DURATION]);
    await tinyPoolTogetherContract.endRound();

    const tickets = await tinyPoolTogetherContract.tickets(user1.address);
    expect(tickets).to.equal(0);
  });

  it("should allow the tinyPoolTogetherContract owner to start a new round", async () => {
    await tinyPoolTogetherContract.connect(user1).joinPool({ value: INITIAL_POOL_SIZE });

    // increase 1 week for evm
    await ethers.provider.send("evm_increaseTime", [ROUND_DURATION]);
    await tinyPoolTogetherContract.endRound();

    const roundActive = await tinyPoolTogetherContract.roundActive();
    expect(roundActive).to.be.false;

    await tinyPoolTogetherContract.startRound();
    const newRoundActive = await tinyPoolTogetherContract.roundActive();
    expect(newRoundActive).to.be.true;
  });

  it("should not allow users to join the pool if the round is not active", async () => {
    await tinyPoolTogetherContract.connect(user1).joinPool({ value: INITIAL_POOL_SIZE });

    // increase 1 week for evm
    await ethers.provider.send("evm_increaseTime", [ROUND_DURATION]);
    await tinyPoolTogetherContract.endRound();

    await expect(tinyPoolTogetherContract.joinPool({ value: INITIAL_POOL_SIZE })).to.be.rejectedWith(
      "Cannot join pool while round is not active"
    );
  });

  it("should not allow users to buy tickets if the round is not active", async () => {
    await tinyPoolTogetherContract.connect(user1).joinPool({ value: INITIAL_POOL_SIZE });

    // increase 1 week for evm
    await ethers.provider.send("evm_increaseTime", [ROUND_DURATION]);
    await tinyPoolTogetherContract.endRound();

    await expect(tinyPoolTogetherContract.buyTicket({ value: TICKET_PRICE })).to.be.rejectedWith(
      "Cannot buy ticket while round is not active"
    );
  });

  it("should allow users to withdraw their deposits if they are not the winner", async () => {
    await tinyPoolTogetherContract.connect(user1).joinPool({ value: INITIAL_POOL_SIZE });
    await tinyPoolTogetherContract.connect(user2).joinPool({ value: INITIAL_POOL_SIZE });

    // increase 1 week for evm
    await ethers.provider.send("evm_increaseTime", [ROUND_DURATION]);
    await tinyPoolTogetherContract.endRound();

    await tinyPoolTogetherContract.connect(user2).withdraw();
  });

  it("should not allow users to claim their prize if they are not the winner", async () => {
    await tinyPoolTogetherContract.connect(user1).joinPool({ value: INITIAL_POOL_SIZE });
    await tinyPoolTogetherContract.connect(user2).joinPool({ value: INITIAL_POOL_SIZE });

    // increase 1 week for evm
    await ethers.provider.send("evm_increaseTime", [ROUND_DURATION]);
    await tinyPoolTogetherContract.endRound();

    await expect(tinyPoolTogetherContract.connect(user2).claim()).to.be.rejectedWith(
      "Cannot claim if you are not the winner"
    );
  });

  it("should allow the winner to claim their prize", async () => {
    await tinyPoolTogetherContract.connect(user1).joinPool({ value: INITIAL_POOL_SIZE });
    await tinyPoolTogetherContract.connect(user2).joinPool({ value: INITIAL_POOL_SIZE });

    // increase 1 week for evm
    await ethers.provider.send("evm_increaseTime", [ROUND_DURATION]);
    await tinyPoolTogetherContract.endRound();

    await tinyPoolTogetherContract.connect(user1).claim();
  });
});
