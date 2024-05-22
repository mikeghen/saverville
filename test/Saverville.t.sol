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
        uint64 subId = vrfCoordinator.createSubscription();
        address networkAddress = 0x4d21A42d5f91f97AF5012FC73F34Fe56a49d3250;

        // Fund Subscription
        vrfCoordinator.fundSubscription(subId, 100);

        // Deploy Saverville (to get consumer address)
        saverville = new Saverville(subId, networkAddress);

        // Add Consumer
        vrfCoordinator.addConsumer(subId, address(this));


        // Random number
        bytes32 Hashkey = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
        uint256 RandomNumber = vrfCoordinator.requestRandomWords(Hashkey, subId, 1, 1, 1);
    }

    // Golbal Random seed
    // When number is need take % of Random seed
    // Planting seed is creft of deposit 

    function test_RandomNumberIsNotZero() public {
        
    }

    function test_OwnerIsMsgSender() public view {
        assertEq(saverville.owner(), address(this));
    }

    function test_CreateCrop() public {}

    function test_Deposit() public {
        uint256 balanceBefore = address(saverville).balance;
        saverville.deposit{value: 1 ether}(0);
        uint256 balanceAfter = address(saverville).balance;

        assertEq(balanceAfter - balanceBefore, 1 ether, "expect increase of 1 ether");
    }

    function test_Harvest() public {}
}
