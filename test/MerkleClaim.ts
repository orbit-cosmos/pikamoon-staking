import { expect } from "chai";
import { ethers } from "hardhat";
import { Addressable } from "ethers";
import { MerkleTree } from "merkletreejs";
import keccak256 from "keccak256";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { PikaMoon, ClaimBonusPika } from "../typechain-types";
function encodeLeaf(address: Addressable | String, amount: bigint) {
  // Same as `abi.encode` in Solidity
  let abi = ethers.AbiCoder.defaultAbiCoder();
  return abi.encode(["address", "uint256"], [address, amount]);
}
const toWei = (value: number) => ethers.parseEther(value.toString());
describe("Check if merkle root is working", function () {
  async function deployICOFixture() {
    const [owner, addr1, addr2, addr3, addr4, addr5] =
      await ethers.getSigners();
    const ClaimBonusPika = await ethers.getContractFactory("ClaimBonusPika");
    const ICOToken = await ethers.getContractFactory("PikaMoon");
    const token: PikaMoon = await ICOToken.deploy(
      "PIKAMoon",
      "PIKA",
      toWei(50_000_000_000),
      owner.address,
      owner.address,
    );

    // Create an array of elements you wish to encode in the Merkle Tree
    const list = [
      encodeLeaf(addr1.address, toWei(2)),
      encodeLeaf(addr2.address, toWei(2)),
      encodeLeaf(addr3.address, toWei(2)),
      encodeLeaf(addr4.address, toWei(2)),
      encodeLeaf(addr5.address, toWei(2)),
    ];
    console.log(
      "0x" + keccak256(encodeLeaf(addr1.address,  toWei(2))).toString("hex"),
    );

    // Create the Merkle Tree using the hashing algorithm `keccak256`
    // Make sure to sort the tree so that it can be produced deterministically regardless
    // of the order of the input list
    const merkleTree = new MerkleTree(list, keccak256, {
      hashLeaves: true,
      sortPairs: true,
    });

    // Compute the Merkle Root
    const root = merkleTree.getHexRoot();

    const claimPika: ClaimBonusPika = await ClaimBonusPika.deploy(
      token.target,
      root,
    );
    await token.mint(claimPika.target, toWei(50_000));

    return { token, merkleTree, list, claimPika, owner, addr1 };
  }
  describe("", async () => {
    let token: PikaMoon,
      claimPika: ClaimBonusPika,
      owner: HardhatEthersSigner,
      addr1: HardhatEthersSigner,
      merkleTree: MerkleTree,
      list: string[];
    before(async () => {
      let fixture = await loadFixture(deployICOFixture);
      token = fixture?.token;
      claimPika = fixture?.claimPika;
      merkleTree = fixture?.merkleTree;
      list = fixture?.list;
      addr1 = fixture?.addr1;
      owner = fixture?.owner;
    });
    it("Should be able to verify if a given address can claim or not", async function () {
      // Compute the Merkle Proof of the owner address (0'th item in list)
      // off-chain. The leaf node is the hash of that value.

      const leaf = keccak256(list[0]);
      const proof = merkleTree.getHexProof(leaf);

      await expect(
        claimPika.connect(addr1).claimBonusPika(toWei(3), proof),
      ).to.be.revertedWith("Invalid markle proof");
      await claimPika.connect(addr1).claimBonusPika(toWei(2), proof);
      await expect(
        claimPika.connect(addr1).claimBonusPika(toWei(2), proof),
      ).to.be.revertedWith("already claimed");
      let tax = await token.calculateTax(owner.address, toWei(2));

      expect(await token.balanceOf(addr1.address)).to.be.equal(
        toWei(2) - tax[0],
      );
    });

    it("withdraw tokens", async () => {
      await claimPika.withdrawTokens();
    });
    it("change markle root", async () => {
      // Create an array of elements you wish to encode in the Merkle Tree
      const list = [encodeLeaf(addr1.address, toWei(2))];
      // console.log(
      //   "0x" + keccak256(encodeLeaf(addr1.address,  toWei(2))).toString("hex"),
      // );

      // Create the Merkle Tree using the hashing algorithm `keccak256`
      // Make sure to sort the tree so that it can be produced deterministically regardless
      // of the order of the input list
      const merkleTree = new MerkleTree(list, keccak256, {
        hashLeaves: true,
        sortPairs: true,
      });

      // Compute the Merkle Root
      const root = merkleTree.getHexRoot();
      await claimPika.updateMerkleRoot(root);

      let getRoot = await claimPika.merkleRoot();
      expect(getRoot).to.be.eq(root);
    });
  });
});
