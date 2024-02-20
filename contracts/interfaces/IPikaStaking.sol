// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import '../libraries/Stake.sol';

interface IPikaStaking {
    function stake(uint256 _value, uint256 _lockDuration) external;

    function unstake(uint256 _stakeId, uint256 _value) external;

    function claimYieldRewards() external;

    function setEndTime(uint32 _endTime) external;

    function changePoolWeight(uint256 _weight) external;

    function pause(bool _shouldPause) external;

    function updatePIKAPerSecond() external;

    function shouldUpdateRatio() external view returns (bool);

    function pendingRewards(address _staker) external view returns (uint256 pendingYield);

    function balanceOf(address _user) external view returns (uint256 balance);

    function getStakesLength(address _user) external view returns (uint256);

    function getStake(address _user, uint256 _stakeId) external view returns (Stake.Data memory);
}
