// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20Capped} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
// import "hardhat/console.sol";
import {IPikaMoon, IERC20} from "./interfaces/IPikaMoon.sol";
import {CommanErrors} from "./libraries/Errors.sol";
import "./interfaces/IUniswapV2Router02.sol";

/**
 * @title PikaMoon Token
 * @dev A simple ERC20 token contract that allows minting and burning of tokens.
 */
contract PikaMoon is ERC20Capped, AccessControl, IPikaMoon {
    bytes32 private constant OWNER_ROLE = keccak256("OWNER_ROLE");
    address public ecoSystemWallet;
    address public marketingWallet;
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => bool) public isExcludeFromTax;
    uint16 public marketingTax = 10; // 1%
    uint16 public ecosystemTax = 10; // 1%
    uint16 public burnTax = 5; // 0.5%
    bool public isTaxEnabled = true;

    /**
     * @dev Constructor function to initialize the contract.
     * @param _name The name of the token.
     * @param _symbol The symbol of the token.
     * @param _cap Cap of token.
     * @param _ecosystemdevelopment ecosystem wallet.
     * @param _marketing marketing wallet.
     */
    constructor(
        string memory _name, // Pikamoon
        string memory _symbol, // PIKA
        uint _cap, // 50,000,000,000
        address _ecosystemdevelopment,
        address _marketing
    ) ERC20(_name, _symbol) ERC20Capped(_cap) {
        // grant deployer as  admin role
        _grantRole(OWNER_ROLE, _msgSender());
        //set owner role to default admin role
        _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
        // check for zero adderss
        if (_ecosystemdevelopment == address(0)) {
            revert CommanErrors.ZeroAddress();
        }
        if (_marketing == address(0)) {
            revert CommanErrors.ZeroAddress();
        }
        //set marketing and ecosystem wallet
        ecoSystemWallet = _ecosystemdevelopment;
        marketingWallet = _marketing;
        // exclude owner & this contract from tax
        isExcludeFromTax[address(this)] = true;



        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
        //     0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        // );
        // // set the rest of the contract variables
        // uniswapV2Router = _uniswapV2Router;
        // // Create a uniswap pair for this new token
        // uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        //     .createPair(address(this), _uniswapV2Router.WETH());

    }

    /**
     * @dev Function for initializing uniswap router and create pair.
     * @param _router address of router.
     */
    function initRouterAndPair(address _router) external onlyRole(OWNER_ROLE) {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            // 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
            _router
        );
        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
    }

    /**
     * @dev Function to get decimals.
     */
    function decimals() public pure override returns (uint8) {
        return 9;
    }

    /**
     * @dev Function to mint new tokens and assign them to a specified address.
     * @param to The address to which the new tokens are minted.
     * @param amount The amount of tokens to be minted.
     */
    function mint(address to, uint amount) external onlyRole(OWNER_ROLE) {
        // Call the internal _mint function from ERC20 to create new tokens
        _mint(to, amount);
    }

    /**
     * @dev Function to burn existing tokens from a specified owner's balance.
     * @param owner The address from which the tokens are burned.
     * @param amount The amount of tokens to be burned.
     */
    function burn(address owner, uint amount) external onlyRole(OWNER_ROLE) {
        // Call the internal _burn function from ERC20 to destroy tokens
        _burn(owner, amount);
    }

    /**
     * @dev Function to set ecosystem address.
     * @param _ecoSystemWallet The address to ecosystem wallet.
     */
    function changeEcoSystemWallet(
        address _ecoSystemWallet
    ) external onlyRole(OWNER_ROLE) {
        if (_ecoSystemWallet == address(0)) {
            revert CommanErrors.ZeroAddress();
        }
        assembly {
            sstore(ecoSystemWallet.slot, _ecoSystemWallet)
        }
    }

    /**
     * @dev Function to set marketing address.
     * @param _marketing The address to  marketing wallet.
     */
    function changeMarketingWallet(
        address _marketing
    ) external onlyRole(OWNER_ROLE) {
        if (_marketing == address(0)) {
            revert CommanErrors.ZeroAddress();
        }
        assembly {
            sstore(marketingWallet.slot, _marketing)
        }
    }

    /**
     * @dev Function to update isExcludeFromTax mapping to exclude or include From Tax
     * @param _user The address to be exclude or include From Tax
     * @param _isExcludeFromTax true or false
     */
    function excludeFromTax(address _user, bool _isExcludeFromTax) external {
        assembly {
            let ptr := mload(0x40) //free memory pointer

            mstore(ptr, _user)
            mstore(add(ptr, 0x20), isExcludeFromTax.slot)
            sstore(keccak256(ptr, 0x40), _isExcludeFromTax)
        }
    }

    /**
     * @dev Function to toggle tax
     */
    function toggleTax() external {
        // 1 or 0  = 1
        // 1 and 0 = 0
        assembly {
            let a := sload(isTaxEnabled.slot)
            let b := shr(mul(isTaxEnabled.offset, 8), a)
            switch b
            case 0 {
                let c := or(
                    a,
                    0x0000000000000000000000000000000000000000000000000001000000000000
                )
                sstore(isTaxEnabled.slot, c)
            }
            case 1 {
                let c := and(
                    a,
                    0x0000000000000000000000000000000000000000000000000000ffffffffffff
                )
                sstore(isTaxEnabled.slot, c)
            }
        }
    }

    /**
     * @dev Function to set Marketing Tax
     * @param _marketingTax tax value
     */
    function setMarketingTax(
        uint16 _marketingTax
    ) external onlyRole(OWNER_ROLE) {
        assembly {
            let a := sload(marketingTax.slot)
            let b := shr(mul(marketingTax.offset, 8), _marketingTax)
            let c := and(
                a,
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000
            )
            sstore(marketingTax.slot, or(c, b))
        }
    }

    /**
     * @dev Function to set EcoSystem Tax
     * @param _ecosystemTax tax value
     */
    function setEcoSystemTax(
        uint16 _ecosystemTax
    ) external onlyRole(OWNER_ROLE) {
        assembly {
            let a := sload(ecosystemTax.slot)
            let b := shl(mul(ecosystemTax.offset, 8), _ecosystemTax)
            let c := and(
                a,
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000ffff
            )
            sstore(ecosystemTax.slot, or(c, b))
        }
    }

    /**
     * @dev Function to set burn Tax
     * @param _burnTax tax value
     */
    function setBurnTax(uint16 _burnTax) external onlyRole(OWNER_ROLE) {
        assembly {
            let a := sload(burnTax.slot)
            let b := shl(mul(burnTax.offset, 8), _burnTax)
            let c := and(
                a,
                0xffffffffffffffffffffffffffffffffffffffffffffffffffff0000ffffffff
            )
            sstore(burnTax.slot, or(c, b))
        }
    }

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     * @param to The address to which the tokens are being transfered.
     * @param value The amount of tokens to be transfered.
     * @notice Pikamoon incorporates a small 2.5% transaction tax on Sell orders & Transfers.
     * There is NO buy Tax when purchasing $PIKA. The Pikamoon token is used to support our metaverse
     * and marketplace, therefore we want to reward hodlers of Pikamoon by punishing those leaving our ecosystem.
     * 1% of the tax will go towards marketing, 1% towards the ecosystem development fund / P2E Rewards
     * and 0.5% burned forever!
     */
    function transfer(
        address to,
        uint256 value
    ) public override(ERC20, IERC20) returns (bool) {
        (
            uint256 tax,
            uint256 burnAmount,
            uint256 marketingAmount,
            uint256 ecosystemAmount
        ) = calculateTax(_msgSender(), value);
        if (ecosystemAmount != 0 && marketingAmount != 0 && burnAmount != 0) {
            unchecked {
                value -= tax;
            }

            // deduct tax
            _transfer(_msgSender(), marketingWallet, marketingAmount);
            _transfer(_msgSender(), ecoSystemWallet, ecosystemAmount);
            _burn(_msgSender(), burnAmount);
        }
        // normal transfer
        super.transfer(to, value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     * @param from The address from which the tokens are being transfered.
     * @param to The address to which the tokens are being transfered.
     * @param value The amount of tokens to be transfered.
     * @notice Pikamoon incorporates a small 2.5% transaction tax on Sell orders & Transfers.
     * There is NO buy Tax when purchasing $PIKA. The Pikamoon token is used to support our metaverse
     * and marketplace, therefore we want to reward hodlers of Pikamoon by punishing those leaving our ecosystem.
     * 1% of the tax will go towards marketing, 1% towards the ecosystem development fund / P2E Rewards
     * and 0.5% burned forever!
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override(ERC20, IERC20) returns (bool) {
        _spendAllowance(from, _msgSender(), value);
        (
            uint256 tax,
            uint256 burnAmount,
            uint256 marketingAmount,
            uint256 ecosystemAmount
        ) = calculateTax(_msgSender(), value);
        if (ecosystemAmount != 0 && marketingAmount != 0 && burnAmount != 0) {
            unchecked {
                value -= tax;
            }

            // deduct tax
            _transfer(from, marketingWallet, marketingAmount);
            _transfer(from, ecoSystemWallet, ecosystemAmount);
            _burn(from, burnAmount);
        }
        // normal transfer
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Function to calculate the tax
     * @param msgSender address on which tax is applied
     * @param value amount on which tax is calculated
     */
    function calculateTax(
        address msgSender,
        uint256 value
    )
        public
        view
        returns (
            uint256 tax,
            uint256 burnAmount,
            uint256 marketingAmount,
            uint256 ecosystemAmount
        )
    {
        // calculate tax
        if (isTaxEnabled && !(isExcludeFromTax[msgSender])) {
            burnAmount = (value * burnTax) / 1000;
            marketingAmount = (value * marketingTax) / 1000;
            ecosystemAmount = (value * ecosystemTax) / 1000;
            unchecked {
                tax = burnAmount + marketingAmount + ecosystemAmount;
            }
        }
    }
      function swapTokensForETH(uint256 tokenAmount) private {
        // generate the pancake uniswapV2Pair path of token -> weth

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
}
