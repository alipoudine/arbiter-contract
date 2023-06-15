// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@balancer-labs/v2-interfaces/contracts/vault/IAsset.sol";
import "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";
import "@balancer-labs/v2-interfaces/contracts/vault/IFlashLoanRecipient.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "./IRegistery.sol";

contract MainArbiter is Ownable, IFlashLoanRecipient {
    using SafeMath for uint256;

    uint8 constant BALANCER = 0;
    uint8 constant UNISWAPV2 = 1;
    uint8 constant UNISWAPV3 = 2;
    uint8 constant DYDX = 3;
    uint8 constant CURVE = 4;
    uint8 constant KYBERSWAP = 5;
    uint8 constant ONEINCH = 6;
    uint8 constant SUSHISWAP = 7;

    IVault balancerVault;
    IUniswapV2Router01 uniswapV2Router;
    IUniswapV2Router01 sushiswapV2Router;
    ISwapRouter uniswapV3Router;
    IRegistery curveRegistery;

    struct SwapRequest {
        uint8 exchange;
        address tokenIn;
        address tokenOut;
        bytes extra;
    }

    constructor() {
        // "balancer"
        balancerVault = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
        // "uniswapv2"
        uniswapV2Router = IUniswapV2Router01(
            0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45
        );
        sushiswapV2Router = IUniswapV2Router01(
            0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
        );
        // "uniswapv3"
        uniswapV3Router = ISwapRouter(
            0xE592427A0AEce92De3Edee1F18E0157C05861564
        );
        // "curve"
        curveRegistery = IRegistery(0x2a426b3Bb4fa87488387545f15D01d81352732F9);
    }

    function withdrawToken(address token) external onlyOwner {
        IERC20 Token = IERC20(token);
        Token.transfer(owner(), Token.balanceOf(address(this)));
    }

    // balancer flashloan, networks: Ethereum, Polygon
    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory,
        bytes memory userData
    ) external override {
        require(_msgSender() == address(balancerVault), "not vault");

        swapsHandler(userData);

        for (uint8 i = 0; i < tokens.length; ++i) {
            IERC20 token = tokens[i];
            uint256 balance = token.balanceOf(address(this));
            uint256 amount = amounts[i];

            if (balance >= amount) {
                token.transfer(address(balancerVault), amount);
                token.transfer(owner(), balance.sub(amount));
            }
        }
    }

    function swapsHandler(bytes memory userData) internal {
        SwapRequest[] memory swaps = abi.decode(userData, (SwapRequest[]));

        for (uint256 i = 0; i < swaps.length; i++) {
            // if (swaps[i].exchange == BALANCER) {
            //     IERC20 tokenIn = IERC20(swaps[i].tokenIn);
            //     uint256 amountIn = tokenIn.balanceOf(address(this));

            //     require(
            //         tokenIn.approve(address(balancerVault), amountIn),
            //         "approve failed."
            //     );

            //     (
            //         bytes32 poolId,
            //         uint256 assetInIndex,
            //         uint256 assetOutIndex
            //     ) = abi.decode(swaps[i].extra, (bytes32, uint256, uint256));
            //     bytes memory empty;

            //     IVault.BatchSwapStep[]
            //         memory swapSteps = new IVault.BatchSwapStep[](1);

            //     swapSteps[0] = IVault.BatchSwapStep(
            //         poolId,
            //         assetInIndex,
            //         assetOutIndex,
            //         amountIn,
            //         empty
            //     );

            //     IAsset[] memory assets = new IAsset[](2);
            //     assets[0] = IAsset(swaps[i].tokenIn);
            //     assets[1] = IAsset(swaps[i].tokenOut);

            //     IVault.FundManagement memory funds = IVault.FundManagement(
            //         address(this),
            //         false,
            //         payable(address(this)),
            //         false
            //     );

            //     int256[] memory limits = new int256[](1);
            //     limits[0] = int256(amountIn);

            //     balancerVault.batchSwap(
            //         IVault.SwapKind.GIVEN_IN,
            //         swapSteps,
            //         assets,
            //         funds,
            //         limits,
            //         type(uint256).max
            //     );
            // } else 
            if (
                swaps[i].exchange == UNISWAPV2 || swaps[i].exchange == SUSHISWAP
            ) {

                IUniswapV2Router01 router;
                if(swaps[i].exchange == SUSHISWAP) {
                    router = sushiswapV2Router;
                } else {
                    router = uniswapV2Router;
                }

                IERC20 tokenIn = IERC20(swaps[i].tokenIn);
                uint256 amountIn = tokenIn.balanceOf(address(this));
                uint256 amountOutMin = abi.decode(swaps[i].extra, (uint256));

                require(
                    tokenIn.approve(address(router), amountIn),
                    "approve failed."
                );

                address[] memory path = new address[](2);
                path[0] = swaps[i].tokenIn;
                path[1] = swaps[i].tokenOut;

                router.swapExactTokensForTokens(
                    amountIn,
                    amountOutMin,
                    path,
                    address(this),
                    type(uint256).max
                );
            } else if (swaps[i].exchange == UNISWAPV3) {
                IERC20 tokenIn = IERC20(swaps[i].tokenIn);
                uint256 amountIn = tokenIn.balanceOf(address(this));
                uint24 poolFee = abi.decode(swaps[i].extra, (uint24));

                require(
                    tokenIn.approve(address(uniswapV3Router), amountIn),
                    "approve failed."
                );

                ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
                    .ExactInputSingleParams({
                        tokenIn: swaps[i].tokenIn,
                        tokenOut: swaps[i].tokenOut,
                        fee: poolFee,
                        recipient: address(this),
                        deadline: block.timestamp,
                        amountIn: amountIn,
                        amountOutMinimum: 0,
                        sqrtPriceLimitX96: 0
                    });

                uniswapV3Router.exactInputSingle(params);
            } else if (swaps[i].exchange == CURVE) {
                IERC20 tokenIn = IERC20(swaps[i].tokenIn);
                uint256 _amount = tokenIn.balanceOf(address(this));
                address _pool = abi.decode(swaps[i].extra, (address));

                require(
                    tokenIn.approve(address(curveRegistery), _amount),
                    "approve failed."
                );

                uint256 _expected = curveRegistery.get_exchange_amount(
                    _pool,
                    swaps[i].tokenIn,
                    swaps[i].tokenOut,
                    _amount
                );

                curveRegistery.exchange(
                    _pool,
                    swaps[i].tokenIn,
                    swaps[i].tokenOut,
                    _amount,
                    _expected.div(2)
                );
            }
        }
    }

    function arbitRequest(
        uint8 loanProvider,
        address loanToken,
        uint256 loanAmount,
        bytes memory swapsData
    ) external onlyOwner {
        if (loanProvider == BALANCER) {
            IERC20[] memory loanTokens = new IERC20[](1);
            loanTokens[0] = IERC20(loanToken);

            uint256[] memory loanAmounts = new uint256[](1);
            loanAmounts[0] = loanAmount;

            balancerVault.flashLoan(
                IFlashLoanRecipient(address(this)),
                loanTokens,
                loanAmounts,
                swapsData
            );
        }
    }
}
