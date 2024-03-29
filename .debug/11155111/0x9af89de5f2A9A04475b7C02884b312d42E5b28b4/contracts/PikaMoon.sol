// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {CommanErrors} from "./libraries/Errors.sol";

/**
 * @title PikaMoon Token
 * @dev A simple ERC20 token contract that allows minting and burning of tokens.
 */
contract PikaMoon is
    Initializable,
    ERC20CappedUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    //storage
    bytes32 private constant OWNER_ROLE = keccak256("OWNER_ROLE");
    uint32 public constant feeMultiply = 1000;
    uint16 constant public marketingTax = 10; 
    uint16 constant public ecosystemTax = 10; 
    uint16 constant public burnTax = 5; 
    address public ecoSystemWallet;
    address public marketingWallet;
    mapping(address => bool) public isExcludeFromTax;
    mapping(address => bool) public automatedMarketMakerPairs;

    bool public isTaxEnabled;

    // events
    event SetAutomatedMarketMakerPair(address pair, bool value);
    event ToggleTax(bool tax);
    event ExcludeFromTax(address _user, bool _isExcludeFromTax);
    event EventEcoSystemWallet(
        address ecoSystemWallet,
        address _ecoSystemWallet
    );
    event EventMarketingWallet(
        address marketingWallet,
        address _marketingWallet
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializer function to initialize the contract.
     * @param _name The name of the token.
     * @param _symbol The symbol of the token.
     * @param _ecosystemdevelopment ecosystem wallet.
     * @param _marketing marketing wallet.
     */
    function initialize(
        string memory _name, // Pikamoon
        string memory _symbol, // PIKA
        address _ecosystemdevelopment,
        address _marketing
    ) external initializer {
        __ERC20_init(_name, _symbol);
        __ERC20Capped_init(50_000_000_000 * 10 ** decimals());
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(OWNER_ROLE, _msgSender());
        _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);

        if (_ecosystemdevelopment == address(0)) {
            revert CommanErrors.ZeroAddress();
        }
        if (_marketing == address(0)) {
            revert CommanErrors.ZeroAddress();
        }

        isTaxEnabled = true;
       
        //set marketing and ecosystem wallet
        ecoSystemWallet = _ecosystemdevelopment;
        marketingWallet = _marketing;
        // exclude owner & this contract from tax
        isExcludeFromTax[address(this)] = true;
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeToAndCall}.
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(OWNER_ROLE) {}

    /**
     * @dev function for setting Automated MarketMaker Pair
     * @param pair address for pair.
     * @param value boolean true or false.
     */
    function setAutomatedMarketMakerPair(
        address pair,
        bool value
    ) external onlyRole(OWNER_ROLE) {
        _setAutomatedMarketMakerPair(pair, value);
    }

    /**
     * @dev private function for setting Automated MarketMaker Pair
     * @param pair address for pair.
     * @param value boolean true or false.
     */
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        if (automatedMarketMakerPairs[pair] == value) {
            revert CommanErrors.PairIsAlreadyGivenValue();
        }

        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
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
     * @dev Function for user to burn there balance.
     * @param amount The amount of tokens to be burned.
     */
    function burn(uint amount) external {
        // Call the internal _burn function from ERC20 to destroy tokens
        _burn(_msgSender(), amount);
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
        emit EventEcoSystemWallet(ecoSystemWallet, _ecoSystemWallet);
        ecoSystemWallet = _ecoSystemWallet;
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
        emit EventMarketingWallet(marketingWallet, _marketing);
        marketingWallet = _marketing;
    }

    /**
     * @dev Function to update isExcludeFromTax mapping to exclude or include From Tax
     * @param _user The address to be exclude or include From Tax
     * @param _isExcludeFromTax true or false
     */
    function excludeFromTax(
        address _user,
        bool _isExcludeFromTax
    ) external onlyRole(OWNER_ROLE) {
        isExcludeFromTax[_user] = _isExcludeFromTax;
        emit ExcludeFromTax(_user, _isExcludeFromTax);
    }

    /**
     * @dev Function to toggle tax
     */
    function toggleTax() external onlyRole(OWNER_ROLE) {
        isTaxEnabled = !isTaxEnabled;
        emit ToggleTax(isTaxEnabled);
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
    ) public override(ERC20Upgradeable) returns (bool) {
        (
            uint256 tax,
            uint256 burnAmount,
            uint256 marketingAmount,
            uint256 ecosystemAmount
        ) = calculateTax(_msgSender(), to, value);
        if (tax > 0) {
            unchecked {
                value -= tax;
            }

            // deduct tax
            if (marketingAmount > 0) {
                super._transfer(_msgSender(), marketingWallet, marketingAmount);
            }
            if (ecosystemAmount > 0) {
                super._transfer(_msgSender(), ecoSystemWallet, ecosystemAmount);
            }
            if (burnAmount > 0) {
                super._burn(_msgSender(), burnAmount);
            }
        }
        // normal transfer
        super._transfer(_msgSender(), to, value);
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
    ) public override(ERC20Upgradeable) returns (bool) {
        _spendAllowance(from, _msgSender(), value);
        (
            uint256 tax,
            uint256 burnAmount,
            uint256 marketingAmount,
            uint256 ecosystemAmount
        ) = calculateTax(from, to, value);
        if (tax > 0) {
            unchecked {
                value -= tax;
            }

            // deduct tax
            if (marketingAmount > 0) {
                super._transfer(from, marketingWallet, marketingAmount);
            }
            if (ecosystemAmount > 0) {
                super._transfer(from, ecoSystemWallet, ecosystemAmount);
            }
            if (burnAmount > 0) {
                super._burn(from, burnAmount);
            }
        }
        // normal transfer
        super._transfer(from, to, value);
        return true;
    }

    /**
     * @dev Function to calculate the tax
     * @param from address on which tax is applied
     * @param to address on which tax is applied
     * @param value amount on which tax is calculated
     */
    function calculateTax(
        address from,
        address to,
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
        if (
            isTaxEnabled &&
            !automatedMarketMakerPairs[from] &&
            !isExcludeFromTax[from] &&
            !isExcludeFromTax[to]
        ) {
            burnAmount = (value * burnTax) / feeMultiply;
            marketingAmount = (value * marketingTax) / feeMultiply;
            ecosystemAmount = (value * ecosystemTax) / feeMultiply;
            unchecked {
                tax = burnAmount + marketingAmount + ecosystemAmount;
            }
        }
    }
}
