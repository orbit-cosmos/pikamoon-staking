import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { PikaMoon } from "../typechain-types";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

const ZeroAddress = ethers.ZeroAddress; 
const toWei = (value: number) => ethers.parseEther(value.toString());
// const fromWei = (value: number) => ethers.formatEther(value);
// const now = () => Math.floor(Date.now() / 1000);

describe("Pikamoon token", function () {
  async function deployFixture() {
    const [owner, otherAccount, account2, account3] = await ethers.getSigners();
    const pikamoon = await ethers.getContractFactory("PikaMoon");

    const token = await pikamoon.deploy(
      "PIKAMoon",
      "PIKA",
      toWei(50_000_000_000),
      owner.address,
      owner.address
    );
    await token.mint(otherAccount.address, toWei(5000));
    return { token, owner, otherAccount, account2, account3 };
  }
  describe("functional unit test", () => {
    let token: PikaMoon,
      owner: HardhatEthersSigner,
      otherAccount: HardhatEthersSigner,
      account2: HardhatEthersSigner,
      account3: HardhatEthersSigner;

    before(async () => {
      let fixture = await loadFixture(deployFixture);
      //@ts-ignore
      token = fixture?.token;
      owner = fixture?.owner;
      otherAccount = fixture?.otherAccount;
      account2 = fixture?.account2;
      account3 = fixture?.account3;
    });

    it("should allow minting", async () => {
      let bal = await token.balanceOf(otherAccount.address)
      await token.mint(otherAccount.address, toWei(5000));
      expect(await token.balanceOf(otherAccount.address)).to.be.equal(bal+toWei(5000));
    });
    it("should be equal to decimal 9", async () => {
      expect(await token.decimals()).to.be.equal(9);
    });
    it("should initialize Router And Pair", async () => {
      expect(await token.uniswapV2Pair()).to.be.equal(ZeroAddress);
      expect(await token.uniswapV2Router()).to.be.equal(ZeroAddress);
      await token.initRouterAndPair(
        "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"
      );
      expect(await token.uniswapV2Router()).to.be.equal(
        "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"
      );
    });
    it("should change marketing wallet", async () => {
      expect(await token.marketingWallet()).to.be.equal(owner.address);
      await token.changeMarketingWallet(account2.address);
      expect(await token.marketingWallet()).to.be.equal(account2.address);
    });
    it("should change ecosystem wallet", async () => {
      expect(await token.ecoSystemWallet()).to.be.equal(owner.address);
      await token.changeEcoSystemWallet(account3.address);
      expect(await token.ecoSystemWallet()).to.be.equal(account3.address);
    });
    it("should allow transfer", async () => {
      expect(await token.balanceOf(owner.address)).to.be.equal(0);
      await expect(
        token.connect(otherAccount).transfer(owner.address, toWei(500))
      ).to.emit(token, "Transfer");
      let tax = await token
      .connect(otherAccount)
      .calculateTax(otherAccount.address, toWei(500));
      expect(await token.balanceOf(owner.address)).to.be.equal(
        toWei(500) - tax[0]
      );
    });
    it("should allow transferFrom", async () => {
      expect(
        await token.allowance(otherAccount.address, owner.address)
      ).to.be.equal(0);
      await token.connect(otherAccount).approve(owner.address, toWei(500));
      expect(
        await token.allowance(otherAccount.address, owner.address)
      ).to.be.equal(toWei(500));
      let bal = await token.balanceOf(owner.address);
      await expect(
        token.transferFrom(otherAccount.address, owner.address, toWei(500))
      ).to.emit(token, "Transfer");
      let tax = await token
      .calculateTax(otherAccount.address, toWei(500));
      expect(await token.balanceOf(owner.address)).to.be.equal(
        bal + toWei(500) - tax[0]
      );
    });
    it("should allow excluding from tax", async () => {
      expect(await token.isExcludeFromTax(otherAccount.address)).to.be.equal(
        false
      );
      await token.excludeFromTax(otherAccount.address, true);
      expect(await token.isExcludeFromTax(otherAccount.address)).to.be.equal(
        true
      );
    });
    it("should toggle tax", async () => {
      expect(await token.isTaxEnabled()).to.be.equal(true);
      await token.toggleTax();
      expect(await token.isTaxEnabled()).to.be.equal(false);
    });
    it("should set marketing tx %", async () => {
      expect(await token.marketingTax()).to.be.equal(10);

      await token.setMarketingTax(20);
      expect(await token.marketingTax()).to.be.equal(20);
    });
    it("should set eco system tax %", async () => {
      expect(await token.ecosystemTax()).to.be.equal(10);
      await token.setEcoSystemTax(30);
      expect(await token.ecosystemTax()).to.be.equal(30);
    });
    it("should set burn tax %", async () => {
      expect(await token.burnTax()).to.be.equal(5);
      await token.setBurnTax(10);
      expect(await token.burnTax()).to.be.equal(10);
    });
    it("should allow burning", async () => {
      let bal = await token.balanceOf(otherAccount.address)
      await expect(token.burn(otherAccount.address, toWei(5)))
        .to.emit(token, "Transfer")
        .withArgs(otherAccount.address, ZeroAddress, toWei(5));
      expect(await token.balanceOf(otherAccount.address)).to.be.equal(bal-toWei(5));
    });
    it("should calculate tax correctly",async () => {
      await token.toggleTax();
      await token.excludeFromTax(otherAccount.address, false);
      let value = toWei(500)
      let burnAmount = (value * (await token.burnTax())) / BigInt(1000);
      let marketingAmount = (value * await token.marketingTax()) / BigInt(1000);
      let ecosystemAmount = (value * await token.ecosystemTax()) / BigInt(1000);
      let taxAmount = burnAmount + marketingAmount + ecosystemAmount;
      let tax = await token
      .calculateTax(otherAccount.address, toWei(500));
      expect(tax[0]).to.be.eq(taxAmount)
      
      await token.excludeFromTax(otherAccount.address, true);
      tax = await token
      .connect(otherAccount)
      .calculateTax(otherAccount.address, toWei(500));
      expect(tax[0]).to.be.eq(0)
    })
  });
});
