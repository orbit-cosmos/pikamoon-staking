// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @dev This smart contract defines custom errors that can be thrown during specific conditions in contracts.
 */

library CommanErrors {
    error ZeroAmount();
    error TransferFailed();
    error ZeroAddress();
    error WithdrawFailed();
    error ExceedMaxTokens();
    error PhaseIsNotActive();
    error ClaimingNotStartedYet();
    error ThereIsNoReward();
    error ContractIsPaused();
    error InvalidLockDuration();
    error StakingTimeNotFinishedYet();
    error WrongUnStakeAmount();
    error WrongEndTime();
    error CanNotUpdateAtTheMoment();
}
