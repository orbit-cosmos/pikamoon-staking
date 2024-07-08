// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20Capped} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
/**
 * @title WrappedToken
 * @dev A simple ERC20 token contract that allows minting and burning of tokens.
 *      This contract is used to represent assets on a blockchain in a wrapped form.
 */
contract Token is ERC20Capped,AccessControl {
   bytes32 private constant OWNER_ROLE = keccak256("OWNER_ROLE");
    /**
     * @dev Constructor function to initialize the WrappedToken contract.
     * @param name The name of the token.
     * @param symbol The symbol of the token.
     */
    constructor(string memory name, string memory symbol,uint _cap) 
    ERC20(name, symbol) ERC20Capped(_cap){
        _grantRole(OWNER_ROLE, msg.sender);
        _setRoleAdmin(OWNER_ROLE,OWNER_ROLE);
    }

    /**
     * @dev Function to mint new tokens and assign them to a specified address.
     * @param to The address to which the new tokens are minted.
     * @param amount The amount of tokens to be minted.
     */
    function mint(address to, uint amount) external onlyRole(OWNER_ROLE){
        
        // Call the internal _mint function from ERC20 to create new tokens
        _mint(to, amount);
    }

    /**
     * @dev Function to burn existing tokens from a specified owner's balance.
     * @param owner The address from which the tokens are burned.
     * @param amount The amount of tokens to be burned.
     */
    function burn(address owner, uint amount) external onlyRole(OWNER_ROLE){
        // Call the internal _burn function from ERC20 to destroy tokens
        _burn(owner, amount);
    }



    
}
