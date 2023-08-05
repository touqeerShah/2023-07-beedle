// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./utils/Errors.sol";
import "./utils/Structs.sol";

import {IERC20} from "./interfaces/IERC20.sol";

import {ISwapRouter} from "./interfaces/ISwapRouter.sol";

contract Fees {
    address public immutable WETH;
    address public immutable staking;

    // @audit-info address can be change over the time so don't hardcode it in code
    /// uniswap v3 router
    ISwapRouter public swapRouter;
    // @audit-info add event for better visibility fo final result

    event ProfitsSold(address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);

    constructor(address _weth, address _staking, address _swapRouter) {
        WETH = _weth;
        staking = _staking;
        swapRouter = ISwapRouter(_swapRouter);
    }

    /// @notice swap loan tokens for collateral tokens from liquidations
    /// @param _profits the token to swap for WETH
    function sellProfits(address _profits) public {
        require(_profits != address(0), "Invalid token address"); // Check if _profits is a valid address
        require(_profits != address(WETH), "Not allowed");
        uint256 amount = IERC20(_profits).balanceOf(address(this));

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: _profits,
            tokenOut: address(WETH),
            fee: 3000,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amount,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });
        try swapRouter.exactInputSingle(params) returns (uint256 amountOut) {
            amount = amountOut;
        } catch {
            revert("Token swap failed");
        }
        IERC20(WETH).transfer(staking, IERC20(WETH).balanceOf(address(this)));
        emit ProfitsSold(_profits, address(WETH), amount, IERC20(WETH).balanceOf(staking));
    }
}
