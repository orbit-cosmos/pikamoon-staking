// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import '../libraries/Stake.sol';

interface IPikaStaking {

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 _value, uint256 _lockDuration) external;

    function unstake(uint256 _stakeId) external;

    function claimYieldRewards() external;

    function updatePIKAPerSecond() external;

    function sync() external;

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setEndTime(uint256 _endTime) external;

    function changePoolWeight(uint256 _weight) external;

    function pause(bool _shouldPause) external;

    /* ========== READ FUNCTIONS ========== */

    function shouldUpdateRatio() external view returns (bool);

    function pendingRewards(address _staker) external view returns (uint256 pendingYield);

    function balanceOf(address _user) external view returns (uint256 balance);

    function getStakesLength(address _user) external view returns (uint256);

    function getStake(address _user, uint256 _stakeId) external view returns (Stake.Data memory);

    /* ========== EVENTS ========== */

    /**
     * @dev Fired in _stake() and stakeAsPool() in PIKAPool contract.
     * @param from token holder address, the tokens will be returned to that address
     * @param stakeId id of the new stake created
     * @param value value of tokens staked
     * @param lockUntil timestamp indicating when tokens should unlock (max 2 years)
     */
    event LogStake(address indexed from, uint256 stakeId, uint256 value, uint256 lockUntil);
    /**
     * @dev Fired in `_updateRewards()`.
     *
     * @param by an address which processed the rewards (staker or PIKA pool contract
     *            in case of a multiple claim call)
     * @param from an address which received the yield
     * @param yieldValue value of yield processed
     */
    event LogUpdateRewards(address indexed by, address indexed from, uint256 yieldValue);

    /**
     * @dev Fired in `unstake()`.
     *
     * @param to address receiving the tokens (user)
     * @param stakeId id value of the stake
     * @param value number of tokens unstaked
     */
    event LogUnstake(address indexed to, uint256 stakeId, uint256 value);
    /**
     * @dev Fired in `updatePIKAPerSecond()`.
     *
     * @param by an address which executed an action
     * @param newPIKAPerSecond new PIKA/second value
     */
    event LogUpdatePikaPerSecond(address indexed by, uint256 newPIKAPerSecond);
    /**
     * @dev Fired in `_sync()` and dependent functions (stake, unstake, etc.).
     *
     * @param by an address which performed an operation
     * @param yieldRewardsPerWeight updated yield rewards per weight value
     * @param lastYieldDistribution usually, current timestamp
     */
    event LogSync(address indexed by, uint256 yieldRewardsPerWeight, uint256 lastYieldDistribution);

    /**
     * @dev Fired in `updatePIKAPerSecond()`.
     *
     * @param by an address which executed an action
     * @param newPikaPerSecond new PIKA/second value
     */
    event LogUpdatePIKAPerSecond(address indexed by, uint256 newPikaPerSecond);

    /**
     * @dev Fired in `_claimYieldRewards()`.
     *
     * @param by an address which claimed the rewards (staker or PIKA pool contract
     *            in case of a multiple claim call)
     * @param from an address which received the yield
     * @param value value of yield paid
     */
    event LogClaimYieldRewards(address indexed by, address indexed from, uint256 value);
    /**
     * @dev Fired in `setEndTime()`.
     *
     * @param by an address which executed the action
     * @param endTime new endTime value
     */
    event LogSetEndTime(address indexed by, uint256 endTime);

    /**
     * @dev Fired in `changePoolWeight()`.
     *
     * @param by an address which executed an action
     * @param poolAddress deployed pool instance address
     * @param weight new pool weight
     */
    event LogChangePoolWeight(address indexed by, address indexed poolAddress, uint256 weight);

}
