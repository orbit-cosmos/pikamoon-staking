# Pikamoon Staking Smart contract

In staking, the user essentially locks up PIKA or PIKA-USDT LP tokens on platform for a certain period
of time in order to receive certain APY as return on their staked amount. The
rewards are accumulated based on their stake amount and locking duration. More amount
and longer staking duration yields better returns. For Pikahub, users can get highly attractive
yields better than most of the platforms but with a healthy reward emission and economy so
that the supply only grows proportional to the rise of demand. [Link to Pikahub](https://www.pikamoon.io/pikahub/staking)

# Types of Staking pools at Pikahub
## 1. $PIKA Direct Staking Pool
In this pool, users simply hold $PIKA in their wallets, and use the platform to lock and unlock
for a promised return. Direct Staking allows you to gain interest upon your investment during
the locking period. 
## 2. $PIKA-USDT LP Pool
Users who provide liquidity on Uniswap v2 get LP tokens in return as proof. These users can
then visit Pikahub and stake those LPs for comparatively higher (multifolds approx 4x) than
the Direct Staking pool rewarded for strengthening the ecosystem. Similar to direct staking,
users can choose the parameters of their liking and enjoy amazing yields.



# User Operations:

- User can stake $Pika/LP tokens.
    * Staking duration can be between 1 month to 12 months.
    * Each stake done will be treated as a new entry and previous stake cannot be altered such that reduced or increased.

- User can unstake $Pika/LP tokens. 
    * Un-staking can be done when staking duration ends for a specific entry resulting in entire stake for the specific entry to be retrieved from the contract.

- User can early un-stake $Pika/LP tokens.
    * Early un-staking can be done before staking duration ends for a specific entry resulting in calculated penalty according to time left being deducted and the remaining amount will be retrieved from the contract. The penalty will be send to the pool controller available for distribution to other stakers.
    * Early un-stake penalty ranges from 10% to 90% slash in staking amount.

- User can claim rewards in $Pika tokens.
    * The rewards will be calculated and will be available as time passes.
    * Rewards can be claimed only if they are verified by the backend to have contributed some effort e.g. playing the game, following socials, referring friends to stake. 
    * The backend decides how much effort was put in resulting in percentage of the claim to be rewarded. This will be achieved by using ECDSA signatures and verification on contract end.
    * There is going to be a cool-off period of 30 days between each reward claim.

- User can Re-stake rewards in $Pika tokens.
    * user can decide weather to re-stake all rewards or a portion. for direct staking the rewards are re-staked in pool itself however in the case of Lp staking pool, the rewards are re-staked in direct staking pool. 
    * user story where a user is eligible to claim 60% of the rewards the remaining 40% of the rewards can be either kept in the pool for further accumulation or re staked for a set period of time or re stake the whole 100% rewards altogether in the direct staking pool.
    * re-staking tokens will be staked for 1 year in direct staking pool..
  
# Admin Operations:

- Admin can Pause/unPause the Contract at any time.
- Admin can create/register staking pool.
- Admin can change Pool Weight.
- Admin can change Pika Per Second.
- Admin can set verification address for ECDSA claim functionality.
- Admin can add or remove logic from staking pools by upgrading the contract


# Mainnet & Testnet Address

- Mainnet
1. pool controller: 0x1cA441f054CCD878A3f9Dba4c35092fD1e07D17f
2. direct staking: 0xF965671DeC4C8f902083e8E0845cf86aac44FD80
3. lp staking: 0xFCf12ADF9Dc9967701596A12D1c7F5E447e34736
4. lp token: 0x43a68a9f1f234e639b142f0aba946b7add26418d 

- TestNet
1. direct staking: 0x42441756E08af5652727C7a7d0a9cBC989eeeA8d
2. lp staking: 0x3fD4AbD102E84459274b0afB409a432483F685CF
3. pool controller: 0xd622aAeCDC504B95041fE3556a4DB96f17D31919
4. lp token: 0x14a41eeDE0B188650796bcc02C9F2f53779B461d



