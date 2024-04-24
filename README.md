# Pikamoon Staking Smart contract

This project is about pikamoon staking smart contract. 

# Scope:

- CorePool.sol
- PikaStakingPool.sol
- PoolController.sol
- libraries/Errors.sol
- libraries/Stake.sol
- interfaces/ICorePool.sol
- interfaces/IPikaMoon.sol
- interfaces/IPoolController.sol

# User Operations:

- User can stake Pikamoon tokens and get Pikamoon tokens in rewards.
- User can unstake or early unstake.
- In case of early unstake, user will pay penalty.
- User can claim rewards right after stake.
- User can choose to claim partial reward and restake the remaining rewards.

# Admin Operations:

- Admin can Pause the Contract at any time.
- Admin can create/register staking pool.
- Admin can change Pool Weight.
- Admin can change Pika Per Second.
