// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/PikaMoon.sol";
contract ContractTest is Test {
    PikaMoon pikamoon;
    function setUp() public {
        pikamoon = new PikaMoon(
            "Pikamoon",
            "PIKA",
            50000000000000000000,
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
    }

    function testExample() public {
        assertTrue(pikamoon.decimals() == 9);
        assertEq(pikamoon.name(), "Pikamoon");
    }
    function testFailTransfer() public {
        pikamoon.transfer(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,2);
    }
    
    function testFuzzTransfer(address add,bool b) public {
        pikamoon.excludeFromTax(add,b);
    }

 

}
