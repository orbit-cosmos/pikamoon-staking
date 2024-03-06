// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../contracts/ClaimBonusPika.sol";
import "../contracts/PikaMoon.sol";
import "./utils/Merkle.sol";


contract TestClaim is Test {
    PikaMoon public pikamoon;
    ClaimBonusPika public claim;
    Merkle public m;
    bytes32[] public data;

    function setUp() public {
        pikamoon = new PikaMoon(
            "Pikamoon",
            "PIKA",
            50000000000000000000,
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        // Initialize
        m = new Merkle();
        // Toy Data
        data = new bytes32[](4);
        data[0] = keccak256(
            abi.encode(0xDf6Fa9A3e89A31f942F543ad88C934eaC1672594, 5)
        );
        data[1] = keccak256(
            abi.encode(0x3a3cEE190139F70B98CC10fa24E50624cFeaDf07, 5)
        );
        data[2] = keccak256(
            abi.encode(0x32b0B0DCA1348Eb281F30B7430f1957eCaE700A3, 5)
        );
        data[3] = keccak256(
            abi.encode(0x0211ED1831046A907c0Bb03F206FE4F85667E942, 5)
        );

        // Get Root, Proof, and Verify
        bytes32 root = m.getRoot(data);

        claim = new ClaimBonusPika(address(pikamoon), root);
        pikamoon.mint(address(claim),11000);
    }

    function testTokenNameSymbol() public {
        assertTrue(pikamoon.decimals() == 9);
        assertEq(pikamoon.name(), "Pikamoon");
    }

    function testClaim() public {
        bytes32[] memory proof = m.getProof(data, 2); // will get proof for 0x2 value
        vm.prank(address(0x32b0B0DCA1348Eb281F30B7430f1957eCaE700A3));
        claim.claimBonusPika(5, proof);

    }

      function testInvalidProof() public {
        bytes32[] memory proof = m.getProof(data, 2); // will get proof for 0x2 value
        vm.expectRevert(bytes("Invalid markle proof"));
        claim.claimBonusPika(5, proof);

    }
}
