import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { PikaMoon, PikaStakingPoolMock, PoolController } from "../typechain-types";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { time } from "@nomicfoundation/hardhat-network-helpers";

import { Address } from "../typechain-types/contracts/PikaMoon.sol";
import { ZeroAddress } from "ethers";

const toGWei = (value: number) => ethers.parseUnits(value.toString(), 9);
const INIT_TIME = 10n;
const PIKA_PER_SEC = 25367833587n;
const ONE_MONTH_IN_SECS = 30 * 24 * 60 * 60;
function encodeAndHash(
  address: Address | string,
  amount: bigint | number,
  restake: boolean,
  duration: bigint | number,
  nonce: bigint | number,
) {
  return ethers.solidityPackedKeccak256(
    ["address", "uint256", "bool", "uint256", "uint256"],
    [address, amount, restake, duration, nonce],
  );
}
describe("Pika Staking", function () {
  async function deployFixture() {
    const [owner, _, account1, account2, verifierAddress] = await ethers.getSigners();
    const pikamoon = await ethers.getContractFactory("PikaMoon");

    const token = await upgrades.deployProxy(
      pikamoon,
      ["PIKAMoon", "PIKA", owner.address, owner.address],
      { initializer: "initialize" },
    );

    const PoolController = await ethers.getContractFactory("PoolController");
    const poolController = await upgrades.deployProxy(PoolController, [], {
      initializer: "initialize",
    });

    const PikaStaking = await ethers.getContractFactory("PikaStakingPoolMock");

    await expect(
      upgrades.deployProxy(
        PikaStaking,
        [ZeroAddress, token.target, poolController.target, 200],
        { initializer: "initialize" },
      ),
    ).to.be.reverted;

    await expect(
      upgrades.deployProxy(
        PikaStaking,
        [token.target, ZeroAddress, poolController.target, 200],
        { initializer: "initialize" },
      ),
    ).to.be.reverted;
    await expect(
      upgrades.deployProxy(
        PikaStaking,
        [token.target, token.target, ZeroAddress, 200],
        { initializer: "initialize" },
      ),
    ).to.be.reverted;

    const staking = await upgrades.deployProxy(
      PikaStaking,
      [token.target, token.target, poolController.target, 200],
      { initializer: "initialize" },
    );

   
    await token.mint(poolController.target, toGWei(5_000_000_000));
    await token.mint(account2.address, toGWei(500));
    await token.mint(account1.address, toGWei(500));
    await token.excludeFromTax(staking.target, true);

    return { token, staking, owner, account1, account2, poolController, verifierAddress };
  }

  describe("test cases", async function () {
    let token: PikaMoon,
      staking: DirectStaking,
      owner: HardhatEthersSigner,
      poolController: PoolController,
      verifierAddress: HardhatEthersSigner,
      account1: HardhatEthersSigner,
      account2: HardhatEthersSigner;

    beforeEach(async () => {
      let fixture = await loadFixture(deployFixture);
      token = fixture?.token;
      staking = fixture?.staking;
      owner = fixture?.owner;
      account1 = fixture?.account1;
      account2 = fixture?.account2;
      poolController = fixture?.poolController;
      verifierAddress = fixture?.verifierAddress;
    });



    it("should accumulate PIKA correctly", async () => {
      await poolController.registerPool(staking.target);
      let stakingAmount = toGWei(50);
      await token.connect(account1).approve(staking.target, stakingAmount);


      await expect(
        staking.connect(account1).stake(stakingAmount, ONE_MONTH_IN_SECS),
      ).to.emit(staking, "LogStake");


      await staking.setNow256(INIT_TIME);

      const totalWeight = await poolController.totalWeight();
      const poolWeight = await staking.weight();

      const expectedRewards = (INIT_TIME * PIKA_PER_SEC * poolWeight) / totalWeight;
      const pendingYield = await staking.pendingRewards(account1.address);
      console.log(pendingYield)
      expect(`${expectedRewards}`.slice(0, 5)).to.be.equal(`${pendingYield}`.slice(0, 5));
    });


    it("should accumulate PIKA correctly for multiple stakers", async () => {
      await poolController.registerPool(staking.target);
      let stakingAmount = toGWei(50);
      await token.connect(account1).approve(staking.target, stakingAmount);


      await expect(
        staking.connect(account1).stake(stakingAmount, ONE_MONTH_IN_SECS),
      ).to.emit(staking, "LogStake");


      await token.connect(account2).approve(staking.target, stakingAmount);


      await expect(
        staking.connect(account2).stake(stakingAmount, ONE_MONTH_IN_SECS),
      ).to.emit(staking, "LogStake");


      await staking.setNow256(INIT_TIME+10n);

      const totalWeight = await poolController.totalWeight();
      const poolWeight = await staking.weight();

      const expectedRewards = ((INIT_TIME+10n) * PIKA_PER_SEC * poolWeight) / totalWeight;
      const pendingYield1 = await staking.pendingRewards(account1.address);
      const pendingYield2 = await staking.pendingRewards(account2.address);
      expect(`${expectedRewards/2n}`.slice(0, 5)).to.be.equal(`${pendingYield1}`.slice(0, 5));
      expect(`${expectedRewards/2n}`.slice(0, 5)).to.be.equal(`${pendingYield2}`.slice(0, 5));
    });
    it("should transfer pika from ",async()=>{
      await poolController.registerPool(staking.target);
      await staking.transferRewardPIKA(account1.address,100000000000000)
    })
    it("should transfer pika from ",async()=>{
      await expect(staking.transferRewardPIKA(account1.address,100000000000000)).to.be.revertedWithCustomError(poolController,"UnAuthorized")
    })

  })

})