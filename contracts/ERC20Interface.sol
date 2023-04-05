// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ERC20Interface is IERC20 {
    function decimals() external returns (uint8);

    function symbol() external returns (string memory);
}
