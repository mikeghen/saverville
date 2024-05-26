// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Saverville} from "../src/saverville.sol";
import {VRFCoordinatorV2Mock} from "chainlink/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";

contract SavervilleTest is Test {
    Saverville public saverville;
    VRFCoordinatorV2Mock public vrfCoordinator;
    uint64 subId;
    uint256 requestId;
    bytes32 keyHash = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
    uint32 callbackGasLimit = 200000;
    uint16 blockConfirmations = 3;
    uint32 numWords = 1;
    address consumerAddress;

    function setUp() external {
        // Setup Chainlink VRF 
        vrfCoordinator = new VRFCoordinatorV2Mock(1, 1);

        // Create a subscription
        subId = vrfCoordinator.createSubscription();
        address networkAddress = address(vrfCoordinator);

        // Fund Subscription
        vrfCoordinator.fundSubscription(subId, 100 ether);

        // Deploy Saverville
        saverville = new Saverville(subId, networkAddress);

        // Add Consumer
        vrfCoordinator.addConsumer(subId, address(saverville));

        consumerAddress = address(saverville);

    }


    function test_RandomNumberIsNotZero() public {
        vm.prank(consumerAddress);
        requestId = vrfCoordinator.requestRandomWords(keyHash, subId, blockConfirmations, callbackGasLimit, numWords);
        vrfCoordinator.fulfillRandomWords(requestId, consumerAddress);
        uint256 randomSeed = saverville.randomSeed();
        console2.log(randomSeed);
        assert(randomSeed > 0);
    }

    function test_RandomNumberIsBetween1To10() public {
        vm.prank(consumerAddress);
        requestId = vrfCoordinator.requestRandomWords(keyHash, subId, blockConfirmations, callbackGasLimit, numWords);
        vrfCoordinator.fulfillRandomWords(requestId, consumerAddress);
        uint256 randomSeed = saverville.randomSeed();
        console2.log(randomSeed);
        assert(randomSeed > 0 && randomSeed < 11);
    }


    function test_OwnerIsMsgSender() public view {
        assertEq(saverville.owner(), address(this));
    }

    function test_BuySeeds() public {
        uint256 quantity = 10;
        uint256 cost = quantity * saverville.seedPrice();
        saverville.buySeeds{value: cost}(quantity);
        (uint256 plantableSeeds,,) = saverville.farms(address(this));
        assertEq(plantableSeeds, quantity);
    }

    function test_PlantSeed() public {
        uint256 quantity = 10;
        uint256 cost = quantity * saverville.seedPrice();
        saverville.buySeeds{value: cost}(quantity);

        saverville.plantSeed(0);
        // Create the Farm in memory
        (uint plantableSeeds, ,) = saverville.farms(address(this));
        assertEq(plantableSeeds, quantity - 1);

        // Get the FarmPlot in memory
        Saverville.FarmPlot memory farmPlot = saverville.getFarmPlots(address(this), 0);
        assertEq(farmPlot.state, 1); // Plot should be seeded
    }

    function test_WaterPlant() public {
        uint256 quantity = 10;
        uint256 cost = quantity * saverville.seedPrice();
        saverville.buySeeds{value: cost}(quantity);

        saverville.plantSeed(0);

        // consumerAddress must call the random function
        vm.startPrank(consumerAddress);
        requestId = vrfCoordinator.requestRandomWords(keyHash, subId, blockConfirmations, callbackGasLimit, numWords);
        vrfCoordinator.fulfillRandomWords(requestId, consumerAddress);
        vm.stopPrank();

        saverville.waterPlant(0);
        assert(saverville.getFarmPlots(address(this), 0).harvestAt > block.timestamp);

        assertEq(saverville.getFarmPlots(address(this), 0).state, 2); // Plot should be watered
    }

    function test_HarvestPlant() public {
        uint256 quantity = 10;
        uint256 cost = quantity * saverville.seedPrice();
        saverville.buySeeds{value: cost}(quantity);

        saverville.plantSeed(0);
        
        // consumerAddress must call the random function
        vm.startPrank(consumerAddress);
        requestId = vrfCoordinator.requestRandomWords(keyHash, subId, blockConfirmations, callbackGasLimit, numWords);
        vrfCoordinator.fulfillRandomWords(requestId, consumerAddress);
        vm.stopPrank();

        saverville.waterPlant(0);
        
        skip(saverville.getFarmPlots(address(this), 0).harvestAt - block.timestamp + 1);

        saverville.harvestPlant(0);
        assertEq(saverville.getFarmPlots(address(this), 0).state, 0); // Plot should be free

        (,, uint256 totalHarvestedPlants) = saverville.farms(address(this));
        assertEq(totalHarvestedPlants, 1);
    }

}
