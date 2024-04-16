// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ICorePool} from "./interfaces/ICorePool.sol";
import {CommonErrors} from "./libraries/Errors.sol";
import {IPikaMoon} from "./interfaces/IPikaMoon.sol";

contract PoolFactory is Initializable, UUPSUpgradeable, OwnableUpgradeable {
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
        __Ownable_init(_msgSender());
        __UUPSUpgradeable_init();
        pikaPerSecond = 25.3678335870 gwei;

        totalWeight = 1000; //(direct staking)200 + (pool staking)800
    }

    function registerPool(address _poolAddress) external onlyOwner {
        if (poolExists[_poolAddress]) {
            revert CommonErrors.AlreadyRegistered();
        }
        poolExists[_poolAddress] = true;
        emit LogRegisterPool(_poolAddress);
    }

    function updatePikaPerSecond(uint256 _pikaPerSecond) external onlyOwner {
        if (_pikaPerSecond == 0) revert CommonErrors.ZeroAmount();
        pikaPerSecond = _pikaPerSecond;
        emit LogUpdatePikaPerSecond(_pikaPerSecond);
    }
    function transferRewardTokens(
        address _token,
        address _to,
        uint256 _value
    ) public {
        if (!poolExists[_msgSender()]) {
            revert CommonErrors.AlreadyRegistered();
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
        emit LogChangePoolWeight(_msgSender(), address(pool), weight);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeToAndCall}.
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
