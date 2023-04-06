// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@gridexprotocol/core/contracts/interfaces/IGrid.sol";
import "@gridexprotocol/core/contracts/interfaces/IGridFactory.sol";
import "@gridexprotocol/core/contracts/libraries/GridAddress.sol";
import "@gridexprotocol/core/contracts/libraries/BoundaryMath.sol";
import "./interfaces/IMakerOrderManager.sol";

contract MakerOrder {
    // For the scope of these swap examples,
    // we will detail the design considerations when using `placeMakerOrder` for addressA and addressB.
    // It should be noted that for the sake of these examples we pass in the maker order manager as a constructor argument instead of inheriting it.
    // More advanced example contracts will detail how to inherit the maker order manager safely.

    IMakerOrderManager public immutable makerOrderManager;

    // address public constant WETH9 = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    // address public constant USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address addressA;
    address addressB;
    int24 public constant RESOLUTION = 5;

    constructor(
        IMakerOrderManager _makerOrderManager,
        address _addressA,
        address _addressB
    ) {
        makerOrderManager = _makerOrderManager;
        addressA = _addressA;
        addressB = _addressB;
    }

    /// @notice place a maker order for addressA
    /// @param amount The amount of addressA to place a maker order
    /// @return orderId The id of the maker order

    function placeMakerOrderForAddressA(
        uint128 amount
    ) external returns (uint256 orderId) {
        // msg.sender MUST approve the contract to spend the input token

        // transfer the specified amount of addressA to this contract
        SafeERC20.safeTransferFrom(
            IERC20(addressA),
            msg.sender,
            address(this),
            amount
        );

        // approve the maker order manager to spend addressA
        SafeERC20.safeApprove(
            IERC20(addressA),
            address(makerOrderManager),
            amount
        );

        // compute grid address
        address gridAddress = GridAddress.computeAddress(
            makerOrderManager.gridFactory(),
            GridAddress.gridKey(addressA, addressB, RESOLUTION)
        );

        IGrid grid = IGrid(gridAddress);

        (, int24 boundary, , ) = grid.slot0();
        // for this example, we will place a maker order at the current lower boundary of the grid

        int24 boundaryLower = BoundaryMath.getBoundaryLowerAtBoundary(
            boundary,
            RESOLUTION
        );
        IMakerOrderManager.PlaceOrderParameters memory parameters = IMakerOrderManager
            .PlaceOrderParameters({
                deadline: block.timestamp,
                recipient: address(this),
                tokenA: addressA,
                tokenB: addressB,
                resolution: RESOLUTION,
                zero: grid.token0() == addressA, // token0 is addressA or not
                boundaryLower: boundaryLower,
                amount: amount
            });

        orderId = makerOrderManager.placeMakerOrder(parameters);
    }

    /// @notice place a maker order for addressB
    /// @param amount The amount of addressB to place a maker order
    /// @return orderId The id of the maker order

    function placeMakerOrderForAddressB(
        uint128 amount
    ) external returns (uint256 orderId) {
        // msg.sender MUST approve the contract to spend the input token

        // transfer the specified amount of addressB to this contract
        SafeERC20.safeTransferFrom(
            IERC20(addressB),
            msg.sender,
            address(this),
            amount
        );

        // approve the maker order manager to spend addressB
        SafeERC20.safeApprove(
            IERC20(addressB),
            address(makerOrderManager),
            amount
        );

        // compute grid address
        address gridAddress = GridAddress.computeAddress(
            makerOrderManager.gridFactory(),
            GridAddress.gridKey(addressA, addressB, RESOLUTION)
        );

        IGrid grid = IGrid(gridAddress);

        (, int24 boundary, , ) = grid.slot0();
        // for this example, we will place a maker order at the current lower boundary of the grid
        int24 boundaryLower = BoundaryMath.getBoundaryLowerAtBoundary(
            boundary,
            RESOLUTION
        );

        IMakerOrderManager.PlaceOrderParameters memory parameters = IMakerOrderManager
            .PlaceOrderParameters({
                deadline: block.timestamp,
                recipient: address(this),
                tokenA: addressA,
                tokenB: addressB,
                resolution: RESOLUTION,
                zero: grid.token0() == addressB, // token0 is addressB or not
                boundaryLower: boundaryLower,
                amount: amount
            });

        orderId = makerOrderManager.placeMakerOrder(parameters);
    }

    /// @notice settle and collect the maker order

    function settleAndCollect(
        uint256 orderId
    ) external returns (uint128 amount0, uint128 amount1) {
        // compute grid address
        address gridAddress = GridAddress.computeAddress(
            makerOrderManager.gridFactory(),
            GridAddress.gridKey(addressA, addressB, RESOLUTION)
        );

        (amount0, amount1) = IGrid(gridAddress).settleMakerOrderAndCollect(
            msg.sender,
            orderId,
            true
        );
    }
}
