// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {IPikaMoon} from "./interfaces/IPikaMoon.sol";
import {Stake} from "./libraries/Stake.sol";
import {CommonErrors} from "./libraries/Errors.sol";
import {ICorePool} from "./interfaces/ICorePool.sol";
import {IPoolController} from "./interfaces/IPoolController.sol";

// import "hardhat/console.sol";

contract CorePool is OwnableUpgradeable, PausableUpgradeable, ICorePool {
    using Stake for Stake.Data;
    using Stake for uint256;
    using SafeERC20 for IPikaMoon;

    /// @dev Data structure representing token holder.
    struct User {
        /// @dev pending rewards rewards to be claimed
        uint256 pendingRewards;
        /// @dev Total weight
        uint256 userTotalWeight;
        /// @dev Checkpoint variable for rewards calculation
        uint256 rewardsPerWeightPaid;
        /// @dev An array of holder's stakes
        Stake.Data[] stakes;
    }

    /// @dev Used to calculate rewards.
    /// @dev Note: stakes are different in duration and "weight" reflects that.
    /// @dev updates in the _sync function
    uint256 public rewardsPerWeight;

    /// @dev Timestamp of the last rewards distribution event.
    uint256 public lastRewardsDistribution;

    /// @dev Link to the pool token instance, for example PIKA or PIKA/USDT pair LP token.
    address public poolToken;
    /// @dev Link to the reward token instance, for example PIKA
    address public rewardToken;
    /// @dev Link to the pool controller IPoolController instance.
    address public poolController;
    /// @dev verifier Address for ECDSA claim verification.
    address public verifierAddress;

    /**  @notice you can lock your tokens for a period between 1 and 12 months.
     * This changes your token weight. By increasing the duration of your lock,
     * you will increase the token weight of the locked tokens.
     * The maximum weight of a locked token is 2 ,
     * which occurs when you lock for a period of 12 months.
     * @dev Pool weight, initial values are 200 for PIKA pool and 800 for PIKA/USDT.
     */
    uint256 public weight;

    /// @dev Used to calculate rewards, keeps track of the tokens weight locked in staking.
    uint256 public globalStakeWeight;

    /// @dev total pool token reserve. PIKA or PIKA/USDT pair LP token.
    uint256 public totalTokenStaked;
    /// @dev upper Bound percentage for early unstake penalty.
    uint256 public upperBoundSlash;
    /// @dev lower Bound percentage for early unstake penalty.
    uint256 public lowerBoundSlash;

    uint256 private multiplier; // 1000 = 100%

    /// @dev Token holder storage, maps token holder address to their data record.
    mapping(address => User) public users;

    /// @dev mapping to prevent signature replay
    mapping(bytes32 => bool) public signatureUsed;

    function __CorePool_init(
        address _poolToken,
        address _rewardToken,
        address _poolController,
        uint256 _weight
    ) internal onlyInitializing {
        if (_poolToken == address(0)) {
            revert CommonErrors.ZeroAddress();
        }
        if (_rewardToken == address(0)) {
            revert CommonErrors.ZeroAddress();
        }

        if (_poolController == address(0)) {
            revert CommonErrors.ZeroAddress();
        }

        verifierAddress = owner();

        //PIKA or PIKA/USDT pair LP token address.
        poolToken = _poolToken;
        //PIKA token address.
        rewardToken = _rewardToken;
        /// pool controller IPoolController instance.
        poolController = _poolController;

        // init the dependent state variables
        lastRewardsDistribution = block.timestamp;
        // direct staking weight 200 and lp staking 800
        weight = _weight;

        upperBoundSlash = 900; // 90%
        lowerBoundSlash = 100; // 10%
        multiplier = 1000; // 100%
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
        uint256 lockUntil = block.timestamp + _lockDuration;

        // calculate stake weight. same as weight function in stake.sol library
        uint256 stakeWeight = (((lockUntil - block.timestamp) *
            Stake.WEIGHT_MULTIPLIER) /
            Stake.MAX_STAKE_PERIOD +
            Stake.BASE_WEIGHT) * _value;
        // makes sure stakeWeight is valid
        assert(stakeWeight > 0);

        // create and save the stake (append it to stakes array)
        Stake.Data memory userStake = Stake.Data({
            value: _value,
            lockedFrom: block.timestamp,
            lockedUntil: lockUntil
        });

        // pushes new stake to `stakes` array
        user.stakes.push(userStake);

        // update user weight
        user.userTotalWeight += stakeWeight;

        // update global weight value
        globalStakeWeight += stakeWeight;

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
     *      state if user tries to early unstake he is slashed according to percentage of time calculations
     *      restricted by upper and lower bound
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

        uint256 stakeValue = userStake.value;

        if(userStake.value == 0){
            revert CommonErrors.ZeroAmount();
        }

        // store stake weight
        uint256 previousWeight = userStake.weight();

        // update user record
        user.userTotalWeight = user.userTotalWeight - previousWeight;

        // update global weight variable
        globalStakeWeight = globalStakeWeight - previousWeight;

        // update global pool token count
        totalTokenStaked -= stakeValue;

        // checks if stake is unlocked already
        if (block.timestamp < userStake.lockedUntil) {
            uint256 earlyUnstakePercentage = calculateEarlyUnstakePercentage(
                userStake.lockedFrom,
                block.timestamp,
                userStake.lockedUntil
            );

            uint256 unstakeValue = stakeValue -
                ((stakeValue * earlyUnstakePercentage) / multiplier);
            // transfer slash amount
            IPikaMoon(poolToken).safeTransfer(
                poolController,
                stakeValue - unstakeValue
            );
            // return user stake
            IPikaMoon(poolToken).safeTransfer(_msgSender(), unstakeValue);
            // emits an event
            emit LogUnstake(_msgSender(), _stakeId, unstakeValue, earlyUnstakePercentage,true);
        } else {
            // return user stake
            IPikaMoon(poolToken).safeTransfer(_msgSender(), stakeValue);

            // emits an event
            emit LogUnstake(_msgSender(), _stakeId, stakeValue, 0,false);
        }
        // deletes stake struct
        delete user.stakes[_stakeId];
    }

    /**
     * @notice Calculates the penalty percentage for early unstaking based on the remaining locked time
     * @dev This function returns a penalty percentage scaled by `multiplier`. The function applies bounds to the penalty, ensuring it does not fall below `lowerBoundSlash` or exceed `upperBoundSlash`.
     * @param lockedFrom The timestamp when the stake was locked
     * @param nowTime The current timestamp, representing the moment of the unstaking request
     * @param lockedUntil The timestamp until which the stake was meant to be locked
     * @return penaltyPercentage The penalty percentage for unstaking early, scaled by `multiplier`. If the stake period has ended, returns 0.
     */
    function calculateEarlyUnstakePercentage(
        uint256 lockedFrom,
        uint256 nowTime,
        uint256 lockedUntil
    ) public view returns (uint256) {
        if (nowTime <= lockedUntil) {
            uint256 percentageToSlash = (((lockedUntil - nowTime)) *
                multiplier) / (lockedUntil - lockedFrom);

            if (percentageToSlash < lowerBoundSlash) {
                return lowerBoundSlash;
            } else if (percentageToSlash > upperBoundSlash) {
                return upperBoundSlash;
            } else {
                return percentageToSlash;
            }
        } else {
            return 0;
        }
    }

    /**
     * @dev Prefixes a bytes32 hash with the string "\x19Ethereum Signed Message:\n32" and then hashes the result.
     * This is used to conform with the Ethereum signing standard (EIP-191).
     * @param hash The original hash that needs to be prefixed and rehashed.
     * @return The prefixed and rehashed bytes32 value.
     */
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    /**
     * @notice Claims a percentage of the accrued rewards for the caller
     * @dev This function handles the claim process by validating the signature and calculating the reward percentage
     * @param _claimPercentage The percentage of the pending rewards to claim, scaled by the MULTIPLIER
     * @param _signature Cryptographic signature to verify the authenticity of the claim
     * @param nonce A unique identifier to prevent replay attacks
     */
    function claimRewards(
        uint256 _claimPercentage,
        bool _restakeLeftOver,
        uint256 _lockDuration,
        bytes memory _signature,
        uint256 nonce
    ) external {
        // lock duration recommended to be of 1 year to mitigate protocol abuse
        // checks if the contract is in a paused state
        if (paused()) revert CommonErrors.ContractIsPaused();

        assert(_claimPercentage <= multiplier);

        bytes32 message = prefixed(
            keccak256(
                abi.encodePacked(
                    _msgSender(),
                    _claimPercentage,
                    _restakeLeftOver,
                    _lockDuration,
                    nonce
                )
            )
        );
        require(!signatureUsed[message]);
        signatureUsed[message] = true;

        if (ECDSA.recover(message, _signature) != verifierAddress) {
            revert CommonErrors.WrongHash();
        }

        // save gas by caching msg.sender
        address _staker = _msgSender();

        // update user state
        _updateReward(_staker);

        // get link to a user data structure, we will write into it later
        User storage user = users[_staker];

        // if pending rewards is zero revert
        if (user.pendingRewards == 0) return;

        if (_claimPercentage != 0) {
            uint256 toClaim = (user.pendingRewards * _claimPercentage) /
                multiplier;

            user.pendingRewards -= toClaim;
            // transfer pending rewards to staker

            IPoolController(poolController).transferRewardTokens(
                rewardToken,
                _staker,
                toClaim
            );
            // emits an event
            emit LogClaimRewards(_staker, toClaim);
        }
        if (_restakeLeftOver) {
            if (
                !(_lockDuration >= Stake.MIN_STAKE_PERIOD &&
                    _lockDuration <= Stake.MAX_STAKE_PERIOD)
            ) {
                revert CommonErrors.InvalidLockDuration();
            }

            // calculates until when a stake is going to be locked
            uint256 lockUntil = block.timestamp + _lockDuration;

            // calculate stake weight. same as weight function in stake.sol library
            uint256 stakeWeight = (((lockUntil - block.timestamp) *
                Stake.WEIGHT_MULTIPLIER) /
                Stake.MAX_STAKE_PERIOD +
                Stake.BASE_WEIGHT) * user.pendingRewards;
            // makes sure stakeWeight is valid
            assert(stakeWeight > 0);

            // create and save the stake (append it to stakes array)
            Stake.Data memory userStake = Stake.Data({
                value: user.pendingRewards,
                lockedFrom: block.timestamp,
                lockedUntil: lockUntil
            });

            // pushes new stake to `stakes` array
            user.stakes.push(userStake);

            // update user weight
            user.userTotalWeight += stakeWeight;

            // update global weight value
            globalStakeWeight += stakeWeight;

            // update pool reserve
            totalTokenStaked += user.pendingRewards;

            IPoolController(poolController).transferRewardTokens(
                rewardToken,
                address(this),
                user.pendingRewards
            );

            // emits an event
            emit LogStake(
                _msgSender(),
                (user.stakes.length - 1),
                user.pendingRewards,
                lockUntil
            );
            user.pendingRewards = 0;
        }
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
        uint256 userWeight = user.userTotalWeight;

        // if smart contract state was not updated recently, `rewardsPerWeight` value
        // is outdated and we need to recalculate it in order to calculate pending rewards correctly
        if (block.timestamp > _lastRewardsDistribution && globalStakeWeight != 0) {
            IPoolController _controller = IPoolController(poolController);
            uint256 secondsPassed = block.timestamp - _lastRewardsDistribution;

            uint256 pikaRewards = (secondsPassed *
                _controller.pikaPerSecond() *
                weight) / _controller.totalWeight();

            // recalculated value for `rewardsPerWeight`
            newrewardsPerWeight =
                pikaRewards.getRewardPerWeight((globalStakeWeight)) +
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
     * @dev Must be called every time user.userTotalWeight is changed.
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
        uint256 userTotalWeight = user.userTotalWeight;

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
        emit LogUpdateRewards(_staker, _rewards);
    }

    /**
     *
     * @dev Updates smart contract state (`rewardsPerWeight`, `lastRewardsDistribution`),
     *      updates state via `updatePIKAPerSecond`
     */
    function _sync() internal {
        IPoolController _poolController = IPoolController(poolController);

        if (block.timestamp <= lastRewardsDistribution) {
            return;
        }
        // if globalStakeWeight is zero - update only `lastRewardsDistribution` and exit
        if (globalStakeWeight == 0) {
            lastRewardsDistribution = block.timestamp;
            return;
        }

        // to calculate the reward we need to know how many seconds passed, and reward per second
        uint256 currentTimestamp = block.timestamp;
        uint256 secondsPassed = currentTimestamp - lastRewardsDistribution;

        // calculate the reward
        uint256 pikaReward = (secondsPassed *
            _poolController.pikaPerSecond() *
            weight) / _poolController.totalWeight();

        // update rewards per weight and `lastRewardsDistribution`
        rewardsPerWeight += pikaReward.getRewardPerWeight(globalStakeWeight);
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
     * @dev When timing conditions are not met (executed too frequently, or after pool Controller
     *      end time), function doesn't throw and exits silently.
     */
    function sync() external {
        // checks if the contract is in a paused state
        if (paused()) revert CommonErrors.ContractIsPaused();
        // calls internal function
        _sync();
    }

    /**
     * @dev Executed by the pool Controller to modify pool weight; the pool Controller is expected
     *      to keep track of the total pools weight when updating.
     *
     * @dev Set weight to zero to disable the pool.
     *
     * @param _weight new weight to set for the pool
     */
    function setWeight(uint256 _weight) external {
        if (_msgSender() != poolController) {
            revert CommonErrors.OnlyFactory();
        }
        // update pool state using current weight value
        _sync();

        // set the new weight value
        weight = _weight;
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

    /**
     * @dev set verification address for ECDSA claim verification.
     * @param _verifierAddress verifier Address 
     */
    function setVerifierAddress(address _verifierAddress) external onlyOwner {
        verifierAddress = _verifierAddress;
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
        for (uint256 i; i < len; i++) {
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
    function getStake(
        address _user,
        uint256 _stakeId
    ) external view returns (Stake.Data memory) {
        // read stake at specified index and return
        return users[_user].stakes[_stakeId];
    }


    /**
     * @dev Get paginated stake information for a specific user
     *
     * This function allows querying stake information for a specific user in a paginated manner.
     * Users can specify a start index and a count to retrieve a subset of the user's stakes.
     *
     * @param _user The address of the user to query stake information for
     * @param startIndex The start index of the paginated results (zero-indexed)
     * @param count The number of stake entries to retrieve
     *
     * @return result An array of Stake.Data structures containing paginated stake information
     */
    function getPaginatedStake(
        address _user,
        uint startIndex,
        uint count
    ) external view returns (Stake.Data[] memory result) {
        Stake.Data[] memory data = users[_user].stakes;
        uint len = data.length;
        // Ensure that we are not starting the pagination out of the bounds of the array
        if (startIndex >= len) return result;

        // Calculate the actual number of items we can return
        uint length = count;
        if (startIndex + count > len) {
            length = len - startIndex;
        }

        // Allocate memory for the result array
        result = new Stake.Data[](length);

        // Populate the result array with the relevant data
        for (uint i = 0; i < length; ) {
            result[i] = data[startIndex + i];
            unchecked {
                ++i;
            }
        }

        return result;
    }

    /**
     * @dev Empty reserved space in storage. The size of the __gap array is calculated so that
     *      the amount of storage used by a contract always adds up to the 50.
     *      See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[40] private __gap;
}
