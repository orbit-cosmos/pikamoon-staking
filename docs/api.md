# Solidity API

## IRouter

### factory

```solidity
function factory() external pure returns (address)
```

### WETH

```solidity
function WETH() external pure returns (address)
```

### swapExactTokensForTokensSupportingFeeOnTransferTokens

```solidity
function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] path, address to, uint256 deadline) external
```

### addLiquidityETH

```solidity
function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity)
```

### swapExactTokensForETHSupportingFeeOnTransferTokens

```solidity
function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] path, address to, uint256 deadline) external
```

### addLiquidity

```solidity
function addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external returns (uint256 amountA, uint256 amountB, uint256 liquidity)
```

### swapExactETHForTokensSupportingFeeOnTransferTokens

```solidity
function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256 amountOutMin, address[] path, address to, uint256 deadline) external payable
```

### getAmountsOut

```solidity
function getAmountsOut(uint256 amountIn, address[] path) external view returns (uint256[] amounts)
```

### getAmountsIn

```solidity
function getAmountsIn(uint256 amountOut, address[] path) external view returns (uint256[] amounts)
```

## IToken

### mint

```solidity
function mint(address to, uint256 amount) external
```

### transfer

```solidity
function transfer(address to, uint256 value) external returns (bool)
```

### balanceOf

```solidity
function balanceOf(address account) external view returns (uint256)
```

### burn

```solidity
function burn(address owner, uint256 amount) external
```

## Presale

_A smart contract for conducting an Initial Coin Offering (ICO)_

### token

```solidity
contract IToken token
```

### activePhase

```solidity
uint256 activePhase
```

### marketingWallet

```solidity
address marketingWallet
```

### AddPhase

```solidity
struct AddPhase {
  uint256 roundId;
  uint256 maxTokens;
  uint256 tokenPriceInUsd;
  uint256 claimStart;
}
```

### Phase

```solidity
struct Phase {
  uint256 roundId;
  uint256 maxTokens;
  uint256 tokensSold;
  uint256 fundsRaisedEth;
  uint256 tokenPriceInUsd;
  uint256 claimStart;
  bool saleStatus;
}
```

### phase

```solidity
mapping(uint256 => struct Presale.Phase) phase
```

### deservedAmount

```solidity
mapping(address => mapping(uint256 => uint256)) deservedAmount
```

### claimedAmount

```solidity
mapping(address => mapping(uint256 => uint256)) claimedAmount
```

### depositEth

```solidity
mapping(address => mapping(uint256 => uint256)) depositEth
```

### Withdrawal

```solidity
event Withdrawal(address account, uint256 ethAmount)
```

### Invest

```solidity
event Invest(address account, uint256 ethAmount, uint256 tokenAmount)
```

### Claim

```solidity
event Claim(address account, uint256 tokenAmount)
```

### constructor

```solidity
constructor(address _router, address _USDT, contract IToken _token) public payable
```

_Constructor to initialize ICO parameters_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _router | address | address of uniswap router v2 |
| _USDT | address | Address of the USDT stable coin |
| _token | contract IToken | Address of the ICO token |

### addPhases

```solidity
function addPhases(struct Presale.AddPhase[] _addPhase) external
```

_Function to add Phases_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _addPhase | struct Presale.AddPhase[] | an  array for phases |

### getPhases

```solidity
function getPhases(uint256[] _roundId) public view returns (struct Presale.Phase[])
```

_Function to get Phases_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct Presale.Phase[] | Array for phases |

### updatePhaseClaimTime

```solidity
function updatePhaseClaimTime(uint256 _roundId, uint256 _startTime) external
```

_Function to update Phase claim time_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _roundId | uint256 | integer for identifying phase |
| _startTime | uint256 | time when claim is alowed |

### setActivePhase

```solidity
function setActivePhase(uint256 _roundId) external
```

_Function to update activePhase state variable_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _roundId | uint256 | integer for identifying phase |

### estimatedToken

```solidity
function estimatedToken(uint256 _weiAmount) public view returns (uint256)
```

_Function to estimate number of tokens agains eth_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | number of tokens |

### invest

```solidity
function invest() public payable
```

_Function to allow investors to contribute funds to the ICO_

### claim

```solidity
function claim(uint256 _currentPhase) external
```

_Function for claiming tokens for specific phase_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _currentPhase | uint256 | integer for identifying phase |

### claimAll

```solidity
function claimAll(uint256[] _phases) external
```

_Function for claiming tokens for all phase pass in the array_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _phases | uint256[] | array of phase id's |

### withdraw

```solidity
function withdraw() external
```

_Function for the owner to withdraw funds from the ICO contract_

### changeTokenAddress

```solidity
function changeTokenAddress(contract IToken newTokenAddress) external
```

_Function for the owner to change the ICO token address_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newTokenAddress | contract IToken | Address of the new ICO token |

### setMarketingAddress

```solidity
function setMarketingAddress(address _marketingAddress) external
```

_Function for the owner to set marketing address_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _marketingAddress | address | Address of the new ICO token |

### withdrawTokens

```solidity
function withdrawTokens() external
```

_Function for withdrawing Tokens in case of emergency or after presale is over_

### receive

```solidity
receive() external payable
```

_Fallback function to receive funds_

## Token

_A simple ERC20 token contract that allows minting and burning of tokens.
     This contract is used to represent assets on a blockchain in a wrapped form._

### constructor

```solidity
constructor(string name, string symbol, uint256 _cap) public
```

_Constructor function to initialize the WrappedToken contract._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| name | string | The name of the token. |
| symbol | string | The symbol of the token. |
| _cap | uint256 |  |

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
function burn(address owner, uint256 amount) external
```

_Function to burn existing tokens from a specified owner's balance._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| owner | address | The address from which the tokens are burned. |
| amount | uint256 | The amount of tokens to be burned. |

## CommanErrors

_This smart contract defines custom errors that can be thrown during specific conditions in other contracts._

### ZeroAmount

```solidity
error ZeroAmount()
```

### TransferFailed

```solidity
error TransferFailed()
```

### ZeroAddress

```solidity
error ZeroAddress()
```

### WithdrawFailed

```solidity
error WithdrawFailed()
```

### ExceedMaxTokens

```solidity
error ExceedMaxTokens()
```

### PhaseIsNotActive

```solidity
error PhaseIsNotActive()
```

### ClaimingNotStartedYet

```solidity
error ClaimingNotStartedYet()
```

### ThereIsNoReward

```solidity
error ThereIsNoReward()
```

## IERC20

### totalSupply

```solidity
function totalSupply() external view returns (uint256)
```

### balanceOf

```solidity
function balanceOf(address account) external view returns (uint256)
```

### transfer

```solidity
function transfer(address recipient, uint256 amount) external returns (bool)
```

### allowance

```solidity
function allowance(address owner, address spender) external view returns (uint256)
```

### approve

```solidity
function approve(address spender, uint256 amount) external returns (bool)
```

### transferFrom

```solidity
function transferFrom(address sender, address recipient, uint256 amount) external returns (bool)
```

### Transfer

```solidity
event Transfer(address from, address to, uint256 value)
```

### Approval

```solidity
event Approval(address owner, address spender, uint256 value)
```

### mint

```solidity
function mint(uint256 amount) external returns (bool)
```

### burn

```solidity
function burn(uint256 amount) external returns (bool)
```

## IERC20Permit

### permit

```solidity
function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external
```

### nonces

```solidity
function nonces(address owner) external view returns (uint256)
```

### DOMAIN_SEPARATOR

```solidity
function DOMAIN_SEPARATOR() external view returns (bytes32)
```

## IRouter

### factory

```solidity
function factory() external pure returns (address)
```

### WETH

```solidity
function WETH() external pure returns (address)
```

### swapExactTokensForTokensSupportingFeeOnTransferTokens

```solidity
function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] path, address to, uint256 deadline) external
```

### addLiquidityETH

```solidity
function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity)
```

### swapExactTokensForETHSupportingFeeOnTransferTokens

```solidity
function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] path, address to, uint256 deadline) external
```

### addLiquidity

```solidity
function addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external returns (uint256 amountA, uint256 amountB, uint256 liquidity)
```

### swapExactETHForTokensSupportingFeeOnTransferTokens

```solidity
function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256 amountOutMin, address[] path, address to, uint256 deadline) external payable
```

### getAmountsOut

```solidity
function getAmountsOut(uint256 amountIn, address[] path) external view returns (uint256[] amounts)
```

### getAmountsIn

```solidity
function getAmountsIn(uint256 amountOut, address[] path) external view returns (uint256[] amounts)
```

## SafeMath

### tryAdd

```solidity
function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256)
```

### trySub

```solidity
function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256)
```

### tryMul

```solidity
function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256)
```

### tryDiv

```solidity
function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256)
```

### tryMod

```solidity
function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256)
```

### add

```solidity
function add(uint256 a, uint256 b) internal pure returns (uint256)
```

### sub

```solidity
function sub(uint256 a, uint256 b) internal pure returns (uint256)
```

### mul

```solidity
function mul(uint256 a, uint256 b) internal pure returns (uint256)
```

### div

```solidity
function div(uint256 a, uint256 b) internal pure returns (uint256)
```

### mod

```solidity
function mod(uint256 a, uint256 b) internal pure returns (uint256)
```

### sub

```solidity
function sub(uint256 a, uint256 b, string errorMessage) internal pure returns (uint256)
```

### div

```solidity
function div(uint256 a, uint256 b, string errorMessage) internal pure returns (uint256)
```

### mod

```solidity
function mod(uint256 a, uint256 b, string errorMessage) internal pure returns (uint256)
```

## Address

### isContract

```solidity
function isContract(address account) internal view returns (bool)
```

### sendValue

```solidity
function sendValue(address payable recipient, uint256 amount) internal
```

### functionCall

```solidity
function functionCall(address target, bytes data) internal returns (bytes)
```

### functionCall

```solidity
function functionCall(address target, bytes data, string errorMessage) internal returns (bytes)
```

### functionCallWithValue

```solidity
function functionCallWithValue(address target, bytes data, uint256 value) internal returns (bytes)
```

### functionCallWithValue

```solidity
function functionCallWithValue(address target, bytes data, uint256 value, string errorMessage) internal returns (bytes)
```

### functionStaticCall

```solidity
function functionStaticCall(address target, bytes data) internal view returns (bytes)
```

### functionStaticCall

```solidity
function functionStaticCall(address target, bytes data, string errorMessage) internal view returns (bytes)
```

### functionDelegateCall

```solidity
function functionDelegateCall(address target, bytes data) internal returns (bytes)
```

### functionDelegateCall

```solidity
function functionDelegateCall(address target, bytes data, string errorMessage) internal returns (bytes)
```

### verifyCallResultFromTarget

```solidity
function verifyCallResultFromTarget(address target, bool success, bytes returndata, string errorMessage) internal view returns (bytes)
```

### verifyCallResult

```solidity
function verifyCallResult(bool success, bytes returndata, string errorMessage) internal pure returns (bytes)
```

## SafeERC20

### safeTransfer

```solidity
function safeTransfer(contract IERC20 token, address to, uint256 value) internal
```

### safeTransferFrom

```solidity
function safeTransferFrom(contract IERC20 token, address from, address to, uint256 value) internal
```

### safeApprove

```solidity
function safeApprove(contract IERC20 token, address spender, uint256 value) internal
```

### safeIncreaseAllowance

```solidity
function safeIncreaseAllowance(contract IERC20 token, address spender, uint256 value) internal
```

### safeDecreaseAllowance

```solidity
function safeDecreaseAllowance(contract IERC20 token, address spender, uint256 value) internal
```

### safePermit

```solidity
function safePermit(contract IERC20Permit token, address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) internal
```

## Context

### _msgSender

```solidity
function _msgSender() internal view returns (address)
```

### _msgData

```solidity
function _msgData() internal view returns (bytes)
```

## Ownable

### OwnershipTransferred

```solidity
event OwnershipTransferred(address previousOwner, address newOwner)
```

### constructor

```solidity
constructor() public
```

_Initializes the contract setting the deployer as the initial owner._

### owner

```solidity
function owner() public view returns (address)
```

_Returns the address of the current owner._

### onlyOwner

```solidity
modifier onlyOwner()
```

_Throws if called by any account other than the owner._

### transferOwnership

```solidity
function transferOwnership(address newOwner) public
```

_Transfers ownership of the contract to a new account (`newOwner`).
Can only be called by the current owner._

### _transferOwnership

```solidity
function _transferOwnership(address newOwner) internal
```

_Transfers ownership of the contract to a new account (`newOwner`)._

## TestPikamoonPresale

### Phase

```solidity
struct Phase {
  uint256 roundId;
  uint256 maxTokens;
  uint256 tokensSold;
  uint256 fundsRaisedEth;
  uint256 tokenPriceInUsd;
  uint256 claimStart;
  bool saleStatus;
}
```

### AddPhase

```solidity
struct AddPhase {
  uint256 roundId;
  uint256 maxTokens;
  uint256 tokenPriceInUsd;
  uint256 claimStart;
}
```

### phase

```solidity
mapping(uint256 => struct TestPikamoonPresale.Phase) phase
```

### deservedAmount

```solidity
mapping(address => mapping(uint256 => uint256)) deservedAmount
```

### claimedAmount

```solidity
mapping(address => mapping(uint256 => uint256)) claimedAmount
```

### depositEth

```solidity
mapping(address => mapping(uint256 => uint256)) depositEth
```

### marketingWallet

```solidity
address marketingWallet
```

### partnershipEthAmount

```solidity
uint256 partnershipEthAmount
```

### marketingClaimedEth

```solidity
uint256 marketingClaimedEth
```

### isWhitelistPresale

```solidity
bool isWhitelistPresale
```

### tokenAddress

```solidity
address tokenAddress
```

### USDT

```solidity
address USDT
```

### router

```solidity
contract IRouter router
```

### activePhase

```solidity
uint256 activePhase
```

### discountRate

```solidity
uint256 discountRate
```

### addPhases

```solidity
function addPhases(struct TestPikamoonPresale.AddPhase[] _addPhase) external
```

### getPhases

```solidity
function getPhases(uint256[] _roundId) public view returns (struct TestPikamoonPresale.Phase[])
```

### updatePhaseClaimTime

```solidity
function updatePhaseClaimTime(uint256 _roundId, uint256 _startTime) external
```

### setActivePhase

```solidity
function setActivePhase(uint256 _roundId) external
```

### currentTimestamp

```solidity
function currentTimestamp() public view returns (uint256)
```

### buyTokensEth

```solidity
function buyTokensEth() public payable
```

### claim

```solidity
function claim(uint256 _currentPhase) external
```

### claimAll

```solidity
function claimAll(uint256[] _phases) external
```

### estimatedToken

```solidity
function estimatedToken(uint256 _weiAmount) public view returns (uint256)
```

### constructor

```solidity
constructor(address _router, address _USDT) public
```

### setToken

```solidity
function setToken(address _token) external
```

### receive

```solidity
receive() external payable
```

### setWhiteListPresale

```solidity
function setWhiteListPresale(bool _flag) external
```

### withdrawTokens

```solidity
function withdrawTokens() external
```

### usdToEth

```solidity
function usdToEth(uint256 _amount) public view returns (uint256)
```

### withdrawETH

```solidity
function withdrawETH() external
```

### getStuckToken

```solidity
function getStuckToken(address _tokenAddress) external
```

