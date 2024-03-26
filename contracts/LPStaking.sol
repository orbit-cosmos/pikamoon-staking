// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./CorePool.sol";

contract LPStaking is CorePool{
constructor(address _poolToken, uint256 _weight,address _stakingRewardAddress) CorePool( _poolToken,  _weight, _stakingRewardAddress){

}
}