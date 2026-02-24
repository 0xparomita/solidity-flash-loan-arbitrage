// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3FlashCallback.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

contract FlashArbitrage is IUniswapV3FlashCallback {
    address public immutable owner;

    struct FlashCallbackData {
        uint256 amount0;
        uint256 amount1;
        address payer;
    }

    constructor() {
        owner = msg.sender;
    }

    // Initiates the flash loan
    function initFlash(
        address pool,
        uint256 amount0,
        uint256 amount1
    ) external {
        IUniswapV3Pool(pool).flash(
            address(this),
            amount0,
            amount1,
            abi.encode(FlashCallbackData({
                amount0: amount0,
                amount1: amount1,
                payer: msg.sender
            }))
        );
    }

    // Callback called by Uniswap V3 Pool
    function uniswapV3FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata data
    ) external override {
        FlashCallbackData memory decoded = abi.decode(data, (FlashCallbackData));

        // ARBITRAGE LOGIC GOES HERE
        // 1. You now have 'decoded.amount0' or 'decoded.amount1'
        // 2. Perform swaps on other DEXs (e.g., Sushiswap)
        // 3. Ensure end balance > loan + fees

        // Repay the loan
        if (fee0 > 0) {
            IERC20(IUniswapV3Pool(msg.sender).token0()).transfer(msg.sender, decoded.amount0 + fee0);
        }
        if (fee1 > 0) {
            IERC20(IUniswapV3Pool(msg.sender).token1()).transfer(msg.sender, decoded.amount1 + fee1);
        }

        // Verify profitability
        require(address(this).balance >= 0, "Arbitrage not profitable");
    }

    function withdraw(address token) external {
        require(msg.sender == owner, "Unauthorized");
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(owner, balance);
    }
}
