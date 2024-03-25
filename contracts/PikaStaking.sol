// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IPikaMoon} from "./interfaces/IPikaMoon.sol";
import {Stake} from "./libraries/Stake.sol";
import {CommonErrors} from "./libraries/Errors.sol";
import {IPikaStaking} from "./interfaces/IPikaStaking.sol";
// import "hardhat/console.sol";

contract PikaStaking is Ownable, Pausable, IPikaStaking {
    using Stake for Stake.Data;
    using Stake for uint256;
    using SafeERC20 for IPikaMoon;

    /// @dev Data structure representing token holder.
    struct User {
        /// @dev pending rewards rewards to be claimed
        uint256 pendingRewards;
        /// @dev Total weight
        uint256 totalWeight;
        /// @dev Checkpoint variable for rewards calculation
        uint256 rewardsPerWeightPaid;
        /// @dev An array of holder's stakes
        Stake.Data[] stakes;
    }

    /// @dev Used to calculate rewards rewards.
    /// @dev Note: stakes are different in duration and "weight" reflects that.
    /// @dev updates in the _sync function
    uint256 public rewardsPerWeight;

    /**
     * @dev The rewards is distributed proportionally to pool weights;
     *      total weight is here to help in determining the proportion.
     */
    uint256 public totalWeight;

    /// @dev Timestamp of the last rewards distribution event.
    uint256 public lastRewardsDistribution;

    /// @dev Link to the pool token instance, for example PIKA or PIKA/ETH pair LP token.
    address public poolToken;


    /// @dev staking Reward Allocation Pool address 
    address public stakingRewardAddress;

    /**  @notice you can lock your tokens for a period between 1 and 12 months.
     * This changes your token weight. By increasing the duration of your lock,
     * you will increase the token weight of the locked tokens.
     * The maximum weight of a locked token is 2 ,
     * which occurs when you lock for a period of 12 months.
     * @dev Pool weight, initial values are 200 for PIKA pool and 800 for PIKA/ETH.
     */
    uint256 public weight;
    /// @dev Used to calculate rewards, keeps track of the tokens weight locked in staking.
    uint256 public globalWeight;
    /// @dev total pool token reserve. PIKA or PIKA/ETH pair LP token.
    uint256 public totalTokenStaked;

    /**
     * @dev PIKA/second determines rewards farming reward base
     */
    uint256 public pikaPerSecond;

    /**
     * @dev PIKA/second decreases by 3% every seconds/update
     *      an update is triggered by executing `updatePIKAPerSecond` public function.
     */
    uint256 public secondsPerUpdate;

    /**
     * @dev End time is the last timestamp when PIKA/second can be decreased;
     *      it is implied that rewards farming stops after that timestamp.
     */
    uint256 public endTime;

    /**
     * @dev Each time the PIKA/second ratio gets updated, the timestamp
     *      when the operation has occurred gets recorded into `lastRatioUpdate`.
     * @dev This timestamp is then used to check if seconds/update `secondsPerUpdate`
     *      has passed when decreasing rewards reward by 3%.
     */
    uint256 public lastRatioUpdate;

    /// @dev Token holder storage, maps token holder address to their data record.
    mapping(address => User) public users;

    constructor(address _poolToken, uint256 _weight,address _stakingRewardAddress) Ownable(_msgSender()) {
        if (_poolToken == address(0)) {
            revert CommonErrors.ZeroAddress();
        }
        //PIKA or PIKA/ETH pair LP token address.
        poolToken = _poolToken;
        // init the dependent state variables
        lastRewardsDistribution = _now256();
        weight = _weight; //(direct staking)200
        pikaPerSecond = 0.0099665 gwei;
        secondsPerUpdate = 14 days;
        lastRatioUpdate = _now256();
        endTime = _now256() + (5 * 30 days); // 5 months
        totalWeight = 1000; //(direct staking)200 + (pool staking)800
        stakingRewardAddress = _stakingRewardAddress;
    }

    /**
     * @notice Stakes specified value of tokens for the specified value of time,
     *      and pays pending rewards rewards if any.
     *
     * @dev Requires value to stake and lock duration to be greater than zero.
     *
     * @param _value value of tokens to stake
     * @param _lockDuration stake duration as unix timestamp
     */

    function stake(uint256 _value, uint256 _lockDuration) external {
        // checks if the contract is in a paused state
        if (paused()) revert CommonErrors.ContractIsPaused();

        // validate the _value
        if (_value == 0) revert CommonErrors.ZeroAmount();

        // validate the _lockDuration
        if (
            !(_lockDuration >= Stake.MIN_STAKE_PERIOD &&
                _lockDuration <= Stake.MAX_STAKE_PERIOD)
        ) {
            revert CommonErrors.InvalidLockDuration();
        }

        // get a link to user data struct, we will write to it later
        User storage user = users[_msgSender()];
        
        // update user state
        _updateReward(_msgSender());
        
        // calculates until when a stake is going to be locked
        uint256 lockUntil = _now256() + _lockDuration;
        
        // calculate stake weight. same as weight function in stake.sol library
        uint256 stakeWeight = (((lockUntil - _now256()) *
            Stake.WEIGHT_MULTIPLIER) /
            Stake.MAX_STAKE_PERIOD +
            Stake.BASE_WEIGHT) * _value;
        // makes sure stakeWeight is valid
        assert(stakeWeight > 0);

        // create and save the stake (append it to stakes array)
        Stake.Data memory userStake = Stake.Data({
            value: _value,
            lockedFrom: _now256(),
            lockedUntil: lockUntil
        });
        
        // pushes new stake to `stakes` array
        user.stakes.push(userStake);
        
        // update user weight
        user.totalWeight += (stakeWeight);
        
        // update global weight value
        globalWeight += stakeWeight;
        
        // update pool reserve
        totalTokenStaked += _value;

        // transfer `_value` to this contract
        IPikaMoon(poolToken).safeTransferFrom(
            _msgSender(),
            address(this),
            _value
        );

        // emits an event
        emit LogStake(
            _msgSender(),
            (user.stakes.length - 1),
            _value,
            lockUntil
        );
    }

    /**
     * @dev Unstakes a stake that has been previously locked, and is now in an unlocked
     *      state.
     *
     * @param _stakeId stake ID to unstake from, zero-indexed
     */
    function unstake(uint256 _stakeId) external {
        // checks if the contract is in a paused state
        if (paused()) revert CommonErrors.ContractIsPaused();

        // get a link to user data struct, we will write to it later
        User storage user = users[_msgSender()];

        // update user state
        _updateReward(_msgSender());
        
        // get a link to the corresponding stake, we may write to it later
        Stake.Data storage userStake = user.stakes[_stakeId];
        
        // checks if stake is unlocked already
        if (!(_now256() > userStake.lockedUntil))
            revert CommonErrors.StakingTimeNotFinishedYet();

         // save gas by caching userStake.value
        uint256 stakeValue = userStake.value;

        // store stake weight
        uint256 previousWeight = userStake.weight();

        // deletes stake struct
        delete user.stakes[_stakeId];

        // update user record
        user.totalWeight = user.totalWeight - previousWeight;
        
        // update global weight variable
        globalWeight = globalWeight - previousWeight;
        
        // update global pool token count
        totalTokenStaked -= stakeValue;

        // return user stake
        IPikaMoon(poolToken).safeTransfer(_msgSender(), stakeValue);

        // emits an event
        emit LogUnstake(_msgSender(), _stakeId, stakeValue);
    }

    /**
     * @dev claims all pending staking rewards.
     */
    function claimRewards() external {
        // checks if the contract is in a paused state
        if (paused()) revert CommonErrors.ContractIsPaused();

        // save gas by caching msg.sender
        address _staker = _msgSender();
        
        // update user state
        _updateReward(_staker);

        // get link to a user data structure, we will write into it later
        User storage user = users[_staker];

        // check pending rewards rewards to claim and save to memory
        uint256 pendingRewardsToClaim = user.pendingRewards;
        
        // if pending rewards is zero - just return silently
        if (pendingRewardsToClaim == 0) return;
        
        // clears user pending rewards
        user.pendingRewards = 0;

        // transfer pending rewards to staker
        IPikaMoon(poolToken).safeTransferFrom(stakingRewardAddress,_staker, pendingRewardsToClaim);

        // emits an event
        emit LogClaimRewards(_staker, pendingRewardsToClaim);
    }

    /**
     * @notice Calculates current rewards rewards value available for address specified.
     * @param _staker an address to calculate rewards rewards value for
     */
    function pendingRewards(
        address _staker
    ) external view returns (uint256 _pendingRewards) {
        if (_staker == address(0)) revert CommonErrors.ZeroAddress();
        // `newrewardsPerWeight` will be the stored or recalculated value for `rewardsPerWeight`
        uint256 newrewardsPerWeight;
        // gas savings
        uint256 _lastRewardsDistribution = lastRewardsDistribution;

        // based on the rewards per weight value, calculate pending rewards;
        User memory user = users[_staker];
        // initializes both variables from one storage slot
        uint256 userWeight = user.totalWeight;

        // if smart contract state was not updated recently, `rewardsPerWeight` value
        // is outdated and we need to recalculate it in order to calculate pending rewards correctly
        if (_now256() > _lastRewardsDistribution && globalWeight != 0) {
            uint256 multiplier = _now256() > endTime
                ? endTime - _lastRewardsDistribution
                : _now256() - _lastRewardsDistribution;
            uint256 pikaRewards = (multiplier * pikaPerSecond * weight) /
                totalWeight;

            // recalculated value for `rewardsPerWeight`
            newrewardsPerWeight =
                pikaRewards.getRewardPerWeight((globalWeight)) +
                rewardsPerWeight;
        } else {
            // if smart contract state is up to date, we don't recalculate
            newrewardsPerWeight = rewardsPerWeight;
        }

        _pendingRewards =
            (userWeight).earned(
                newrewardsPerWeight,
                user.rewardsPerWeightPaid
            ) +
            user.pendingRewards;
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

        // calculates pending rewards to be added
        uint256 _rewards = userTotalWeight.earned(
            rewardsPerWeight,
            user.rewardsPerWeightPaid
        );
        // calculates pending reenue distribution to be added
        // increases stored user.rewards with value returned
        user.pendingRewards += _rewards;

        // updates user checkpoint values for future calculations
        user.rewardsPerWeightPaid = rewardsPerWeight;

        // emits an event
        emit LogUpdateRewards(_msgSender(), _staker, _rewards);
    }

    /**
     *
     * @dev Updates smart contract state (`rewardsPerWeight`, `lastRewardsDistribution`),
     *      updates state via `updatePIKAPerSecond`
     */
    function _sync() internal {
        // update PIKA per second value
        if (shouldUpdateRatio()) {
            updatePIKAPerSecond();
        }

        // check bound conditions and if these are not met -
        // exit silently, without emitting an event
        if (lastRewardsDistribution >= endTime) {
            return;
        }
        if (_now256() <= lastRewardsDistribution) {
            return;
        }
        // if locking weight is zero - update only `lastRewardsDistribution` and exit
        if (globalWeight == 0) {
            lastRewardsDistribution = _now256();
            return;
        }

        // to calculate the reward we need to know how many seconds passed, and reward per second
        uint256 currentTimestamp = _now256() > endTime ? endTime : _now256();
        uint256 secondsPassed = currentTimestamp - lastRewardsDistribution;

        // calculate the reward
        uint256 pikaReward = (secondsPassed * pikaPerSecond * weight) /
            totalWeight;

        // update rewards per weight and `lastRewardsDistribution`
        rewardsPerWeight += pikaReward.getRewardPerWeight(globalWeight);
        lastRewardsDistribution = currentTimestamp;

        // emits an event
        emit LogSync(_msgSender(), rewardsPerWeight, lastRewardsDistribution);
    }

    /**
     * @notice Service function to synchronize pool state with current time.
     *
     * @dev Can be executed by anyone at any time, but has an effect only when
     *      at least one second passes between synchronizations.
     * @dev Executed internally when staking, unstaking, processing rewards in order
     *      for calculations to be correct and to reflect state progress of the contract.
     * @dev When timing conditions are not met (executed too frequently, or after factory
     *      end time), function doesn't throw and exits silently.
     */
    function sync() external {
        // checks if the contract is in a paused state
        if (paused()) revert CommonErrors.ContractIsPaused();
        // calls internal function
        _sync();
    }
    
    /**
     * @dev Verifies if `secondsPerUpdate` has passed since last PIKA/second
     *      ratio update and if PIKA/second reward can be decreased by 3%.
     *
     * @return true if enough time has passed and `updatePIKAPerSecond` can be executed.
     */
    function shouldUpdateRatio() public view returns (bool) {
        // if rewards farming period has ended
        if (_now256() > endTime) {
            // PIKA/second reward cannot be updated anymore
            return false;
        }

        // check if seconds/update have passed since last update
        return _now256() >= lastRatioUpdate + secondsPerUpdate;
    }

    /**
     * @notice Decreases PIKA/second reward by 3%, can be executed
     *      no more than once per `secondsPerUpdate` seconds.
     */
    function updatePIKAPerSecond() public {
        // checks if ratio can be updated i.e. if seconds/update have passed
        if (!shouldUpdateRatio()) revert CommonErrors.CanNotUpdateAtTheMoment();

        // decreases PIKA/second reward by 3%.
        // To achieve that we multiply by 97 and then
        // divide by 100
        pikaPerSecond = (pikaPerSecond * 97) / 100;

        // set current timestamp as the last ratio update timestamp
        lastRatioUpdate = _now256();

        // emits an event
        emit LogUpdatePikaPerSecond(_msgSender(), pikaPerSecond);
    }

    /**
     * @dev Updates rewards generation ending timestamp.
     *
     * @param _endTime new end time value to be stored
     */
    function setEndTime(uint256 _endTime) external onlyOwner {
        // checks if _endTime is a timestap after the last time that
        // PIKA/second has been updated
        if (!(_endTime > lastRatioUpdate)) {
            revert CommonErrors.WrongEndTime();
        }
        // updates endTime state var
        endTime = _endTime;

        // emits an event
        emit LogSetEndTime(_msgSender(), _endTime);
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
        emit LogChangePoolWeight(_msgSender(), address(this), weight);
    }

    /**
     * @dev Set paused/unpaused state in the staking contract.
     * @param _shouldPause whether the contract should be paused/unpausd
     */
    function pause(bool _shouldPause) external onlyOwner {
        if (_shouldPause) {
            _pause();
        } else {
            _unpause();
        }
    }

    function _now256() internal view returns (uint256) {
        // return current block timestamp
        return block.timestamp;
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
        // calculate length
        uint256 len = user.stakes.length;
        // loops over each user stake and adds to the total balance.
        for (uint256 i; i < len; ) {
            balance += user.stakes[i].value;
            unchecked {
                i = i + 1;
            }
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
    function getStake(
        address _user,
        uint256 _stakeId
    ) external view returns (Stake.Data memory) {
        // read stake at specified index and return
        return users[_user].stakes[_stakeId];
    }
}
