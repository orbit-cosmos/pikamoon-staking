// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20Capped} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import {IPikaMoon, IERC20} from "./interfaces/IPikaMoon.sol";
import {CommanErrors} from "./libraries/Errors.sol";

/**
 * @title PikaMoon Token
 * @dev A simple ERC20 token contract that allows minting and burning of tokens.
 */
contract PikaMoon is ERC20Capped, AccessControl, IPikaMoon {
    bytes32 private constant OWNER_ROLE = keccak256("OWNER_ROLE");
    address public ecosystemdevelopment;
    address public marketing;
    mapping(address => bool) public isExcludeFromTax;
    uint16 public marketingTax = 10; // 1%
    uint16 public ecosystemTax = 10; // 1%
    uint16 public burnTax = 5; // 0.5%
    bool public isTaxEnabled = true;

    /**
     * @dev Constructor function to initialize the contract.
     * @param name The name of the token.
     * @param symbol The symbol of the token.
     */
    constructor(
        string memory name, // PikaMoon
        string memory symbol, // PIKA
        uint _cap, // 50,000,000,000
        address _ecosystemdevelopment,
        address _marketing
    ) ERC20(name, symbol) ERC20Capped(_cap) {
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
        ecosystemdevelopment = _ecosystemdevelopment;
        marketing = _marketing;
        // exclude owner from tax
        isExcludeFromTax[_msgSender()] = true;
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
     * @dev Function to exclude or include From Tax
     * @param _user The address to be exclude or include From Tax
     * @param _isExcludeFromTax true or false
     */
    function excludeFromTax(
        address _user,
        bool _isExcludeFromTax
    ) external onlyRole(OWNER_ROLE) {
        if (_user == address(0)) {
            revert CommanErrors.ZeroAddress();
        }
        isExcludeFromTax[_user] = _isExcludeFromTax;
    }

    /**
     * @dev Function to toggle tax
     */
    function toggleTax() external onlyRole(OWNER_ROLE) {
        isTaxEnabled = !isTaxEnabled;
    }

    /**
     * @dev Function to set Marketing Tax
     * @param _marketingTax tax value
     */
    function setMarketingTax(
        uint16 _marketingTax
    ) external onlyRole(OWNER_ROLE) {
        marketingTax = _marketingTax; 
    }

    /**
     * @dev Function to set EcoSystem Tax
     * @param _ecosystemTax tax value
     */
    function setEcoSystemTax(
        uint16 _ecosystemTax
    ) external onlyRole(OWNER_ROLE) {
        ecosystemTax = _ecosystemTax; 
    }

    /**
     * @dev Function to set burn Tax
     * @param _burnTax tax value
     */
    function setBurnTax(uint16 _burnTax) external onlyRole(OWNER_ROLE) {
        burnTax = _burnTax; 
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
        uint finalAmount = value;
        if (isTaxEnabled && !(isExcludeFromTax[_msgSender()])) {
            // calculate tax
            uint tax;
            uint burnAmount = (value * burnTax) / 1000;
            uint marketingAmount = (value * marketingTax) / 1000;
            uint ecosystemAmount = (value * ecosystemTax) / 1000;
            unchecked {
                tax = burnAmount + marketingAmount + ecosystemAmount;
                finalAmount -= tax;
            }

            // deduct tax
            _transfer(_msgSender(), marketing, marketingAmount);
            _transfer(_msgSender(), ecosystemdevelopment, ecosystemAmount);
            _burn(_msgSender(), burnAmount);
        }
        // normal transfer
        super.transfer(to, finalAmount);
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
        uint finalAmount = value;
        if (isTaxEnabled && !(isExcludeFromTax[from])) {
            // calculate tax
            uint tax;
            uint burnAmount = (value * burnTax) / 1000;
            uint marketingAmount = (value * marketingTax) / 1000;
            uint ecosystemAmount = (value * ecosystemTax) / 1000;
            unchecked {
                tax = burnAmount + marketingAmount + ecosystemAmount;
                finalAmount -= tax;
            }

            // deduct tax
            _transfer(from, marketing, marketingAmount);
            _transfer(from, ecosystemdevelopment, ecosystemAmount);
            _burn(from, burnAmount);
        }
        // normal transfer
        _transfer(from, to, finalAmount);
        return true;
    }
}
