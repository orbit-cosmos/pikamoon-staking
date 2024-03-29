// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ICorePool} from "./interfaces/ICorePool.sol";
import {CommonErrors} from "./libraries/Errors.sol";
contract PoolFactory is Ownable {
    /**
     * @dev PIKA/second determines rewards farming reward base
     */
    uint256 public pikaPerSecond;
    /**
     * @dev The yield is distributed proportionally to pool weights;
     *      total weight is here to help in determining the proportion.
     */
    uint256 public totalWeight;

    /**
     * @dev Pika/second decreases by 3% every seconds/update
     *      an update is triggered by executing `updatePikaPerSecond` public function.
     */
    uint256 public secondsPerUpdate;

    /**
     * @dev End time is the last timestamp when Pika/second can be decreased;
     *      it is implied that yield farming stops after that timestamp.
     */
    uint256 public endTime;

    /**
     * @dev Each time the Pika/second ratio gets updated, the timestamp
     *      when the operation has occurred gets recorded into `lastRatioUpdate`.
     * @dev This timestamp is then used to check if seconds/update `secondsPerUpdate`
     *      has passed when decreasing yield reward by 3%.
     */
    uint256 public lastRatioUpdate;



    /**
     * @dev Fired in registerPool()
     *
     * @param by an address which executed an action
     * @param poolToken pool token address (like Pika)
     * @param poolAddress deployed pool instance address
     * @param weight pool weight
     * @param isFlashPool flag indicating if pool is a flash pool
     */
    event LogRegisterPool(
        address indexed by,
        address indexed poolToken,
        address indexed poolAddress,
        uint64 weight,
        bool isFlashPool
    );

    /**
     * @dev Fired in `changePoolWeight()`.
     *
     * @param by an address which executed an action
     * @param poolAddress deployed pool instance address
     * @param weight new pool weight
     */
    event LogChangePoolWeight(address indexed by, address indexed poolAddress, uint256 weight);

    /**
     * @dev Fired in `updatePikaPerSecond()`.
     *
     * @param by an address which executed an action
     * @param newPikaPerSecond new Pika/second value
     */
    event LogUpdatePikaPerSecond(address indexed by, uint256 newPikaPerSecond);

    /**
     * @dev Fired in `setEndTime()`.
     *
     * @param by an address which executed the action
     * @param endTime new endTime value
     */
    event LogSetEndTime(address indexed by, uint256 endTime);

    /**
     * @dev Initializes a factory instance
     *
   
     */

    constructor(

    )  Ownable(_msgSender()){
  

        pikaPerSecond = 0.0002 gwei;
        secondsPerUpdate = 14 days;
        lastRatioUpdate = block.timestamp;
        endTime = block.timestamp + (5 * 30 days); // 5 months
        totalWeight = 1000; //(direct staking)200 + (pool staking)800
         
    }


    /**
     * @dev Verifies if `secondsPerUpdate` has passed since last PIKA/second
     *      ratio update and if PIKA/second reward can be decreased by 3%.
     *
     * @return true if enough time has passed and `updatePIKAPerSecond` can be executed.
     */
    function shouldUpdateRatio() public view returns (bool) {
        // if rewards farming period has ended
        if (block.timestamp > endTime) {
            // PIKA/second reward cannot be updated anymore
            return false;
        }

        // check if seconds/update have passed since last update
        return block.timestamp >= lastRatioUpdate + secondsPerUpdate;
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
        lastRatioUpdate = block.timestamp;

        // emits an event
        emit LogUpdatePikaPerSecond(_msgSender(), pikaPerSecond);
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
     * @dev Updates rewards generation ending timestamp.
     *
     * @param _endTime new end time value to be stored
     */
    function setEndTimeForPikaPerSec(uint256 _endTime) external onlyOwner {
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

  
}
