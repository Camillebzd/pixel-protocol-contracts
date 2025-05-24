// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {PixelProtocol} from "../src/PixelProtocol.sol";
import {USDC} from "../src/mock/USDC.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Vm} from "forge-std/Vm.sol";

contract PixelProtocolTest is Test {
    PixelProtocol public pixelProtocol;
    USDC public usdc;

    address owner;
    address user;

    function setUp() public {
        // Setup owner
        owner = makeAddr("Owner");
        user = makeAddr("User");

        // Setup USDC and PixelProtocol contracts
        usdc = new USDC(owner);
        pixelProtocol = new PixelProtocol(owner, address(usdc));

        // Mint some USDC for the user and owner
        vm.prank(owner);
        usdc.mint(owner, 1000 * 1e6); // 1000 USDC (6 decimals)
        vm.prank(owner);
        usdc.mint(user, 1000 * 1e6); // 1000 USDC (6 decimals)
    }

    function testSetCooldown() public {
        uint256 newCooldown = 5 minutes;

        pixelProtocol.setCooldown(newCooldown);

        assertEq(pixelProtocol.COOLDOWN(), newCooldown);
    }

    function testPlacePixel() public {
        uint256 x = 100;
        uint256 y = 200;
        uint24 color = 0xFF0000; // Red

        // Place a pixel
        vm.expectEmit(true, true, false, true, address(pixelProtocol));
        emit PixelProtocol.PixelPlaced(x, y, color, user, block.timestamp);
        vm.prank(user);
        pixelProtocol.placePixel(x, y, color);

        // Check if the pixel was placed correctly
        (uint24 pixelColor, address pixelWallet, uint256 pixelTimestamp) = pixelProtocol.canvas(x, y);
        assertEq(pixelColor, color);
        assertEq(pixelWallet, user);
        assertEq(pixelTimestamp, block.timestamp);
    }

    function testInvalidCoordinates() public {
        uint256 x = 600; // Out of bounds
        uint256 y = 700; // Out of bounds
        uint24 color = 0x00FF00; // Green

        // Try to place a pixel with invalid coordinates
        vm.expectRevert(abi.encodeWithSelector(PixelProtocol.InvalidCoordinates.selector, x, y));
        vm.prank(user);
        pixelProtocol.placePixel(x, y, color);
    }

    function testCooldownActive() public {
        uint256 x = 100;
        uint256 y = 200;
        uint24 color = 0x0000FF; // Blue

        // Simulate placing a pixel
        vm.prank(user);
        pixelProtocol.placePixel(x, y, color);
        uint256 lastPlacement = pixelProtocol.lastPlacement(user);

        // Try to place another pixel before cooldown
        skip(60); // Skip 60 seconds
        vm.expectRevert(
            abi.encodeWithSelector(PixelProtocol.CooldownActive.selector, lastPlacement, pixelProtocol.COOLDOWN())
        );
        vm.prank(user);
        pixelProtocol.placePixel(x, y, color);
    }

    function testUSDCTransfer() public {
        uint256 x = 100;
        uint256 y = 200;
        uint24 color = 0xFFFF00; // Yellow
        uint256 fee = pixelProtocol.USDC_FEE();

        // Approve USDC transfer
        vm.prank(user);
        usdc.approve(address(pixelProtocol), fee);

        uint256 initialBalance = usdc.balanceOf(user);

        // Place a pixel with USDC fee
        vm.recordLogs();
        vm.prank(user);
        pixelProtocol.placePixelWithUSDC(x, y, color);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 2, "Expected two logs");
        // Check second log for PixelPlaced event
        bytes32 expectedTopic = keccak256("PixelPlaced(uint256,uint256,uint24,address,uint256)");
        assertEq(entries[1].topics[0], expectedTopic, "Second log is not PixelPlaced");
        assertEq(uint256(entries[1].topics[1]), x, "X coordinate mismatch");
        assertEq(uint256(entries[1].topics[2]), y, "Y coordinate mismatch");
        (uint24 loggedColor, uint256 loggedTimestamp) = abi.decode(entries[1].data, (uint24, uint256));
        assertEq(loggedColor, color, "Color mismatch");
        assertEq(address(uint160(uint256(entries[1].topics[3]))), user, "Wallet mismatch");
        assertEq(loggedTimestamp, block.timestamp, "Timestamp mismatch");

        // Check USDC balance after placement
        assertEq(usdc.balanceOf(user), initialBalance - fee);
        assertEq(usdc.balanceOf(address(pixelProtocol)), fee);

        // Withdraw USDC fee
        uint256 ownerBalance = usdc.balanceOf(owner);
        vm.prank(owner);
        pixelProtocol.withdrawUSDC(owner, fee);
        assertEq(usdc.balanceOf(owner), ownerBalance + fee);
    }

    function testUSDCTransferFailed() public {
        uint256 x = 100;
        uint256 y = 200;
        uint24 color = 0x00FFFF; // Cyan

        // Simulate USDC transfer failure
        vm.expectRevert();
        vm.prank(user);
        pixelProtocol.placePixelWithUSDC(x, y, color);
    }

    function testWithdrawUSDC() public {
        uint256 amount = 5 * 1e6; // 5 USDC
        uint256 initialBalance = usdc.balanceOf(owner);

        vm.prank(owner);
        usdc.transfer(address(pixelProtocol), amount);

        assertEq(usdc.balanceOf(address(pixelProtocol)), amount);
        assertEq(usdc.balanceOf(owner), initialBalance - amount);

        // Withdraw USDC
        vm.prank(owner);
        pixelProtocol.withdrawUSDC(owner, amount);

        // Check balances
        assertEq(usdc.balanceOf(owner), initialBalance);
        assertEq(usdc.balanceOf(address(pixelProtocol)), 0);
    }

    function testWithdrawUSDCUnauthorized() public {
        uint256 amount = 5 * 1e6; // 5 USDC
        uint256 initialBalance = usdc.balanceOf(owner);

        vm.prank(owner);
        usdc.transfer(address(pixelProtocol), amount);

        assertEq(usdc.balanceOf(address(pixelProtocol)), amount);
        assertEq(usdc.balanceOf(owner), initialBalance - amount);

        // Try to withdraw USDC as a non-owner
        vm.expectRevert();
        vm.prank(user);
        pixelProtocol.withdrawUSDC(user, amount);

        // Check balances remain unchanged
        assertEq(usdc.balanceOf(address(pixelProtocol)), amount);
    }
}
