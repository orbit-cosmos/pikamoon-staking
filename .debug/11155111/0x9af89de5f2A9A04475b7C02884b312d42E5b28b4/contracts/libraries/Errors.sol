// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * @dev This smart contract defines custom errors that can be thrown during specific conditions in contracts.
 */

library CommanErrors {
    error ZeroAmount();
    error ZeroAddress();
    error WrongTax();
    error PairIsAlreadyGivenValue();
}
