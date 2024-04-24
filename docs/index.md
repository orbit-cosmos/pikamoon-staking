# Solidity API

## CorePool

### User

_Data structure representing token holder._

```solidity
struct User {
  uint256 pendingRewards;
  uint256 userTotalWeight;
  uint256 rewardsPerWeightPaid;
  struct Stake.Data[] stakes;
}
```

### rewardsPerWeight

```solidity
uint256 rewardsPerWeight
```

_Used to calculate rewards.
Note: stakes are different in duration and "weight" reflects that.
updates in the _sync function_

### lastRewardsDistribution

```solidity
uint256 lastRewardsDistribution
```

_Timestamp of the last rewards distribution event._

### poolToken

```solidity
address poolToken
```

_Link to the pool token instance, for example PIKA or PIKA/USDT pair LP token._

### rewardToken

```solidity
address rewardToken
```

_Link to the reward token instance, for example PIKA_

### poolController

```solidity
address poolController
```

_Link to the pool controller IPoolController instance._

### weight

```solidity
uint256 weight
```

you can lock your tokens for a period between 1 and 12 months.
This changes your token weight. By increasing the duration of your lock,
you will increase the token weight of the locked tokens.
The maximum weight of a locked token is 2 ,
which occurs when you lock for a period of 12 months.

_Pool weight, initial values are 200 for PIKA pool and 800 for PIKA/USDT._

### globalStakeWeight

```solidity
uint256 globalStakeWeight
```

_Used to calculate rewards, keeps track of the tokens weight locked in staking._

### totalTokenStaked

```solidity
uint256 totalTokenStaked
```

_total pool token reserve. PIKA or PIKA/USDT pair LP token._

### upperBoundSlash

```solidity
uint256 upperBoundSlash
```

_upper Bound percentage for early unstake penalty._

### lowerBoundSlash

```solidity
uint256 lowerBoundSlash
```

_lower Bound percentage for early unstake penalty._

### users

```solidity
mapping(address => struct CorePool.User) users
```

_Token holder storage, maps token holder address to their data record._

### signatureUsed

```solidity
mapping(bytes32 => bool) signatureUsed
```

_mapping to prevent signature replay_

### __CorePool_init

```solidity
function __CorePool_init(address _poolToken, address _rewardToken, address _poolController, uint256 _weight) internal
```

### stake

```solidity
function stake(uint256 _value, uint256 _lockDuration) external
```

Stakes specified value of tokens for the specified value of time,
     and pays pending rewards rewards if any.

_Requires value to stake and lock duration to be greater than zero._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _value | uint256 | value of tokens to stake |
| _lockDuration | uint256 | stake duration as unix timestamp |

### unstake

```solidity
function unstake(uint256 _stakeId) external
```

_Unstakes a stake that has been previously locked, and is now in an unlocked
     state if user tries to early unstake he is slashed according to percentage of time calculations
     restricted by upper and lower bound_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _stakeId | uint256 | stake ID to unstake from, zero-indexed |

### calculateEarlyUnstakePercentage

```solidity
function calculateEarlyUnstakePercentage(uint256 lockedFrom, uint256 nowTime, uint256 lockedUntil) public view returns (uint256)
```

Calculates the penalty percentage for early unstaking based on the remaining locked time

_This function returns a penalty percentage scaled by `multiplier`. The function applies bounds to the penalty, ensuring it does not fall below `lowerBoundSlash` or exceed `upperBoundSlash`._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| lockedFrom | uint256 | The timestamp when the stake was locked |
| nowTime | uint256 | The current timestamp, representing the moment of the unstaking request |
| lockedUntil | uint256 | The timestamp until which the stake was meant to be locked |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | penaltyPercentage The penalty percentage for unstaking early, scaled by `multiplier`. If the stake period has ended, returns 0. |

### prefixed

```solidity
function prefixed(bytes32 hash) internal pure returns (bytes32)
```

_Prefixes a bytes32 hash with the string "\x19Ethereum Signed Message:\n32" and then hashes the result.
This is used to conform with the Ethereum signing standard (EIP-191)._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| hash | bytes32 | The original hash that needs to be prefixed and rehashed. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | The prefixed and rehashed bytes32 value. |

### claimRewards

```solidity
function claimRewards(uint256 _claimPercentage, bool _restakeLeftOver, uint256 _lockDuration, bytes _signature, uint256 nonce) external
```

Claims a percentage of the accrued rewards for the caller

_This function handles the claim process by validating the signature and calculating the reward percentage_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _claimPercentage | uint256 | The percentage of the pending rewards to claim, scaled by the MULTIPLIER |
| _restakeLeftOver | bool |  |
| _lockDuration | uint256 |  |
| _signature | bytes | Cryptographic signature to verify the authenticity of the claim |
| nonce | uint256 | A unique identifier to prevent replay attacks |

### pendingRewards

```solidity
function pendingRewards(address _staker) external view returns (uint256 _pendingRewards)
```

Calculates current rewards rewards value available for address specified.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _staker | address | an address to calculate rewards rewards value for |

### _updateReward

```solidity
function _updateReward(address _staker) internal
```

_Must be called every time user.userTotalWeight is changed.
Syncs the global pool state, processes the user pending rewards (if any),
     and updates check points values stored in the user struct.
If user is coming from v1 pool, it expects to receive this v1 user weight
     to include in rewards calculations._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _staker | address | user address |

### _sync

```solidity
function _sync() internal
```

_Updates smart contract state (`rewardsPerWeight`, `lastRewardsDistribution`),
     updates state via `updatePIKAPerSecond`_

### sync

```solidity
function sync() external
```

Service function to synchronize pool state with current time.

_Can be executed by anyone at any time, but has an effect only when
     at least one second passes between synchronizations.
Executed internally when staking, unstaking, processing rewards in order
     for calculations to be correct and to reflect state progress of the contract.
When timing conditions are not met (executed too frequently, or after pool Controller
     end time), function doesn't throw and exits silently._

### setWeight

```solidity
function setWeight(uint256 _weight) external
```

_Executed by the pool Controller to modify pool weight; the pool Controller is expected
     to keep track of the total pools weight when updating.

Set weight to zero to disable the pool._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _weight | uint256 | new weight to set for the pool |

### pause

```solidity
function pause(bool _shouldPause) external
```

_Set paused/unpaused state in the staking contract._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _shouldPause | bool | whether the contract should be paused/unpausd |

### balanceOf

```solidity
function balanceOf(address _user) external view returns (uint256 balance)
```

Returns total staked token balance for the given address.
Expected to be called externally through `eth_call`. Gas shouldn't
        be an issue here.

_Loops through stakes and returns total balance._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _user | address | an address to query balance for |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| balance | uint256 | total staked token balance |

### getStakesLength

```solidity
function getStakesLength(address _user) external view returns (uint256)
```

Returns number of stakes for the given address. Allows iteration over stakes.

_See `getStake()`._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _user | address | an address to query stake length for |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | number of stakes for the given address |

### getStake

```solidity
function getStake(address _user, uint256 _stakeId) external view returns (struct Stake.Data)
```

Returns information on the given stake for the given address.

_See getStakesLength._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _user | address | an address to query stake for |
| _stakeId | uint256 | zero-indexed stake ID for the address specified |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct Stake.Data | stake info as Stake structure |

## PikaStakingPool

### constructor

```solidity
constructor() public
```

### initialize

```solidity
function initialize(address _poolToken, address _rewardToken, address _poolController, uint256 _weight) external
```

### _authorizeUpgrade

```solidity
function _authorizeUpgrade(address newImplementation) internal
```

_Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
{upgradeToAndCall}._

## PoolController

### pikaPerSecond

```solidity
uint256 pikaPerSecond
```

_PIKA/second determines rewards farming reward base_

### totalWeight

```solidity
uint256 totalWeight
```

_The yield is distributed proportionally to pool weights;
     total weight is here to help in determining the proportion._

### poolExists

```solidity
mapping(address => bool) poolExists
```

_Keeps track of registered pool addresses, maps pool address -> exists flag._

### LogChangePoolWeight

```solidity
event LogChangePoolWeight(address by, address poolAddress, uint256 weight)
```

_Fired in `changePoolWeight()`._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| by | address | an address which executed an action |
| poolAddress | address | deployed pool instance address |
| weight | uint256 | new pool weight |

### LogUpdatePikaPerSecond

```solidity
event LogUpdatePikaPerSecond(uint256 newPikaPerSecond)
```

_Fired in `updatePikaPerSecond()`._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newPikaPerSecond | uint256 | new Pika/second value |

### LogRegisterPool

```solidity
event LogRegisterPool(address addr)
```

_Fired in registerPool()_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| addr | address | an address of pool |

### constructor

```solidity
constructor() public
```

### initialize

```solidity
function initialize() external
```

### registerPool

```solidity
function registerPool(address _poolAddress) external
```

Registers a new pool

_Only callable by the owner; emits LogRegisterPool on success_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _poolAddress | address | The address of the pool to register |

### updatePikaPerSecond

```solidity
function updatePikaPerSecond(uint256 _pikaPerSecond) external
```

Updates the rate of PIKA distribution per second

_Only callable by the owner; emits LogUpdatePikaPerSecond on success_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _pikaPerSecond | uint256 | The new rate of PIKA distribution per second |

### transferRewardTokens

```solidity
function transferRewardTokens(address _token, address _to, uint256 _value) public
```

Transfers reward tokens from a registered pool

_Only callable by a registered pool_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _token | address | The token address to transfer |
| _to | address | The recipient address |
| _value | uint256 | The amount of tokens to transfer |

### changePoolWeight

```solidity
function changePoolWeight(address pool, uint256 weight) external
```

_Changes the weight of the pool;
     executed by the pool itself or by the factory owner._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address | address of the pool to change weight for |
| weight | uint256 | new weight value to set to |

### _authorizeUpgrade

```solidity
function _authorizeUpgrade(address newImplementation) internal
```

_Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
{upgradeToAndCall}._

## ICorePool

### stake

```solidity
function stake(uint256 _value, uint256 _lockDuration) external
```

### unstake

```solidity
function unstake(uint256 _stakeId) external
```

### claimRewards

```solidity
function claimRewards(uint256 _claimPercentage, bool _restakeLeftOver, uint256 _lockDuration, bytes _signature, uint256 _nonce) external
```

### sync

```solidity
function sync() external
```

### setWeight

```solidity
function setWeight(uint256 _weight) external
```

### pause

```solidity
function pause(bool _shouldPause) external
```

### pendingRewards

```solidity
function pendingRewards(address _staker) external view returns (uint256 pendingYield)
```

### balanceOf

```solidity
function balanceOf(address _user) external view returns (uint256 balance)
```

### getStakesLength

```solidity
function getStakesLength(address _user) external view returns (uint256)
```

### getStake

```solidity
function getStake(address _user, uint256 _stakeId) external view returns (struct Stake.Data)
```

### weight

```solidity
function weight() external view returns (uint256)
```

### LogStake

```solidity
event LogStake(address from, uint256 stakeId, uint256 value, uint256 lockUntil)
```

_Fired in _stake() and stakeAsPool() in PIKAPool contract._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| from | address | token holder address, the tokens will be returned to that address |
| stakeId | uint256 | id of the new stake created |
| value | uint256 | value of tokens staked |
| lockUntil | uint256 | timestamp indicating when tokens should unlock (max 2 years) |

### LogUpdateRewards

```solidity
event LogUpdateRewards(address from, uint256 yieldValue)
```

_Fired in `_updateRewards()`._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| from | address | an address which received the yield |
| yieldValue | uint256 | value of yield processed |

### LogUnstake

```solidity
event LogUnstake(address to, uint256 stakeId, uint256 value, uint256 earlyUnstakePercentage, bool isEarlyUnstake)
```

_Fired in `unstake()`._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | address receiving the tokens (user) |
| stakeId | uint256 | id value of the stake |
| value | uint256 | number of tokens unstaked |
| earlyUnstakePercentage | uint256 |  |
| isEarlyUnstake | bool |  |

### LogUpdatePikaPerSecond

```solidity
event LogUpdatePikaPerSecond(address by, uint256 newPIKAPerSecond)
```

_Fired in `updatePIKAPerSecond()`._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| by | address | an address which executed an action |
| newPIKAPerSecond | uint256 | new PIKA/second value |

### LogSync

```solidity
event LogSync(address by, uint256 yieldRewardsPerWeight, uint256 lastYieldDistribution)
```

_Fired in `_sync()` and dependent functions (stake, unstake, etc.)._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| by | address | an address which performed an operation |
| yieldRewardsPerWeight | uint256 | updated yield rewards per weight value |
| lastYieldDistribution | uint256 | usually, current timestamp |

### LogUpdatePIKAPerSecond

```solidity
event LogUpdatePIKAPerSecond(address by, uint256 newPikaPerSecond)
```

_Fired in `updatePIKAPerSecond()`._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| by | address | an address which executed an action |
| newPikaPerSecond | uint256 | new PIKA/second value |

### LogClaimRewards

```solidity
event LogClaimRewards(address from, uint256 value)
```

_Fired in `_claimYieldRewards()`._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| from | address | an address which received the yield |
| value | uint256 | value of yield paid |

### LogSetEndTime

```solidity
event LogSetEndTime(address by, uint256 endTime)
```

_Fired in `setEndTime()`._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| by | address | an address which executed the action |
| endTime | uint256 | new endTime value |

## IPikaMoon

### mint

```solidity
function mint(address to, uint256 amount) external
```

### burn

```solidity
function burn(address owner, uint256 amount) external
```

## IPoolController

### owner

```solidity
function owner() external view returns (address)
```

### pikaPerSecond

```solidity
function pikaPerSecond() external view returns (uint192)
```

### totalWeight

```solidity
function totalWeight() external view returns (uint32)
```

### transferRewardTokens

```solidity
function transferRewardTokens(address _token, address _to, uint256 _value) external
```

### changePoolWeight

```solidity
function changePoolWeight(address pool, uint32 weight) external
```

## CommonErrors

Pre-defined errors instead of string error messages to reduce gas costs.

_This smart contract defines custom errors that can be thrown during specific conditions in contracts._

### ZeroAmount

```solidity
error ZeroAmount()
```

### ZeroAddress

```solidity
error ZeroAddress()
```

### ContractIsPaused

```solidity
error ContractIsPaused()
```

### InvalidLockDuration

```solidity
error InvalidLockDuration()
```

### OnlyFactory

```solidity
error OnlyFactory()
```

### AlreadyRegistered

```solidity
error AlreadyRegistered()
```

### WrongHash

```solidity
error WrongHash()
```

## Stake

_Stake library used by PIKA pool and PIKA/USDT LP Pool.

Responsible to manage weight calculation and store important constants
     related to stake period, base weight and multipliers utilized._

### Data

```solidity
struct Data {
  uint256 value;
  uint256 lockedFrom;
  uint256 lockedUntil;
}
```

### WEIGHT_MULTIPLIER

```solidity
uint256 WEIGHT_MULTIPLIER
```

_Stake weight is proportional to stake value and time locked, precisely
     "stake value wei multiplied by (fraction of the year locked plus one)".
To avoid significant precision loss due to multiplication by "fraction of the year" [0, 1],
     weight is stored multiplied by 1e6 constant, as an integer.
Corner case 1: if time locked is zero, weight is stake value multiplied by 1e6 + base weight
Corner case 2: if time locked is two years, division of
            (lockedUntil - lockedFrom) / MAX_STAKE_PERIOD is 1e6, and
     weight is a stake value multiplied by 2 * 1e6._

### BASE_WEIGHT

```solidity
uint256 BASE_WEIGHT
```

_Minimum weight value, if result of multiplication using WEIGHT_MULTIPLIER
     is 0 (e.g stake flexible), then BASE_WEIGHT is used._

### MIN_STAKE_PERIOD

```solidity
uint256 MIN_STAKE_PERIOD
```

_Minimum period that someone can lock a stake for._

### MAX_STAKE_PERIOD

```solidity
uint256 MAX_STAKE_PERIOD
```

_Maximum period that someone can lock a stake for._

### REWARD_PER_WEIGHT_MULTIPLIER

```solidity
uint256 REWARD_PER_WEIGHT_MULTIPLIER
```

_Rewards per weight are stored multiplied by 1e20 as uint._

### weight

```solidity
function weight(struct Stake.Data _self) internal view returns (uint256)
```

### earned

```solidity
function earned(uint256 _weight, uint256 _rewardPerWeight, uint256 _rewardPerWeightPaid) internal pure returns (uint256)
```

_Converts stake weight (not to be mixed with the pool weight) to
     PIKA reward value, applying the 10^12 division on weight_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _weight | uint256 | stake weight |
| _rewardPerWeight | uint256 | PIKA reward per weight |
| _rewardPerWeightPaid | uint256 | last reward per weight value used for user earnings |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | reward value normalized to 10^12 |

### getRewardPerWeight

```solidity
function getRewardPerWeight(uint256 _reward, uint256 _globalWeight) internal pure returns (uint256)
```

_Converts reward PIKA value to stake weight (not to be mixed with the pool weight),
     applying the 10^12 multiplication on the reward.
     - OR -
Converts reward PIKA value to reward/weight if stake weight is supplied as second
     function parameter instead of reward/weight._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _reward | uint256 | yield reward |
| _globalWeight | uint256 | total weight in the pool |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | reward per weight value |

## CommanErrors

_This smart contract defines custom errors that can be thrown during specific conditions in contracts._

### ZeroAmount

```solidity
error ZeroAmount()
```

### ZeroAddress

```solidity
error ZeroAddress()
```

### WrongTax

```solidity
error WrongTax()
```

### PairIsAlreadyGivenValue

```solidity
error PairIsAlreadyGivenValue()
```

## StorageSlot

_Library for reading and writing primitive types to specific storage slots.

Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
This library helps with reading and writing to such slots without the need for inline assembly.

The functions in this library return Slot structs that contain a `value` member that can be used to read or write.

Example usage to set ERC1967 implementation slot:
```solidity
contract ERC1967 {
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    function _setImplementation(address newImplementation) internal {
        require(newImplementation.code.length > 0);
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }
}
```_

### AddressSlot

```solidity
struct AddressSlot {
  address value;
}
```

### BooleanSlot

```solidity
struct BooleanSlot {
  bool value;
}
```

### Bytes32Slot

```solidity
struct Bytes32Slot {
  bytes32 value;
}
```

### Uint256Slot

```solidity
struct Uint256Slot {
  uint256 value;
}
```

### StringSlot

```solidity
struct StringSlot {
  string value;
}
```

### BytesSlot

```solidity
struct BytesSlot {
  bytes value;
}
```

### getAddressSlot

```solidity
function getAddressSlot(bytes32 slot) internal pure returns (struct StorageSlot.AddressSlot r)
```

_Returns an `AddressSlot` with member `value` located at `slot`._

### getBooleanSlot

```solidity
function getBooleanSlot(bytes32 slot) internal pure returns (struct StorageSlot.BooleanSlot r)
```

_Returns an `BooleanSlot` with member `value` located at `slot`._

### getBytes32Slot

```solidity
function getBytes32Slot(bytes32 slot) internal pure returns (struct StorageSlot.Bytes32Slot r)
```

_Returns an `Bytes32Slot` with member `value` located at `slot`._

### getUint256Slot

```solidity
function getUint256Slot(bytes32 slot) internal pure returns (struct StorageSlot.Uint256Slot r)
```

_Returns an `Uint256Slot` with member `value` located at `slot`._

### getStringSlot

```solidity
function getStringSlot(bytes32 slot) internal pure returns (struct StorageSlot.StringSlot r)
```

_Returns an `StringSlot` with member `value` located at `slot`._

### getStringSlot

```solidity
function getStringSlot(string store) internal pure returns (struct StorageSlot.StringSlot r)
```

_Returns an `StringSlot` representation of the string storage pointer `store`._

### getBytesSlot

```solidity
function getBytesSlot(bytes32 slot) internal pure returns (struct StorageSlot.BytesSlot r)
```

_Returns an `BytesSlot` with member `value` located at `slot`._

### getBytesSlot

```solidity
function getBytesSlot(bytes store) internal pure returns (struct StorageSlot.BytesSlot r)
```

_Returns an `BytesSlot` representation of the bytes storage pointer `store`._

## Address

_Collection of functions related to the address type_

### AddressInsufficientBalance

```solidity
error AddressInsufficientBalance(address account)
```

_The ETH balance of the account is not enough to perform the operation._

### AddressEmptyCode

```solidity
error AddressEmptyCode(address target)
```

_There's no code at `target` (it is not a contract)._

### FailedInnerCall

```solidity
error FailedInnerCall()
```

_A call to an address target failed. The target may have reverted._

### sendValue

```solidity
function sendValue(address payable recipient, uint256 amount) internal
```

_Replacement for Solidity's `transfer`: sends `amount` wei to
`recipient`, forwarding all available gas and reverting on errors.

https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
of certain opcodes, possibly making contracts go over the 2300 gas limit
imposed by `transfer`, making them unable to receive funds via
`transfer`. {sendValue} removes this limitation.

https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].

IMPORTANT: because control is transferred to `recipient`, care must be
taken to not create reentrancy vulnerabilities. Consider using
{ReentrancyGuard} or the
https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern]._

### functionCall

```solidity
function functionCall(address target, bytes data) internal returns (bytes)
```

_Performs a Solidity function call using a low level `call`. A
plain `call` is an unsafe replacement for a function call: use this
function instead.

If `target` reverts with a revert reason or custom error, it is bubbled
up by this function (like regular Solidity function calls). However, if
the call reverted with no returned reason, this function reverts with a
{FailedInnerCall} error.

Returns the raw returned data. To convert to the expected return value,
use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].

Requirements:

- `target` must be a contract.
- calling `target` with `data` must not revert._

### functionCallWithValue

```solidity
function functionCallWithValue(address target, bytes data, uint256 value) internal returns (bytes)
```

_Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
but also transferring `value` wei to `target`.

Requirements:

- the calling contract must have an ETH balance of at least `value`.
- the called Solidity function must be `payable`._

### functionStaticCall

```solidity
function functionStaticCall(address target, bytes data) internal view returns (bytes)
```

_Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
but performing a static call._

### functionDelegateCall

```solidity
function functionDelegateCall(address target, bytes data) internal returns (bytes)
```

_Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
but performing a delegate call._

### verifyCallResultFromTarget

```solidity
function verifyCallResultFromTarget(address target, bool success, bytes returndata) internal view returns (bytes)
```

_Tool to verify that a low level call to smart-contract was successful, and reverts if the target
was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
unsuccessful call._

### verifyCallResult

```solidity
function verifyCallResult(bool success, bytes returndata) internal pure returns (bytes)
```

_Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
revert reason or with a default {FailedInnerCall} error._

## IBeacon

_This is the interface that {BeaconProxy} expects of its beacon._

### implementation

```solidity
function implementation() external view returns (address)
```

_Must return an address that can be used as a delegate call target.

{UpgradeableBeacon} will check that this address is a contract._

## ERC1967Utils

_This abstract contract provides getters and event emitting update functions for
https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots._

### Upgraded

```solidity
event Upgraded(address implementation)
```

_Emitted when the implementation is upgraded._

### AdminChanged

```solidity
event AdminChanged(address previousAdmin, address newAdmin)
```

_Emitted when the admin account has changed._

### BeaconUpgraded

```solidity
event BeaconUpgraded(address beacon)
```

_Emitted when the beacon is changed._

### IMPLEMENTATION_SLOT

```solidity
bytes32 IMPLEMENTATION_SLOT
```

_Storage slot with the address of the current implementation.
This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1._

### ERC1967InvalidImplementation

```solidity
error ERC1967InvalidImplementation(address implementation)
```

_The `implementation` of the proxy is invalid._

### ERC1967InvalidAdmin

```solidity
error ERC1967InvalidAdmin(address admin)
```

_The `admin` of the proxy is invalid._

### ERC1967InvalidBeacon

```solidity
error ERC1967InvalidBeacon(address beacon)
```

_The `beacon` of the proxy is invalid._

### ERC1967NonPayable

```solidity
error ERC1967NonPayable()
```

_An upgrade function sees `msg.value > 0` that may be lost._

### getImplementation

```solidity
function getImplementation() internal view returns (address)
```

_Returns the current implementation address._

### upgradeToAndCall

```solidity
function upgradeToAndCall(address newImplementation, bytes data) internal
```

_Performs implementation upgrade with additional setup call if data is nonempty.
This function is payable only if the setup call is performed, otherwise `msg.value` is rejected
to avoid stuck value in the contract.

Emits an {IERC1967-Upgraded} event._

### ADMIN_SLOT

```solidity
bytes32 ADMIN_SLOT
```

_Storage slot with the admin of the contract.
This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1._

### getAdmin

```solidity
function getAdmin() internal view returns (address)
```

_Returns the current admin.

TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using
the https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
`0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`_

### changeAdmin

```solidity
function changeAdmin(address newAdmin) internal
```

_Changes the admin of the proxy.

Emits an {IERC1967-AdminChanged} event._

### BEACON_SLOT

```solidity
bytes32 BEACON_SLOT
```

_The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
This is the keccak-256 hash of "eip1967.proxy.beacon" subtracted by 1._

### getBeacon

```solidity
function getBeacon() internal view returns (address)
```

_Returns the current beacon._

### upgradeBeaconToAndCall

```solidity
function upgradeBeaconToAndCall(address newBeacon, bytes data) internal
```

_Change the beacon and trigger a setup call if data is nonempty.
This function is payable only if the setup call is performed, otherwise `msg.value` is rejected
to avoid stuck value in the contract.

Emits an {IERC1967-BeaconUpgraded} event.

CAUTION: Invoking this function has no effect on an instance of {BeaconProxy} since v5, since
it uses an immutable beacon without looking at the value of the ERC-1967 beacon slot for
efficiency._

## IERC1822Proxiable

_ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
proxy whose upgrades are fully controlled by the current implementation._

### proxiableUUID

```solidity
function proxiableUUID() external view returns (bytes32)
```

_Returns the storage slot that the proxiable contract assumes is being used to store the implementation
address.

IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
function revert if invoked through a proxy._

## IERC165

_Interface of the ERC165 standard, as defined in the
https://eips.ethereum.org/EIPS/eip-165[EIP].

Implementers can declare support of contract interfaces, which can then be
queried by others ({ERC165Checker}).

For an implementation, see {ERC165}._

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) external view returns (bool)
```

_Returns true if this contract implements the interface defined by
`interfaceId`. See the corresponding
https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
to learn more about how these ids are created.

This function call must use less than 30 000 gas._

## IAccessControl

_External interface of AccessControl declared to support ERC165 detection._

### AccessControlUnauthorizedAccount

```solidity
error AccessControlUnauthorizedAccount(address account, bytes32 neededRole)
```

_The `account` is missing a role._

### AccessControlBadConfirmation

```solidity
error AccessControlBadConfirmation()
```

_The caller of a function is not the expected one.

NOTE: Don't confuse with {AccessControlUnauthorizedAccount}._

### RoleAdminChanged

```solidity
event RoleAdminChanged(bytes32 role, bytes32 previousAdminRole, bytes32 newAdminRole)
```

_Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`

`DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
{RoleAdminChanged} not being emitted signaling this._

### RoleGranted

```solidity
event RoleGranted(bytes32 role, address account, address sender)
```

_Emitted when `account` is granted `role`.

`sender` is the account that originated the contract call, an admin role
bearer except when using {AccessControl-_setupRole}._

### RoleRevoked

```solidity
event RoleRevoked(bytes32 role, address account, address sender)
```

_Emitted when `account` is revoked `role`.

`sender` is the account that originated the contract call:
  - if using `revokeRole`, it is the admin role bearer
  - if using `renounceRole`, it is the role bearer (i.e. `account`)_

### hasRole

```solidity
function hasRole(bytes32 role, address account) external view returns (bool)
```

_Returns `true` if `account` has been granted `role`._

### getRoleAdmin

```solidity
function getRoleAdmin(bytes32 role) external view returns (bytes32)
```

_Returns the admin role that controls `role`. See {grantRole} and
{revokeRole}.

To change a role's admin, use {AccessControl-_setRoleAdmin}._

### grantRole

```solidity
function grantRole(bytes32 role, address account) external
```

_Grants `role` to `account`.

If `account` had not been already granted `role`, emits a {RoleGranted}
event.

Requirements:

- the caller must have ``role``'s admin role._

### revokeRole

```solidity
function revokeRole(bytes32 role, address account) external
```

_Revokes `role` from `account`.

If `account` had been granted `role`, emits a {RoleRevoked} event.

Requirements:

- the caller must have ``role``'s admin role._

### renounceRole

```solidity
function renounceRole(bytes32 role, address callerConfirmation) external
```

_Revokes `role` from the calling account.

Roles are often managed via {grantRole} and {revokeRole}: this function's
purpose is to provide a mechanism for accounts to lose their privileges
if they are compromised (such as when a trusted device is misplaced).

If the calling account had been granted `role`, emits a {RoleRevoked}
event.

Requirements:

- the caller must be `callerConfirmation`._

## IERC20Errors

_Standard ERC20 Errors
Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC20 tokens._

### ERC20InsufficientBalance

```solidity
error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed)
```

_Indicates an error related to the current `balance` of a `sender`. Used in transfers._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sender | address | Address whose tokens are being transferred. |
| balance | uint256 | Current balance for the interacting account. |
| needed | uint256 | Minimum amount required to perform a transfer. |

### ERC20InvalidSender

```solidity
error ERC20InvalidSender(address sender)
```

_Indicates a failure with the token `sender`. Used in transfers._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sender | address | Address whose tokens are being transferred. |

### ERC20InvalidReceiver

```solidity
error ERC20InvalidReceiver(address receiver)
```

_Indicates a failure with the token `receiver`. Used in transfers._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| receiver | address | Address to which tokens are being transferred. |

### ERC20InsufficientAllowance

```solidity
error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed)
```

_Indicates a failure with the `spender`’s `allowance`. Used in transfers._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| spender | address | Address that may be allowed to operate on tokens without being their owner. |
| allowance | uint256 | Amount of tokens a `spender` is allowed to operate with. |
| needed | uint256 | Minimum amount required to perform a transfer. |

### ERC20InvalidApprover

```solidity
error ERC20InvalidApprover(address approver)
```

_Indicates a failure with the `approver` of a token to be approved. Used in approvals._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| approver | address | Address initiating an approval operation. |

### ERC20InvalidSpender

```solidity
error ERC20InvalidSpender(address spender)
```

_Indicates a failure with the `spender` to be approved. Used in approvals._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| spender | address | Address that may be allowed to operate on tokens without being their owner. |

## IERC721Errors

_Standard ERC721 Errors
Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC721 tokens._

### ERC721InvalidOwner

```solidity
error ERC721InvalidOwner(address owner)
```

_Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in EIP-20.
Used in balance queries._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| owner | address | Address of the current owner of a token. |

### ERC721NonexistentToken

```solidity
error ERC721NonexistentToken(uint256 tokenId)
```

_Indicates a `tokenId` whose `owner` is the zero address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | Identifier number of a token. |

### ERC721IncorrectOwner

```solidity
error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner)
```

_Indicates an error related to the ownership over a particular token. Used in transfers._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sender | address | Address whose tokens are being transferred. |
| tokenId | uint256 | Identifier number of a token. |
| owner | address | Address of the current owner of a token. |

### ERC721InvalidSender

```solidity
error ERC721InvalidSender(address sender)
```

_Indicates a failure with the token `sender`. Used in transfers._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sender | address | Address whose tokens are being transferred. |

### ERC721InvalidReceiver

```solidity
error ERC721InvalidReceiver(address receiver)
```

_Indicates a failure with the token `receiver`. Used in transfers._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| receiver | address | Address to which tokens are being transferred. |

### ERC721InsufficientApproval

```solidity
error ERC721InsufficientApproval(address operator, uint256 tokenId)
```

_Indicates a failure with the `operator`’s approval. Used in transfers._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operator | address | Address that may be allowed to operate on tokens without being their owner. |
| tokenId | uint256 | Identifier number of a token. |

### ERC721InvalidApprover

```solidity
error ERC721InvalidApprover(address approver)
```

_Indicates a failure with the `approver` of a token to be approved. Used in approvals._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| approver | address | Address initiating an approval operation. |

### ERC721InvalidOperator

```solidity
error ERC721InvalidOperator(address operator)
```

_Indicates a failure with the `operator` to be approved. Used in approvals._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operator | address | Address that may be allowed to operate on tokens without being their owner. |

## IERC1155Errors

_Standard ERC1155 Errors
Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC1155 tokens._

### ERC1155InsufficientBalance

```solidity
error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId)
```

_Indicates an error related to the current `balance` of a `sender`. Used in transfers._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sender | address | Address whose tokens are being transferred. |
| balance | uint256 | Current balance for the interacting account. |
| needed | uint256 | Minimum amount required to perform a transfer. |
| tokenId | uint256 | Identifier number of a token. |

### ERC1155InvalidSender

```solidity
error ERC1155InvalidSender(address sender)
```

_Indicates a failure with the token `sender`. Used in transfers._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| sender | address | Address whose tokens are being transferred. |

### ERC1155InvalidReceiver

```solidity
error ERC1155InvalidReceiver(address receiver)
```

_Indicates a failure with the token `receiver`. Used in transfers._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| receiver | address | Address to which tokens are being transferred. |

### ERC1155MissingApprovalForAll

```solidity
error ERC1155MissingApprovalForAll(address operator, address owner)
```

_Indicates a failure with the `operator`’s approval. Used in transfers._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operator | address | Address that may be allowed to operate on tokens without being their owner. |
| owner | address | Address of the current owner of a token. |

### ERC1155InvalidApprover

```solidity
error ERC1155InvalidApprover(address approver)
```

_Indicates a failure with the `approver` of a token to be approved. Used in approvals._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| approver | address | Address initiating an approval operation. |

### ERC1155InvalidOperator

```solidity
error ERC1155InvalidOperator(address operator)
```

_Indicates a failure with the `operator` to be approved. Used in approvals._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operator | address | Address that may be allowed to operate on tokens without being their owner. |

### ERC1155InvalidArrayLength

```solidity
error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength)
```

_Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
Used in batch transfers._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| idsLength | uint256 | Length of the array of token identifiers |
| valuesLength | uint256 | Length of the array of token amounts |

## Initializable

_This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.

The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
case an upgrade adds a module that needs to be initialized.

For example:

[.hljs-theme-light.nopadding]
```solidity
contract MyToken is ERC20Upgradeable {
    function initialize() initializer public {
        __ERC20_init("MyToken", "MTK");
    }
}

contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
    function initializeV2() reinitializer(2) public {
        __ERC20Permit_init("MyToken");
    }
}
```

TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.

CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.

[CAUTION]
====
Avoid leaving a contract uninitialized.

An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:

[.hljs-theme-light.nopadding]
```
/// @custom:oz-upgrades-unsafe-allow constructor
constructor() {
    _disableInitializers();
}
```
====_

### InitializableStorage

_Storage of the initializable contract.

It's implemented on a custom ERC-7201 namespace to reduce the risk of storage collisions
when using with upgradeable contracts._

```solidity
struct InitializableStorage {
  uint64 _initialized;
  bool _initializing;
}
```

### InvalidInitialization

```solidity
error InvalidInitialization()
```

_The contract is already initialized._

### NotInitializing

```solidity
error NotInitializing()
```

_The contract is not initializing._

### Initialized

```solidity
event Initialized(uint64 version)
```

_Triggered when the contract has been initialized or reinitialized._

### initializer

```solidity
modifier initializer()
```

_A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
`onlyInitializing` functions can be used to initialize parent contracts.

Similar to `reinitializer(1)`, except that in the context of a constructor an `initializer` may be invoked any
number of times. This behavior in the constructor can be useful during testing and is not expected to be used in
production.

Emits an {Initialized} event._

### reinitializer

```solidity
modifier reinitializer(uint64 version)
```

_A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
used to initialize parent contracts.

A reinitializer may be used after the original initialization step. This is essential to configure modules that
are added through upgrades and that require initialization.

When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
cannot be nested. If one is invoked in the context of another, execution will revert.

Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
a contract, executing them in the right order is up to the developer or operator.

WARNING: Setting the version to 2**64 - 1 will prevent any future reinitialization.

Emits an {Initialized} event._

### onlyInitializing

```solidity
modifier onlyInitializing()
```

_Modifier to protect an initialization function so that it can only be invoked by functions with the
{initializer} and {reinitializer} modifiers, directly or indirectly._

### _checkInitializing

```solidity
function _checkInitializing() internal view virtual
```

_Reverts if the contract is not in an initializing state. See {onlyInitializing}._

### _disableInitializers

```solidity
function _disableInitializers() internal virtual
```

_Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
to any version. It is recommended to use this to lock implementation contracts that are designed to be called
through proxies.

Emits an {Initialized} event the first time it is successfully executed._

### _getInitializedVersion

```solidity
function _getInitializedVersion() internal view returns (uint64)
```

_Returns the highest version that has been initialized. See {reinitializer}._

### _isInitializing

```solidity
function _isInitializing() internal view returns (bool)
```

_Returns `true` if the contract is currently initializing. See {onlyInitializing}._

## UUPSUpgradeable

_An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
{ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.

A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
`UUPSUpgradeable` with a custom implementation of upgrades.

The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism._

### UPGRADE_INTERFACE_VERSION

```solidity
string UPGRADE_INTERFACE_VERSION
```

_The version of the upgrade interface of the contract. If this getter is missing, both `upgradeTo(address)`
and `upgradeToAndCall(address,bytes)` are present, and `upgradeTo` must be used if no function should be called,
while `upgradeToAndCall` will invoke the `receive` function if the second argument is the empty byte string.
If the getter returns `"5.0.0"`, only `upgradeToAndCall(address,bytes)` is present, and the second argument must
be the empty byte string if no function should be called, making it impossible to invoke the `receive` function
during an upgrade._

### UUPSUnauthorizedCallContext

```solidity
error UUPSUnauthorizedCallContext()
```

_The call is from an unauthorized context._

### UUPSUnsupportedProxiableUUID

```solidity
error UUPSUnsupportedProxiableUUID(bytes32 slot)
```

_The storage `slot` is unsupported as a UUID._

### onlyProxy

```solidity
modifier onlyProxy()
```

_Check that the execution is being performed through a delegatecall call and that the execution context is
a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
fail._

### notDelegated

```solidity
modifier notDelegated()
```

_Check that the execution is not being performed through a delegate call. This allows a function to be
callable on the implementing contract but not through proxies._

### __UUPSUpgradeable_init

```solidity
function __UUPSUpgradeable_init() internal
```

### __UUPSUpgradeable_init_unchained

```solidity
function __UUPSUpgradeable_init_unchained() internal
```

### proxiableUUID

```solidity
function proxiableUUID() external view virtual returns (bytes32)
```

_Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
implementation. It is used to validate the implementation's compatibility when performing an upgrade.

IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier._

### upgradeToAndCall

```solidity
function upgradeToAndCall(address newImplementation, bytes data) public payable virtual
```

_Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
encoded in `data`.

Calls {_authorizeUpgrade}.

Emits an {Upgraded} event._

### _checkProxy

```solidity
function _checkProxy() internal view virtual
```

_Reverts if the execution is not performed via delegatecall or the execution
context is not of a proxy with an ERC1967-compliant implementation pointing to self.
See {_onlyProxy}._

### _checkNotDelegated

```solidity
function _checkNotDelegated() internal view virtual
```

_Reverts if the execution is performed via delegatecall.
See {notDelegated}._

### _authorizeUpgrade

```solidity
function _authorizeUpgrade(address newImplementation) internal virtual
```

_Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
{upgradeToAndCall}.

Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.

```solidity
function _authorizeUpgrade(address) internal onlyOwner {}
```_

## ERC165Upgradeable

_Implementation of the {IERC165} interface.

Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
for the additional interface id that will be supported. For example:

```solidity
function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
}
```_

### __ERC165_init

```solidity
function __ERC165_init() internal
```

### __ERC165_init_unchained

```solidity
function __ERC165_init_unchained() internal
```

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) public view virtual returns (bool)
```

_See {IERC165-supportsInterface}._

## ContextUpgradeable

_Provides information about the current execution context, including the
sender of the transaction and its data. While these are generally available
via msg.sender and msg.data, they should not be accessed in such a direct
manner, since when dealing with meta-transactions the account sending and
paying for execution may not be the actual sender (as far as an application
is concerned).

This contract is only required for intermediate, library-like contracts._

### __Context_init

```solidity
function __Context_init() internal
```

### __Context_init_unchained

```solidity
function __Context_init_unchained() internal
```

### _msgSender

```solidity
function _msgSender() internal view virtual returns (address)
```

### _msgData

```solidity
function _msgData() internal view virtual returns (bytes)
```

### _contextSuffixLength

```solidity
function _contextSuffixLength() internal view virtual returns (uint256)
```

## AccessControlUpgradeable

_Contract module that allows children to implement role-based access
control mechanisms. This is a lightweight version that doesn't allow enumerating role
members except through off-chain means by accessing the contract event logs. Some
applications may benefit from on-chain enumerability, for those cases see
{AccessControlEnumerable}.

Roles are referred to by their `bytes32` identifier. These should be exposed
in the external API and be unique. The best way to achieve this is by
using `public constant` hash digests:

```solidity
bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
```

Roles can be used to represent a set of permissions. To restrict access to a
function call, use {hasRole}:

```solidity
function foo() public {
    require(hasRole(MY_ROLE, msg.sender));
    ...
}
```

Roles can be granted and revoked dynamically via the {grantRole} and
{revokeRole} functions. Each role has an associated admin role, and only
accounts that have a role's admin role can call {grantRole} and {revokeRole}.

By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
that only accounts with this role will be able to grant or revoke other
roles. More complex role relationships can be created by using
{_setRoleAdmin}.

WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
grant and revoke this role. Extra precautions should be taken to secure
accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
to enforce additional security measures for this role._

### RoleData

```solidity
struct RoleData {
  mapping(address => bool) hasRole;
  bytes32 adminRole;
}
```

### DEFAULT_ADMIN_ROLE

```solidity
bytes32 DEFAULT_ADMIN_ROLE
```

### AccessControlStorage

```solidity
struct AccessControlStorage {
  mapping(bytes32 => struct AccessControlUpgradeable.RoleData) _roles;
}
```

### onlyRole

```solidity
modifier onlyRole(bytes32 role)
```

_Modifier that checks that an account has a specific role. Reverts
with an {AccessControlUnauthorizedAccount} error including the required role._

### __AccessControl_init

```solidity
function __AccessControl_init() internal
```

### __AccessControl_init_unchained

```solidity
function __AccessControl_init_unchained() internal
```

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) public view virtual returns (bool)
```

_See {IERC165-supportsInterface}._

### hasRole

```solidity
function hasRole(bytes32 role, address account) public view virtual returns (bool)
```

_Returns `true` if `account` has been granted `role`._

### _checkRole

```solidity
function _checkRole(bytes32 role) internal view virtual
```

_Reverts with an {AccessControlUnauthorizedAccount} error if `_msgSender()`
is missing `role`. Overriding this function changes the behavior of the {onlyRole} modifier._

### _checkRole

```solidity
function _checkRole(bytes32 role, address account) internal view virtual
```

_Reverts with an {AccessControlUnauthorizedAccount} error if `account`
is missing `role`._

### getRoleAdmin

```solidity
function getRoleAdmin(bytes32 role) public view virtual returns (bytes32)
```

_Returns the admin role that controls `role`. See {grantRole} and
{revokeRole}.

To change a role's admin, use {_setRoleAdmin}._

### grantRole

```solidity
function grantRole(bytes32 role, address account) public virtual
```

_Grants `role` to `account`.

If `account` had not been already granted `role`, emits a {RoleGranted}
event.

Requirements:

- the caller must have ``role``'s admin role.

May emit a {RoleGranted} event._

### revokeRole

```solidity
function revokeRole(bytes32 role, address account) public virtual
```

_Revokes `role` from `account`.

If `account` had been granted `role`, emits a {RoleRevoked} event.

Requirements:

- the caller must have ``role``'s admin role.

May emit a {RoleRevoked} event._

### renounceRole

```solidity
function renounceRole(bytes32 role, address callerConfirmation) public virtual
```

_Revokes `role` from the calling account.

Roles are often managed via {grantRole} and {revokeRole}: this function's
purpose is to provide a mechanism for accounts to lose their privileges
if they are compromised (such as when a trusted device is misplaced).

If the calling account had been revoked `role`, emits a {RoleRevoked}
event.

Requirements:

- the caller must be `callerConfirmation`.

May emit a {RoleRevoked} event._

### _setRoleAdmin

```solidity
function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual
```

_Sets `adminRole` as ``role``'s admin role.

Emits a {RoleAdminChanged} event._

### _grantRole

```solidity
function _grantRole(bytes32 role, address account) internal virtual returns (bool)
```

_Attempts to grant `role` to `account` and returns a boolean indicating if `role` was granted.

Internal function without access restriction.

May emit a {RoleGranted} event._

### _revokeRole

```solidity
function _revokeRole(bytes32 role, address account) internal virtual returns (bool)
```

_Attempts to revoke `role` to `account` and returns a boolean indicating if `role` was revoked.

Internal function without access restriction.

May emit a {RoleRevoked} event._

## IERC20

_Interface of the ERC20 standard as defined in the EIP._

### Transfer

```solidity
event Transfer(address from, address to, uint256 value)
```

_Emitted when `value` tokens are moved from one account (`from`) to
another (`to`).

Note that `value` may be zero._

### Approval

```solidity
event Approval(address owner, address spender, uint256 value)
```

_Emitted when the allowance of a `spender` for an `owner` is set by
a call to {approve}. `value` is the new allowance._

### totalSupply

```solidity
function totalSupply() external view returns (uint256)
```

_Returns the value of tokens in existence._

### balanceOf

```solidity
function balanceOf(address account) external view returns (uint256)
```

_Returns the value of tokens owned by `account`._

### transfer

```solidity
function transfer(address to, uint256 value) external returns (bool)
```

_Moves a `value` amount of tokens from the caller's account to `to`.

Returns a boolean value indicating whether the operation succeeded.

Emits a {Transfer} event._

### allowance

```solidity
function allowance(address owner, address spender) external view returns (uint256)
```

_Returns the remaining number of tokens that `spender` will be
allowed to spend on behalf of `owner` through {transferFrom}. This is
zero by default.

This value changes when {approve} or {transferFrom} are called._

### approve

```solidity
function approve(address spender, uint256 value) external returns (bool)
```

_Sets a `value` amount of tokens as the allowance of `spender` over the
caller's tokens.

Returns a boolean value indicating whether the operation succeeded.

IMPORTANT: Beware that changing an allowance with this method brings the risk
that someone may use both the old and the new allowance by unfortunate
transaction ordering. One possible solution to mitigate this race
condition is to first reduce the spender's allowance to 0 and set the
desired value afterwards:
https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729

Emits an {Approval} event._

### transferFrom

```solidity
function transferFrom(address from, address to, uint256 value) external returns (bool)
```

_Moves a `value` amount of tokens from `from` to `to` using the
allowance mechanism. `value` is then deducted from the caller's
allowance.

Returns a boolean value indicating whether the operation succeeded.

Emits a {Transfer} event._

## IERC20Metadata

_Interface for the optional metadata functions from the ERC20 standard._

### name

```solidity
function name() external view returns (string)
```

_Returns the name of the token._

### symbol

```solidity
function symbol() external view returns (string)
```

_Returns the symbol of the token._

### decimals

```solidity
function decimals() external view returns (uint8)
```

_Returns the decimals places of the token._

## ERC20Upgradeable

_Implementation of the {IERC20} interface.

This implementation is agnostic to the way tokens are created. This means
that a supply mechanism has to be added in a derived contract using {_mint}.

TIP: For a detailed writeup see our guide
https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
to implement supply mechanisms].

The default value of {decimals} is 18. To change this, you should override
this function so it returns a different value.

We have followed general OpenZeppelin Contracts guidelines: functions revert
instead returning `false` on failure. This behavior is nonetheless
conventional and does not conflict with the expectations of ERC20
applications.

Additionally, an {Approval} event is emitted on calls to {transferFrom}.
This allows applications to reconstruct the allowance for all accounts just
by listening to said events. Other implementations of the EIP may not emit
these events, as it isn't required by the specification._

### ERC20Storage

```solidity
struct ERC20Storage {
  mapping(address => uint256) _balances;
  mapping(address => mapping(address => uint256)) _allowances;
  uint256 _totalSupply;
  string _name;
  string _symbol;
}
```

### __ERC20_init

```solidity
function __ERC20_init(string name_, string symbol_) internal
```

_Sets the values for {name} and {symbol}.

All two of these values are immutable: they can only be set once during
construction._

### __ERC20_init_unchained

```solidity
function __ERC20_init_unchained(string name_, string symbol_) internal
```

### name

```solidity
function name() public view virtual returns (string)
```

_Returns the name of the token._

### symbol

```solidity
function symbol() public view virtual returns (string)
```

_Returns the symbol of the token, usually a shorter version of the
name._

### decimals

```solidity
function decimals() public view virtual returns (uint8)
```

_Returns the number of decimals used to get its user representation.
For example, if `decimals` equals `2`, a balance of `505` tokens should
be displayed to a user as `5.05` (`505 / 10 ** 2`).

Tokens usually opt for a value of 18, imitating the relationship between
Ether and Wei. This is the default value returned by this function, unless
it's overridden.

NOTE: This information is only used for _display_ purposes: it in
no way affects any of the arithmetic of the contract, including
{IERC20-balanceOf} and {IERC20-transfer}._

### totalSupply

```solidity
function totalSupply() public view virtual returns (uint256)
```

_See {IERC20-totalSupply}._

### balanceOf

```solidity
function balanceOf(address account) public view virtual returns (uint256)
```

_See {IERC20-balanceOf}._

### transfer

```solidity
function transfer(address to, uint256 value) public virtual returns (bool)
```

_See {IERC20-transfer}.

Requirements:

- `to` cannot be the zero address.
- the caller must have a balance of at least `value`._

### allowance

```solidity
function allowance(address owner, address spender) public view virtual returns (uint256)
```

_See {IERC20-allowance}._

### approve

```solidity
function approve(address spender, uint256 value) public virtual returns (bool)
```

_See {IERC20-approve}.

NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
`transferFrom`. This is semantically equivalent to an infinite approval.

Requirements:

- `spender` cannot be the zero address._

### transferFrom

```solidity
function transferFrom(address from, address to, uint256 value) public virtual returns (bool)
```

_See {IERC20-transferFrom}.

Emits an {Approval} event indicating the updated allowance. This is not
required by the EIP. See the note at the beginning of {ERC20}.

NOTE: Does not update the allowance if the current allowance
is the maximum `uint256`.

Requirements:

- `from` and `to` cannot be the zero address.
- `from` must have a balance of at least `value`.
- the caller must have allowance for ``from``'s tokens of at least
`value`._

### _transfer

```solidity
function _transfer(address from, address to, uint256 value) internal
```

_Moves a `value` amount of tokens from `from` to `to`.

This internal function is equivalent to {transfer}, and can be used to
e.g. implement automatic token fees, slashing mechanisms, etc.

Emits a {Transfer} event.

NOTE: This function is not virtual, {_update} should be overridden instead._

### _update

```solidity
function _update(address from, address to, uint256 value) internal virtual
```

_Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
(or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
this function.

Emits a {Transfer} event._

### _mint

```solidity
function _mint(address account, uint256 value) internal
```

_Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
Relies on the `_update` mechanism

Emits a {Transfer} event with `from` set to the zero address.

NOTE: This function is not virtual, {_update} should be overridden instead._

### _burn

```solidity
function _burn(address account, uint256 value) internal
```

_Destroys a `value` amount of tokens from `account`, lowering the total supply.
Relies on the `_update` mechanism.

Emits a {Transfer} event with `to` set to the zero address.

NOTE: This function is not virtual, {_update} should be overridden instead_

### _approve

```solidity
function _approve(address owner, address spender, uint256 value) internal
```

_Sets `value` as the allowance of `spender` over the `owner` s tokens.

This internal function is equivalent to `approve`, and can be used to
e.g. set automatic allowances for certain subsystems, etc.

Emits an {Approval} event.

Requirements:

- `owner` cannot be the zero address.
- `spender` cannot be the zero address.

Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument._

### _approve

```solidity
function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual
```

_Variant of {_approve} with an optional flag to enable or disable the {Approval} event.

By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
`_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
`Approval` event during `transferFrom` operations.

Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to
true using the following override:
```
function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
    super._approve(owner, spender, value, true);
}
```

Requirements are the same as {_approve}._

### _spendAllowance

```solidity
function _spendAllowance(address owner, address spender, uint256 value) internal virtual
```

_Updates `owner` s allowance for `spender` based on spent `value`.

Does not update the allowance value in case of infinite allowance.
Revert if not enough allowance is available.

Does not emit an {Approval} event._

## ERC20CappedUpgradeable

_Extension of {ERC20} that adds a cap to the supply of tokens._

### ERC20CappedStorage

```solidity
struct ERC20CappedStorage {
  uint256 _cap;
}
```

### ERC20ExceededCap

```solidity
error ERC20ExceededCap(uint256 increasedSupply, uint256 cap)
```

_Total supply cap has been exceeded._

### ERC20InvalidCap

```solidity
error ERC20InvalidCap(uint256 cap)
```

_The supplied cap is not a valid cap._

### __ERC20Capped_init

```solidity
function __ERC20Capped_init(uint256 cap_) internal
```

_Sets the value of the `cap`. This value is immutable, it can only be
set once during construction._

### __ERC20Capped_init_unchained

```solidity
function __ERC20Capped_init_unchained(uint256 cap_) internal
```

### cap

```solidity
function cap() public view virtual returns (uint256)
```

_Returns the cap on the token's total supply._

### _update

```solidity
function _update(address from, address to, uint256 value) internal virtual
```

_See {ERC20-_update}._

## PikaMoon

_A simple ERC20 token contract that allows minting and burning of tokens._

### feeMultiply

```solidity
uint32 feeMultiply
```

### marketingTax

```solidity
uint16 marketingTax
```

### ecosystemTax

```solidity
uint16 ecosystemTax
```

### burnTax

```solidity
uint16 burnTax
```

### ecoSystemWallet

```solidity
address ecoSystemWallet
```

### marketingWallet

```solidity
address marketingWallet
```

### isExcludeFromTax

```solidity
mapping(address => bool) isExcludeFromTax
```

### automatedMarketMakerPairs

```solidity
mapping(address => bool) automatedMarketMakerPairs
```

### isTaxEnabled

```solidity
bool isTaxEnabled
```

### SetAutomatedMarketMakerPair

```solidity
event SetAutomatedMarketMakerPair(address pair, bool value)
```

### ToggleTax

```solidity
event ToggleTax(bool tax)
```

### ExcludeFromTax

```solidity
event ExcludeFromTax(address _user, bool _isExcludeFromTax)
```

### EventEcoSystemWallet

```solidity
event EventEcoSystemWallet(address ecoSystemWallet, address _ecoSystemWallet)
```

### EventMarketingWallet

```solidity
event EventMarketingWallet(address marketingWallet, address _marketingWallet)
```

### constructor

```solidity
constructor() public
```

### initialize

```solidity
function initialize(string _name, string _symbol, address _ecosystemdevelopment, address _marketing) external
```

_Initializer function to initialize the contract._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _name | string | The name of the token. |
| _symbol | string | The symbol of the token. |
| _ecosystemdevelopment | address | ecosystem wallet. |
| _marketing | address | marketing wallet. |

### _authorizeUpgrade

```solidity
function _authorizeUpgrade(address newImplementation) internal
```

_Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
{upgradeToAndCall}._

### setAutomatedMarketMakerPair

```solidity
function setAutomatedMarketMakerPair(address pair, bool value) external
```

_function for setting Automated MarketMaker Pair_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pair | address | address for pair. |
| value | bool | boolean true or false. |

### decimals

```solidity
function decimals() public pure returns (uint8)
```

_Function to get decimals._

### mint

```solidity
function mint(address to, uint256 amount) external
```

_Function to mint new tokens and assign them to a specified address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | The address to which the new tokens are minted. |
| amount | uint256 | The amount of tokens to be minted. |

### burn

```solidity
function burn(uint256 amount) external
```

_Function for user to burn there balance._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | The amount of tokens to be burned. |

### changeEcoSystemWallet

```solidity
function changeEcoSystemWallet(address _ecoSystemWallet) external
```

_Function to set ecosystem address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _ecoSystemWallet | address | The address to ecosystem wallet. |

### changeMarketingWallet

```solidity
function changeMarketingWallet(address _marketing) external
```

_Function to set marketing address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _marketing | address | The address to  marketing wallet. |

### excludeFromTax

```solidity
function excludeFromTax(address _user, bool _isExcludeFromTax) external
```

_Function to update isExcludeFromTax mapping to exclude or include From Tax_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _user | address | The address to be exclude or include From Tax |
| _isExcludeFromTax | bool | true or false |

### toggleTax

```solidity
function toggleTax() external
```

_Function to toggle tax_

### transfer

```solidity
function transfer(address to, uint256 value) public returns (bool)
```

Pikamoon incorporates a small 2.5% transaction tax on Sell orders & Transfers.
There is NO buy Tax when purchasing $PIKA. The Pikamoon token is used to support our metaverse
and marketplace, therefore we want to reward hodlers of Pikamoon by punishing those leaving our ecosystem.
1% of the tax will go towards marketing, 1% towards the ecosystem development fund / P2E Rewards
and 0.5% burned forever!

_Moves a `value` amount of tokens from the caller's account to `to`._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | The address to which the tokens are being transfered. |
| value | uint256 | The amount of tokens to be transfered. |

### transferFrom

```solidity
function transferFrom(address from, address to, uint256 value) public returns (bool)
```

Pikamoon incorporates a small 2.5% transaction tax on Sell orders & Transfers.
There is NO buy Tax when purchasing $PIKA. The Pikamoon token is used to support our metaverse
and marketplace, therefore we want to reward hodlers of Pikamoon by punishing those leaving our ecosystem.
1% of the tax will go towards marketing, 1% towards the ecosystem development fund / P2E Rewards
and 0.5% burned forever!

_Moves a `value` amount of tokens from `from` to `to` using the
allowance mechanism. `value` is then deducted from the caller's
allowance._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| from | address | The address from which the tokens are being transfered. |
| to | address | The address to which the tokens are being transfered. |
| value | uint256 | The amount of tokens to be transfered. |

### calculateTax

```solidity
function calculateTax(address from, address to, uint256 value) public view returns (uint256 tax, uint256 burnAmount, uint256 marketingAmount, uint256 ecosystemAmount)
```

_Function to calculate the tax_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| from | address | address on which tax is applied |
| to | address | address on which tax is applied |
| value | uint256 | amount on which tax is calculated |

