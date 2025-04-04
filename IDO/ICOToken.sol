// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract icoToken is ERC20, ERC20Burnable, Ownable{

    constructor() ERC20("ICOToken", "ICOT") {

        _mint(msg.sender, 1000000000 * 10 ** decimals());
        
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
