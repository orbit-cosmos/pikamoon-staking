// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "forge-std/console.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {IPikaMoon} from "./interfaces/IPikaMoon.sol";

contract ClaimBonusPika is Ownable {
    bytes32 public merkleRoot;
    address public token;
    mapping(address => bool) public isClaimable;
    
    constructor(address _token,bytes32 _merkleRoot) Ownable(_msgSender()) {
        require(_token != address(0),"zero address");
        token = _token;
        merkleRoot = _merkleRoot;
    }

    function claimBonusPika(
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) external  {
        console.log("------->");
        console.log(msg.sender);
        require(!isClaimable[_msgSender()],"already claimed");
        bytes32 leaf = keccak256(abi.encode(_msgSender(),_amount));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid markle proof"
        );

        isClaimable[_msgSender()] = true;
        bool s = IPikaMoon(token).transfer(_msgSender(),_amount);
        require(s);
    }

    function updateMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }
    // withdraw left over tokens. only use in case of emergency 
    function withdrawTokens() external onlyOwner {
        bool s = IPikaMoon(token).transfer(_msgSender(), IPikaMoon(token).balanceOf(address(this)));
        require(s);
    }
}
