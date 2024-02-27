// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {Pausable} from '@openzeppelin/contracts/utils/Pausable.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {IPikaMoon} from './interfaces/IPikaMoon.sol';
import {Stake} from './libraries/Stake.sol';
import {CommanErrors} from './libraries/Errors.sol';
import './interfaces/IPikaStaking.sol';
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// import "hardhat/console.sol";

contract PikaStaking is Ownable, Pausable, IPikaStaking {
    using Stake for Stake.Data;
    using Stake for uint256;
//   using SafeERC20 for IERC20;
    /// @dev Data structure representing token holder.
    struct User {
        /// @dev pending yield rewards to be claimed
        uint256 pendingYield;
        /// @dev Total weight
        uint256 totalWeight;
        /// @dev Checkpoint variable for yield calculation
        uint256 yieldRewardsPerWeightPaid;
        /// @dev An array of holder's stakes
        Stake.Data[] stakes;
    }

    /// @dev Used to calculate yield rewards.
    /// @dev This value is different from "reward per token" used in flash pool.
    /// @dev Note: stakes are different in duration and "weight" reflects that.
    uint256 public yieldRewardsPerWeight;

    /**
     * @dev The yield is distributed proportionally to pool weights;
     *      total weight is here to help in determining the proportion.
     */
    uint256 public totalWeight;

    /// @dev Timestamp of the last yield distribution event.
    uint256 public lastYieldDistribution;

    /// @dev Link to the pool token instance, for example PIKA or PIKA/ETH pair.
    address public poolToken;

    /**  @notice you can lock your tokens for a period between 1 and 12 months. 
    This changes your token weight. By increasing the duration of your lock, 
    you will increase the token weight of the locked tokens. 
    The maximum weight of a locked token is 2 , 
    which occurs when you lock for a period of 12 months.
    
    @dev Pool weight, initial values are 200 for PIKA pool and 800 for PIKA/ETH.
    */
    uint256 public weight;
    /// @dev Used to calculate rewards, keeps track of the tokens weight locked in staking.
    uint256 public globalWeight;
    /// @dev total pool token reserve
    uint256 public poolTokenReserve;

    /**
     * @dev PIKA/second determines yield farming reward base
     *      used by the yield pools controlled by the factory.
     */
    uint192 public pikaPerSecond;

    /**
     * @dev PIKA/second decreases by 3% every seconds/update
     *      an update is triggered by executing `updatePIKAPerSecond` public function.
     */
    uint256 public secondsPerUpdate;

    /**
     * @dev End time is the last timestamp when PIKA/second can be decreased;
     *      it is implied that yield farming stops after that timestamp.
     */
    uint256 public endTime;

    /**
     * @dev Each time the PIKA/second ratio gets updated, the timestamp
     *      when the operation has occurred gets recorded into `lastRatioUpdate`.
     * @dev This timestamp is then used to check if seconds/update `secondsPerUpdate`
     *      has passed when decreasing yield reward by 3%.
     */
    uint256 public lastRatioUpdate;

    /// @dev Token holder storage, maps token holder address to their data record.
    mapping(address => User) public users;

    /**
     * @dev Fired in _stake() and stakeAsPool() in PIKAPool contract.
     * @param by address that executed the stake function (user or pool)
     * @param from token holder address, the tokens will be returned to that address
     * @param stakeId id of the new stake created
     * @param value value of tokens staked
     * @param lockUntil timestamp indicating when tokens should unlock (max 2 years)
     */
    event LogStake(address indexed by, address indexed from, uint256 stakeId, uint256 value, uint256 lockUntil);
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
     * @dev Fired in `unstakeLocked()`.
     *
     * @param to address receiving the tokens (user)
     * @param stakeId id value of the stake
     * @param value number of tokens unstaked
     */
    event LogUnstakeLocked(address indexed to, uint256 stakeId, uint256 value);
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
    event LogSetEndTime(address indexed by, uint32 endTime);

    /**
     * @dev Fired in `changePoolWeight()`.
     *
     * @param by an address which executed an action
     * @param poolAddress deployed pool instance address
     * @param weight new pool weight
     */
    event LogChangePoolWeight(address indexed by, address indexed poolAddress, uint256 weight);

    constructor(address _poolToken) Ownable(msg.sender) {
        if (_poolToken == address(0)) {
            revert CommanErrors.ZeroAddress();
        }
        poolToken = _poolToken;
        // init the dependent internal state variables
        lastYieldDistribution = _now256();
        weight = 200; //(direct staking)200
        pikaPerSecond = 0.01 ether;
        secondsPerUpdate = 14 days;
        lastRatioUpdate = _now256();
        endTime = _now256() + (5 * 30 days); // 5 months
        totalWeight = 1000; //(direct staking)200 + (pool staking)800
    }

    /**
     * @notice Stakes specified value of tokens for the specified value of time,
     *      and pays pending yield rewards if any.
     *
     * @dev Requires value to stake and lock duration to be greater than zero.
     *
     * @param _value value of tokens to stake
     * @param _lockDuration stake duration as unix timestamp
     */

    function stake(uint256 _value, uint256 _lockDuration) external {
        // checks if the contract is in a paused state
        if (paused()) revert CommanErrors.ContractIsPaused();

        // validate the inputs
        if (_value == 0) revert CommanErrors.ZeroAmount();
        if (!(_lockDuration >= Stake.MIN_STAKE_PERIOD && _lockDuration <= Stake.MAX_STAKE_PERIOD)) {
            revert CommanErrors.InvalidLockDuration();
        }

        // get a link to user data struct, we will write to it later
        User storage user = users[msg.sender];
        // update user state
        _updateReward(msg.sender);
        // calculates until when a stake is going to be locked
        uint256 lockUntil = _now256() + _lockDuration;
        // stake weight formula rewards for locking
        uint256 stakeWeight = (((lockUntil - _now256()) * Stake.WEIGHT_MULTIPLIER) /
            Stake.MAX_STAKE_PERIOD +
            Stake.BASE_WEIGHT) * _value;
        // makes sure stakeWeight is valid
        assert(stakeWeight > 0);
        // create and save the stake (append it to stakes array)
        Stake.Data memory userStake = Stake.Data({value: _value, lockedFrom: _now256(), lockedUntil: lockUntil});
        // pushes new stake to `stakes` array
        user.stakes.push(userStake);
        // update user weight
        user.totalWeight += (stakeWeight);
        // update global weight value and global pool token count
        globalWeight += stakeWeight;
        poolTokenReserve += _value;

        // transfer `_value`
        IPikaMoon(poolToken).transferFrom(msg.sender, address(this), _value);

        // emits an event
        emit LogStake(msg.sender, msg.sender, (user.stakes.length - 1), _value, lockUntil);
    }

    /**
     * @dev Unstakes a stake that has been previously locked, and is now in an unlocked
     *      state. Otherwise it transfers PIKA
     *      from the contract balance.
     *
     * @param _stakeId stake ID to unstake from, zero-indexed
     * @param _value value of tokens to unstake
     */
    function unstake(uint256 _stakeId, uint256 _value) external {
        // checks if the contract is in a paused state
        if (paused()) revert CommanErrors.ContractIsPaused();

        // validate the inputs
        if (_value == 0) revert CommanErrors.ZeroAmount();

        // get a link to user data struct, we will write to it later
        User storage user = users[msg.sender];
        // update user state
        _updateReward(msg.sender);
        // get a link to the corresponding stake, we may write to it later
        Stake.Data storage userStake = user.stakes[_stakeId];
        // checks if stake is unlocked already
        if (!(_now256() > userStake.lockedUntil)) revert CommanErrors.StakingTimeNotFinishedYet();

        // we also save stakeValue for gasSavings
        uint256 stakeValue = userStake.value;
        // verify available balance
        if (!(stakeValue >= _value)) revert CommanErrors.WrongUnStakeAmount();
        // store stake weight
        uint256 previousWeight = userStake.weight();
        // value used to save new weight after updates in storage
        uint256 newWeight;

        // update the stake, or delete it if its depleted
        if (stakeValue - _value == 0) {
            // deletes stake struct, no need to save new weight because it stays 0
            delete user.stakes[_stakeId];
        } else {
            userStake.value -= _value;
            // saves new weight to memory
            newWeight = userStake.weight();
        }
        // update user record
        user.totalWeight = user.totalWeight - previousWeight + newWeight;
        // update global weight variable
        globalWeight = globalWeight - previousWeight + newWeight;
        // update global pool token count
        poolTokenReserve -= _value;

        // otherwise just return tokens back to holder
        IPikaMoon(poolToken).transfer(msg.sender, _value);

        // emits an event
        emit LogUnstakeLocked(msg.sender, _stakeId, _value);
    }

    /**
     * @dev claims all pending staking rewards.
     */
    function claimYieldRewards() external {
        // checks if the contract is in a paused state
        if (paused()) revert CommanErrors.ContractIsPaused();
        address _staker = msg.sender;
        // update user state
        _updateReward(_staker);
        // get link to a user data structure, we will write into it later
        User storage user = users[_staker];

        // check pending yield rewards to claim and save to memory
        uint256 pendingYieldToClaim = user.pendingYield;
        // if pending yield is zero - just return silently
        if (pendingYieldToClaim == 0) return;
        // clears user pending yield
        user.pendingYield = 0;

        IPikaMoon(poolToken).mint(_staker, pendingYieldToClaim);
        // emits an event
        emit LogClaimYieldRewards(msg.sender, _staker, pendingYieldToClaim);
    }

    /**
     * @dev Updates yield generation ending timestamp.
     *
     * @param _endTime new end time value to be stored
     */
    function setEndTime(uint32 _endTime) external onlyOwner {
        // checks if _endTime is a timestap after the last time that
        // PIKA/second has been updated
        if (!(_endTime > lastRatioUpdate)) {
            revert CommanErrors.WrongEndTime();
        }
        // updates endTime state var
        endTime = _endTime;

        // emits an event
        emit LogSetEndTime(msg.sender, _endTime);
    }

    /**
     * @dev Changes the weight of the pool;
     *      executed by the pool itself or by the factory owner.
     *
     * @param _weight new weight value to set to
     */
    function changePoolWeight(uint256 _weight) external onlyOwner {
        // recalculate total weight
        totalWeight = totalWeight + _weight - weight;

        // set the new pool weight
        weight = _weight;

        // emits an event
        emit LogChangePoolWeight(msg.sender, address(this), weight);
    }

    /**
     * @dev Set paused/unpaused state in the staking contract.
     * @param _shouldPause whether the contract should be paused/unpausd
     */
    function pause(bool _shouldPause) external onlyOwner {
        // checks bool input and pause/unpause the contract depending on
        // msg.sender's request
        if (_shouldPause) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
     * @notice Decreases PIKA/second reward by 3%, can be executed
     *      no more than once per `secondsPerUpdate` seconds.
     */
    function updatePIKAPerSecond() public {
        // checks if ratio can be updated i.e. if seconds/update have passed
        if (!shouldUpdateRatio()) revert CommanErrors.CanNotUpdateAtTheMoment();

        // decreases PIKA/second reward by 3%.
        // To achieve that we multiply by 97 and then
        // divide by 100
        pikaPerSecond = (pikaPerSecond * 97) / 100;

        // set current timestamp as the last ratio update timestamp
        lastRatioUpdate = _now256();

        // emits an event
        emit LogUpdatePikaPerSecond(msg.sender, pikaPerSecond);
    }

    /**
     * @dev Used internally, mostly by children implementations, see `sync()`.
     *
     * @dev Updates smart contract state (`yieldRewardsPerWeight`, `lastYieldDistribution`),
     *      updates factory state via `updatePIKAPerSecond`
     */
    function _sync() internal {
        // update PIKA per second value in factory if required
        if (shouldUpdateRatio()) {
            updatePIKAPerSecond();
        }

        // check bound conditions and if these are not met -
        // exit silently, without emitting an event
        if (lastYieldDistribution >= endTime) {
            return;
        }
        if (_now256() <= lastYieldDistribution) {
            return;
        }
        // if locking weight is zero - update only `lastYieldDistribution` and exit
        if (globalWeight == 0) {
            lastYieldDistribution = _now256();
            return;
        }

        // to calculate the reward we need to know how many seconds passed, and reward per second
        uint256 currentTimestamp = _now256() > endTime ? endTime : _now256();
        uint256 secondsPassed = currentTimestamp - lastYieldDistribution;

        // calculate the reward
        uint256 pikaReward = (secondsPassed * pikaPerSecond * weight) / totalWeight;

        // update rewards per weight and `lastYieldDistribution`
        yieldRewardsPerWeight += pikaReward.getRewardPerWeight(globalWeight);
        lastYieldDistribution = currentTimestamp;

        // emits an event
        emit LogSync(msg.sender, yieldRewardsPerWeight, lastYieldDistribution);
    }

    /**
     * @dev Must be called every time user.totalWeight is changed.
     * @dev Syncs the global pool state, processes the user pending rewards (if any),
     *      and updates check points values stored in the user struct.
     * @dev If user is coming from v1 pool, it expects to receive this v1 user weight
     *      to include in rewards calculations.
     *
     * @param _staker user address
     */
    function _updateReward(address _staker) internal {
        // update pool state
        _sync();
        // gets storage reference to the user
        User storage user = users[_staker];
        // gas savings
        uint256 userTotalWeight = user.totalWeight;

        // calculates pending yield to be added
        uint256 pendingYield = userTotalWeight.earned(yieldRewardsPerWeight, user.yieldRewardsPerWeightPaid);
        // calculates pending reenue distribution to be added
        // increases stored user.pendingYield with value returned
        user.pendingYield += pendingYield;
        // increases stored user.pendingRevDis with value returned

        // updates user checkpoint values for future calculations
        user.yieldRewardsPerWeightPaid = yieldRewardsPerWeight;

        // emits an event
        emit LogUpdateRewards(msg.sender, _staker, pendingYield);
    }

    function _now256() internal view returns (uint256) {
        // return current block timestamp
        return block.timestamp;
    }

    /**
     * @dev Verifies if `secondsPerUpdate` has passed since last PIKA/second
     *      ratio update and if PIKA/second reward can be decreased by 3%.
     *
     * @return true if enough time has passed and `updatePIKAPerSecond` can be executed.
     */
    function shouldUpdateRatio() public view returns (bool) {
        // if yield farming period has ended
        if (_now256() > endTime) {
            // PIKA/second reward cannot be updated anymore
            return false;
        }

        // check if seconds/update have passed since last update
        return _now256() >= lastRatioUpdate + secondsPerUpdate;
    }

    /**
     * @notice Calculates current yield rewards value available for address specified.
     *
     * @dev See `_pendingRewards()` for further details.
     *
     * @dev External `pendingRewards()` returns pendingYield and pendingRevDis
     *         accumulated with already stored user.pendingYield and user.pendingRevDis.
     *
     * @param _staker an address to calculate yield rewards value for
     */
    function pendingRewards(address _staker) external view returns (uint256 pendingYield) {
        if (_staker == address(0)) revert CommanErrors.ZeroAddress();
        // `newYieldRewardsPerWeight` will be the stored or recalculated value for `yieldRewardsPerWeight`
        uint256 newYieldRewardsPerWeight;
        // gas savings
        uint256 _lastYieldDistribution = lastYieldDistribution;

        // based on the rewards per weight value, calculate pending rewards;
        User storage user = users[_staker];
        // initializes both variables from one storage slot
        uint256 userWeight = user.totalWeight;

        // if smart contract state was not updated recently, `yieldRewardsPerWeight` value
        // is outdated and we need to recalculate it in order to calculate pending rewards correctly
        if (_now256() > _lastYieldDistribution && globalWeight != 0) {
            uint256 multiplier = _now256() > endTime
                ? endTime - _lastYieldDistribution
                : _now256() - _lastYieldDistribution;
            uint256 pikaRewards = (multiplier * weight * pikaPerSecond) / totalWeight;

            // recalculated value for `yieldRewardsPerWeight`
            newYieldRewardsPerWeight = pikaRewards.getRewardPerWeight((globalWeight)) + yieldRewardsPerWeight;
        } else {
            // if smart contract state is up to date, we don't recalculate
            newYieldRewardsPerWeight = yieldRewardsPerWeight;
        }

        pendingYield =
            (userWeight).earned(newYieldRewardsPerWeight, user.yieldRewardsPerWeightPaid) +
            user.pendingYield;
    }

    /**
     * @notice Returns total staked token balance for the given address.
     * @dev Loops through stakes and returns total balance.
     * @notice Expected to be called externally through `eth_call`. Gas shouldn't
     *         be an issue here.
     *
     * @param _user an address to query balance for
     * @return balance total staked token balance
     */
    function balanceOf(address _user) external view returns (uint256 balance) {
        // gets storage pointer to _user
        User memory user = users[_user];
        // loops over each user stake and adds to the total balance.
        for (uint256 i = 0; i < user.stakes.length; i++) {
            balance += user.stakes[i].value;
        }
    }

    /**
     * @notice Returns number of stakes for the given address. Allows iteration over stakes.
     *
     * @dev See `getStake()`.
     *
     * @param _user an address to query stake length for
     * @return number of stakes for the given address
     */
    function getStakesLength(address _user) external view returns (uint256) {
        // read stakes array length and return
        return users[_user].stakes.length;
    }

    /**
     * @notice Returns information on the given stake for the given address.
     *
     * @dev See getStakesLength.
     *
     * @param _user an address to query stake for
     * @param _stakeId zero-indexed stake ID for the address specified
     * @return stake info as Stake structure
     */
    function getStake(address _user, uint256 _stakeId) external view returns (Stake.Data memory) {
        // read stake at specified index and return
        return users[_user].stakes[_stakeId];
    }
}
