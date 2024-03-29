// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./CorePool.sol";

contract DirectStaking is CorePool {
    constructor(
        address _poolToken,
        address _rewardToken,
        address _factory,
        uint256 _weight,
        address _stakingRewardAddress
    ) CorePool(_poolToken, _rewardToken,_factory,_weight, _stakingRewardAddress) {}
}
