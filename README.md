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
    * Staking duration can be between 1 month to 12 months.
    * Each stake done will be treated as a new entry and previous stake cannot be altered such that reduced or increased.

- User can unstake. 
    * Un-staking can be done when staking duration ends for a specific entry resulting in entire stake for the specific entry to be retrieved from the contract.

- User can early unstake.
    * Early un-staking can be done before staking duration ends for a specific entry resulting in calculated penalty according to time left being deducted and the remaining amount will be retrieved from the contract. The penalty will be send to the pool controller available for distribution to other stakers.
    * Early un-stake penalty ranges from 10% to 90% slash in staking amount.

- User can claim rewards.
    * The rewards will be calculated and will be available as time passes.
    * Rewards can be claimed only if they are verified by the backend to have contributed some effort e.g. playing the game, following socials, referring friends to stake. 
    * The backend decides how much effort was put in resulting in percentage of the claim to be rewarded.
    * A user story where a user is eligible to claim 60% of the rewards the remaining 40% of the rewards can be either kept in the pool for further accumulation or re staked for a set period of time decided by the backend.
    * This will be achieved by using ECDSA signatures and verification on contract end.

# Admin Operations:

- Admin can Pause the Contract at any time.
- Admin can create/register staking pool.
- Admin can change Pool Weight.
- Admin can change Pika Per Second.
- Admin can set verification address for ECDSA claim functionality.


# Sepolia Address

pool controller = 0xd622aAeCDC504B95041fE3556a4DB96f17D31919
direct staking pool = 0x42441756E08af5652727C7a7d0a9cBC989eeeA8d
lp staking pool = 0x04810828935c2415c472C5adb3BA3BE9d8b2fE5C
LP TOKEN = 0x1b10cA433611878595250e8Fd340e5DEE8f8ccF0
PIKA TOKEN = 0x13E467DAda37B741a47fB8c03157d4C133A79d75 