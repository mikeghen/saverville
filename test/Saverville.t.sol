// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Saverville} from "../src/saverville.sol";
import {VRFCoordinatorV2Mock} from "chainlink/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";

contract SavervilleTest is Test {
    Saverville public saverville;

    function setUp() public {

        // Setup Chainlink VRF 
        // Steps: https://docs.chain.link/vrf/v2/subscription/examples/test-locally#testing-logic
        VRFCoordinatorV2Mock vrfCoordinator = new VRFCoordinatorV2Mock(1,1);

        // Create a subscription

        // Fund Subscription

        // Deploy Saverville (to get consumer address)
        saverville = new Saverville();

        // Add Consumer

        
    }

    function testOwnerIsMsgSender() public view {
        assertEq(saverville.owner(), address(this));
    }

    function testCreateCrop() public {}

    function testDeposit() public {
        uint256 balanceBefore = address(saverville).balance;
        saverville.deposit{value: 1 ether}(0);
        uint256 balanceAfter = address(saverville).balance;

        assertEq(balanceAfter - balanceBefore, 1 ether, "expect increase of 1 ether");
    }

    function testHarvest() public {}
}
