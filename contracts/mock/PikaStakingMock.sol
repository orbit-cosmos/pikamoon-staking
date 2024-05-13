// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../PikaStakingPool.sol";


interface IStaking {
    function transferRewardPIKA(address to,uint value) external;
}

contract PikaStakingPoolMock is PikaStakingPool,IStaking {
    uint256 public now256;

    function setNow256(uint256 __now256) external {
        now256 = __now256;
    }

    function _now256() internal view override returns (uint256) {
        return now256;
    }

    function transferRewardPIKA(address to,uint value) external{
        IPoolController(poolController).transferRewardTokens(rewardToken,to,value);
    }
}
    