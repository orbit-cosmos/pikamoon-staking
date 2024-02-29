import fs from "fs";
import csv from "csv-parser";
import { Addressable, ethers } from "ethers";
import { MerkleTree } from "merkletreejs";
import keccak256 from "keccak256";

type Data = { Wallet: string, Amount: number }
type Address = Addressable | String

const toWei = (value: number) => ethers.parseEther(value.toString());
function encodeLeaf(address: Address, amount: bigint) {
  // Same as `abi.encode` in Solidity
  let abi = ethers.AbiCoder.defaultAbiCoder();
  return abi.encode(["address", "uint256"], [address, amount]);
}
// Read CSV file
const csvFilePath = "address-bonusAmount.csv";
const rows: Array<Data> = [];
fs.createReadStream(csvFilePath)
  .pipe(csv())
  .on("data", (row: Data) => {
    rows.push(row);
  })
  .on("end", () => {
    const leaves = rows.map((row: { Wallet: string; Amount: number }) => {
      //   const data = `${row.Wallet}${" "}${row.Amount}`;
      //   console.log(data)
      return encodeLeaf(row.Wallet, toWei(row.Amount));
    });
    const merkleTree = new MerkleTree(leaves, keccak256, {
      hashLeaves: true,
      sortPairs: true,
    });
    const root = merkleTree.getHexRoot();
    console.log("root", root);
  });
