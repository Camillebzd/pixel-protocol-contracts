// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {PixelProtocol} from "../src/PixelProtocol.sol";

contract PixelProtocolScript is Script {
    PixelProtocol public pixelProtocol;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        address usdc = 0x4C2AA252BEe766D3399850569713b55178934849; // USDC address on Etherlink testnet
        pixelProtocol = new PixelProtocol(msg.sender, usdc);

        vm.stopBroadcast();
    }
}
