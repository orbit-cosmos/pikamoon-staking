// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * @dev This smart contract defines custom errors that can be thrown during specific conditions in contracts.
 * @notice Pre-defined errors instead of string error messages to reduce gas costs.
 */

library CommonErrors {
    error ZeroAmount();
    error ZeroAddress();
    error ContractIsPaused();
    error InvalidLockDuration();
    error OnlyFactory();
    error AlreadyRegistered();
    error WrongHash();
    error AlreadyUnstaked();
    error UnAuthorized();
    error CoolOffPeriodIsNotOver();
}
