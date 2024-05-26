// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Saverville} from "../src/Saverville.sol";
import {VRFCoordinatorV2Mock} from "chainlink/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";

contract DeploySaverville is Script {
    Saverville public saverville;
    VRFCoordinatorV2Mock public vrfCoordinator;
    uint64 subId;

    bytes32 keyHash = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
    uint32 callbackGasLimit = 200000;
    uint16 blockConfirmations = 3;
    uint32 numWords = 1;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy VRFCoordinatorV2Mock
        vrfCoordinator = new VRFCoordinatorV2Mock(1, 1);
        console.log("Deployed VRFCoordinatorV2Mock at:", address(vrfCoordinator));

        // Create a subscription
        subId = vrfCoordinator.createSubscription();
        console.log("Created subscription with ID:", subId);

        // Fund the subscription
        vrfCoordinator.fundSubscription(subId, 100 ether);
        console.log("Funded subscription with 100 ETH");

        // Deploy Saverville
        saverville = new Saverville(subId, address(vrfCoordinator));
        console.log("Deployed Saverville at:", address(saverville));

        // Add Saverville as a consumer to the VRF subscription
        vrfCoordinator.addConsumer(subId, address(saverville));
        console.log("Added Saverville as a consumer to the subscription");

        vm.stopBroadcast();
    }
}
