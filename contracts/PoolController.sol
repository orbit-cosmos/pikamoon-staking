// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ICorePool} from "./interfaces/ICorePool.sol";
import {CommonErrors} from "./libraries/Errors.sol";
import {IPikaMoon} from "./interfaces/IPikaMoon.sol";

contract PoolController is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    using SafeERC20 for IPikaMoon;
    /**
     * @dev PIKA/second determines rewards farming reward base
     */
    uint256 public pikaPerSecond;
    /**
     * @dev The yield is distributed proportionally to pool weights;
     *      total weight is here to help in determining the proportion.
     */
    uint256 public totalWeight;

    /// @dev Keeps track of registered pool addresses, maps pool address -> exists flag.
    mapping(address => bool) public poolExists;
    mapping(address => address) public pools;

    /**
     * @dev Fired in `changePoolWeight()`.
     *
     * @param by an address which executed an action
     * @param poolAddress deployed pool instance address
     * @param weight new pool weight
     */
    event LogChangePoolWeight(
        address indexed by,
        address indexed poolAddress,
        uint256 weight
    );

    /**
     * @dev Fired in `updatePikaPerSecond()`.
     *
     * @param newPikaPerSecond new Pika/second value
     */
    event LogUpdatePikaPerSecond(uint256 newPikaPerSecond);

    /**
     * @dev Fired in registerPool()
     * @param addr an address of pool
     */
    event LogRegisterPool(address indexed addr);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() external initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        pikaPerSecond = 25.3678335870 gwei; // pika has 9 decimals, so gwei = 10**9

        totalWeight = 1000; //(direct staking)200 + (pool staking)800
    }
    /// @notice Registers a new pool
    /// @dev Only callable by the owner; emits LogRegisterPool on success
    /// @param _poolAddress The address of the pool to register
    function registerPool(address _poolAddress) external onlyOwner {
        if (poolExists[_poolAddress]) {
            revert CommonErrors.AlreadyRegistered();
        }

        (bool ok, bytes memory result) = _poolAddress.staticcall(abi.encodeWithSignature("poolToken()"));
        require(ok);
        
        address poolToken = abi.decode(result, (address));
        pools[poolToken] = _poolAddress;
        poolExists[_poolAddress] = true;

        emit LogRegisterPool(_poolAddress);
    }
    /// @notice Updates the rate of PIKA distribution per second
    /// @dev Only callable by the owner; emits LogUpdatePikaPerSecond on success
    /// @param _pikaPerSecond The new rate of PIKA distribution per second
    function updatePikaPerSecond(uint256 _pikaPerSecond) external onlyOwner {
        if (_pikaPerSecond == 0) revert CommonErrors.ZeroAmount();
        pikaPerSecond = _pikaPerSecond;
        emit LogUpdatePikaPerSecond(_pikaPerSecond);
    }

    /// @notice Transfers reward tokens from a registered pool
    /// @dev Only callable by a registered pool
    /// @param _token The token address to transfer
    /// @param _to The recipient address
    /// @param _value The amount of tokens to transfer
    function transferRewardTokens(
        address _token,
        address _to,
        uint256 _value
    ) public {
        if (!poolExists[msg.sender]) {
            revert CommonErrors.UnAuthorized();
        }
        IPikaMoon(_token).safeTransfer(_to, _value);
    }

    /**
     * @dev Changes the weight of the pool;
     *      executed by the pool itself or by the factory owner.
     *
     * @param pool address of the pool to change weight for
     * @param weight new weight value to set to
     */
    function changePoolWeight(address pool, uint256 weight) external onlyOwner {
        // recalculate total weight
        totalWeight = totalWeight + weight - ICorePool(pool).weight();

        // set the new pool weight
        ICorePool(pool).setWeight(weight);

        // emit an event
        emit LogChangePoolWeight(msg.sender, address(pool), weight);
    }


    /**
     * @dev Overrides `Ownable.renounceOwnership()`, to avoid accidentally
     *      renouncing ownership of the PoolControllers contract.
     */
    function renounceOwnership() public virtual override {}


    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeToAndCall}.
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}


     /**
     * @dev Empty reserved space in storage. The size of the __gap array is calculated so that
     *      the amount of storage used by a contract always adds up to the 50.
     *      See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}
