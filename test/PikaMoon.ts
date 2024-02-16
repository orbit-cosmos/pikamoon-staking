import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { PikaMoon } from "../typechain-types";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

const toWei = (value: number) => ethers.parseEther(value.toString());
const fromWei = (value: number) => ethers.formatEther(value);
const now = () => Math.floor(Date.now() / 1000);
describe("Pika token testcases", function () {
  async function deployFixture() {
    const [owner, otherAccount, account2] = await ethers.getSigners();
    const pikamoon = await ethers.getContractFactory("PikaMoon");

    const token = await pikamoon.deploy(
      "PIKAMoon",
      "PIKA",
      toWei(50_000_000_000),
      account2.address,
      account2.address
    );
    await token.mint(otherAccount.address, toWei(5000))
    return { token, owner, otherAccount, account2 };
  }
  describe("transfer", () => {
    let token:PikaMoon, owner:HardhatEthersSigner, otherAccount:HardhatEthersSigner;

    before(async () => {
      let fixture = await loadFixture(deployFixture);
      token = fixture?.token;
      owner = fixture?.owner;
      otherAccount = fixture?.otherAccount;
    });



    it("should allow transfer", async() => {
        await expect(token.connect(otherAccount).transfer(owner.address,toWei(500)))
        .to.emit(token,"Transfer")
    });


    it("should allow transferFrom", async() => {
        await token.connect(otherAccount).approve(owner.address,toWei(500))
        await expect(token.transferFrom(otherAccount.address,owner.address,toWei(500)))
        .to.emit(token,"Transfer")
    });
  });
});
