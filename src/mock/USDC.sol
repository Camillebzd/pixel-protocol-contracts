// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract USDC is ERC20, Ownable, ERC20Permit {
    constructor(
        address initialOwner
    ) ERC20("USD Coin", "USDC") Ownable(initialOwner) ERC20Permit("USD Coin") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function decimals()
        public
        pure
        override(ERC20)
        returns (uint8)
    {
        return 6;
    }
}
