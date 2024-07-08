import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { PikaMoon, DirectStaking, PoolController } from "../typechain-types";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { time } from "@nomicfoundation/hardhat-network-helpers";

import { Address } from "../typechain-types/contracts/PikaMoon.sol";
import { ZeroAddress } from "ethers";

const toGWei = (value: number) => ethers.parseUnits(value.toString(), 9);

function encodeAndHash(
    address: Address | string,
    amount: bigint | number,
    restake: boolean,
    nonce: bigint | number,
) {
    return ethers.solidityPackedKeccak256(
        ["address", "uint256", "bool", "uint256"],
        [address, amount, restake, nonce],
    );
}
describe("Pika Staking", function () {
    async function deployFixture() {
        const [owner, _, account1, account2,account3, verifierAddress] = await ethers.getSigners();
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

        const PikaStaking = await ethers.getContractFactory("PikaStakingPool");

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

        await poolController.registerPool(staking.target);

        await token.mint(poolController.target, toGWei(5_000_000_000));
        await token.mint(account2.address, toGWei(100));
        await token.mint(account1.address, toGWei(100));
        await token.excludeFromTax(staking.target, true);
        await token.excludeFromTax(poolController.target, true);

        return { token, staking, owner, account1, account2, account3,poolController, verifierAddress };
    }

    describe("test cases", async function () {
        let token: PikaMoon,
            staking: DirectStaking,
            owner: HardhatEthersSigner,
            poolController: PoolController,
            verifierAddress: HardhatEthersSigner,
            account1: HardhatEthersSigner,
            account2: HardhatEthersSigner,
            account3: HardhatEthersSigner

        before(async () => {
            let fixture = await loadFixture(deployFixture);
            token = fixture?.token;
            staking = fixture?.staking;
            owner = fixture?.owner;
            account1 = fixture?.account1;
            account2 = fixture?.account2;
            account3 = fixture?.account3;
            poolController = fixture?.poolController;
            verifierAddress = fixture?.verifierAddress;
        });

        // ************* register pool **************
        it("test rewards after lock period ", async () => {
            let stakingAmount = toGWei(50);
            await token.connect(account1).approve(staking.target, stakingAmount);

            const ONE_MONTH_IN_SECS = 30 * 24 * 60 * 60;
            const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60;

            await expect(
                staking.connect(account1).stake(stakingAmount, ONE_MONTH_IN_SECS),
            ).to.emit(staking, "LogStake");



            await time.increase(30 * 24);



            let pendingYield = await staking.pendingRewards(account1.address);
            console.log("account1", pendingYield)
            await time.increase(30 * 24 * 60);
            pendingYield = await staking.pendingRewards(account1.address);
            console.log("account1", pendingYield)
            pendingYield = await staking.pendingRewards(account2.address);
            console.log("account2", pendingYield)



            await token.connect(account2).approve(staking.target, stakingAmount);
            await expect(
                staking.connect(account2).stake(stakingAmount, ONE_YEAR_IN_SECS),
            ).to.emit(staking, "LogStake");


            console.log("user info before lock duration", await staking.users(account1.address))



            await time.increase(30 * 24 * 60 * 60);
            console.log("time complete for account1")


            await token.connect(account2).approve(staking.target, stakingAmount);
            await expect(
                staking.connect(account2).stake(stakingAmount, ONE_YEAR_IN_SECS),
            ).to.emit(staking, "LogStake");




            pendingYield = await staking.pendingRewards(account1.address);
            console.log("account1", pendingYield)

            pendingYield = await staking.pendingRewards(account2.address);
            console.log("account2", pendingYield)

            await time.increase(30 * 24 * 60);

            pendingYield = await staking.pendingRewards(account1.address);
            console.log("account1", pendingYield)

            console.log("rewardsPerWeight", await staking.rewardsPerWeight())
            console.log("usnfor", await staking.users(account1.address))



            console.log("balance account1", await token.balanceOf(account1.address))
            let time_nonce = new Date().getTime();
            const message = encodeAndHash(
                account1.address,
                1000,
                false,
                time_nonce,
            );
            const signature = await owner.signMessage(ethers.toBeArray(message));
            await time.increase(30 * 24 * 60 * 60);
            await expect(
                staking
                    .connect(account1)
                    .claimRewards(1000, false, signature, time_nonce),
            ).to.emit(staking, "LogClaimRewards");

            console.log("balance account1", await token.balanceOf(account1.address))

            pendingYield = await staking.pendingRewards(account1.address);
            console.log("account1 after claim", pendingYield)
        })

        it("test claim cool off  ", async () => {

            let time_nonce = new Date().getTime();
            const message = encodeAndHash(
                account1.address,
                500,
                false,
                time_nonce,
            );
            const signature = await owner.signMessage(ethers.toBeArray(message));
            await expect(
                staking
                    .connect(account1)
                    .claimRewards(500, false, signature, time_nonce),
            ).to.be.revertedWithCustomError(staking, "CoolOffPeriodIsNotOver");
        })
        it("test claim pending Rewards zero ", async () => {

            let time_nonce = new Date().getTime();
            const message = encodeAndHash(
                account3.address,
                500,
                false,
                time_nonce,
            );
            const signature = await owner.signMessage(ethers.toBeArray(message));
            await 
                staking
                    .connect(account3)
                    .claimRewards(500, false, signature, time_nonce)
        })
        it("test claim Rewards  invalid operation", async () => {

            let time_nonce = new Date().getTime();
            const message = encodeAndHash(
                account2.address,
                0,
                false,
                time_nonce,
            );
            const signature = await owner.signMessage(ethers.toBeArray(message));
            await 
                expect(staking
                    .connect(account2)
                    .claimRewards(0, false, signature, time_nonce)).to.be.revertedWithCustomError(staking,"InvalidOperation")
        })

        it("test claim Rewards  invalid operation", async () => {

            let time_nonce = new Date().getTime();
            const message = encodeAndHash(
                account2.address,
                0,
                false,
                time_nonce,
            );
            const signature = await owner.signMessage(ethers.toBeArray(message));
            await 
                expect(staking
                    .connect(account2)
                    .claimRewards(0, false, signature, time_nonce)).to.be.revertedWithCustomError(staking,"InvalidOperation")
        })



    })
})