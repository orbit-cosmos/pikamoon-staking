// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
interface IPoolFactory {
    function owner() external view returns (address);

    function pikaPerSecond() external view returns (uint192);

    function totalWeight() external view returns (uint32);

    function secondsPerUpdate() external view returns (uint32);

    function endTime() external view returns (uint32);

    function lastRatioUpdate() external view returns (uint32);



   function shouldUpdateRatio() external view returns (bool);

    function updatePIKAPerSecond() external;
    function transferRewardTokens(address _token, address _to, uint256 _value) external;

 
    function changePoolWeight(address pool, uint32 weight) external;
}
