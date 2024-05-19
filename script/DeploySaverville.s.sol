// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {Saverville} from "../src/saverville.sol";

contract DeploySaverville is Script {
    function run() external {
        vm.startBroadcast();
        new Saverville();
        vm.stopBroadcast();
    }
}
