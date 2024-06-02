// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Saverville} from "../src/saverville.sol";
import {VRFCoordinatorV2Mock} from "chainlink/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {MockLendingPool} from "../src/mocks/MockLendingPool.sol";

contract SavervilleTest is Test {
    Saverville public saverville;
    VRFCoordinatorV2Mock public vrfCoordinator;
    MockLendingPool public lendingPool;
    MockERC20 public wETH;

    uint64 subId;
    uint256 requestId;
    bytes32 keyHash = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
    uint32 callbackGasLimit = 200000;
    uint16 blockConfirmations = 3;
    uint32 numWords = 1;
    address consumerAddress;
    address farmerAddress;

    function setUp() external {
        // Setup Chainlink VRF
        vrfCoordinator = new VRFCoordinatorV2Mock(1, 1);

        // Create a subscription
        subId = vrfCoordinator.createSubscription();
        address networkAddress = address(vrfCoordinator);

        // Fund Subscription
        vrfCoordinator.fundSubscription(subId, 100 ether);

        // Deploy WETH and MockLendingPool
        wETH = new MockERC20("Wrapped Ether", "WETH");
        lendingPool = new MockLendingPool(address(wETH));

        // Deploy Saverville
        saverville = new Saverville(subId, networkAddress, address(lendingPool));

        // Send saverVille some ETH
        vm.deal(address(saverville), 10 ether);

        // Add Consumer
        vrfCoordinator.addConsumer(subId, address(saverville));

        consumerAddress = address(saverville);

        farmerAddress = vm.addr(1);
        vm.deal(farmerAddress, 10 ether);

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

        // Check farmer balance before buying seeds
        uint256 farmerBalance = address(farmerAddress).balance;

        uint256 quantity = 10;
        uint256 cost = quantity * saverville.seedPrice();
        vm.startPrank(farmerAddress);
        saverville.buySeeds{value: cost}(quantity);
        (uint256 plantableSeeds,,) = saverville.farms(farmerAddress);
        assertEq(plantableSeeds, quantity);
        vm.stopPrank();

        // Check farmer balance after buying seeds
        uint256 farmerBalanceAfter = address(farmerAddress).balance;
        assertEq(farmerBalance - cost, farmerBalanceAfter);
    }

    function test_PlantSeed() public {
        uint256 quantity = 10;
        uint256 cost = quantity * saverville.seedPrice();

        vm.startPrank(farmerAddress);
        saverville.buySeeds{value: cost}(quantity);
        saverville.plantSeed(0);
        vm.stopPrank();
        // Create the Farm in memory
        (uint256 plantableSeeds,,) = saverville.farms(farmerAddress);
        assertEq(plantableSeeds, quantity - 1);

        // Get the FarmPlot in memory
        Saverville.FarmPlot memory farmPlot = saverville.getFarmPlots(farmerAddress, 0);
        assertEq(farmPlot.state, 1); // Plot should be seeded
    }

    function test_WaterPlant() public {
        uint256 quantity = 10;
        uint256 cost = quantity * saverville.seedPrice();

        vm.startPrank(farmerAddress);
        saverville.buySeeds{value: cost}(quantity);
        saverville.plantSeed(0);
        vm.stopPrank();

        // consumerAddress must call the random function
        vm.startPrank(consumerAddress);
        requestId = vrfCoordinator.requestRandomWords(keyHash, subId, blockConfirmations, callbackGasLimit, numWords);
        vrfCoordinator.fulfillRandomWords(requestId, consumerAddress);
        vm.stopPrank();

        vm.prank(farmerAddress);
        saverville.waterPlant(0);
        assert(saverville.getFarmPlots(farmerAddress, 0).harvestAt > block.timestamp);

        assertEq(saverville.getFarmPlots(farmerAddress, 0).state, 2); // Plot should be watered
    }

    function test_HarvestPlant() public {
        uint256 quantity = 10;
        uint256 seedPrice = saverville.seedPrice();
        uint256 cost = quantity * saverville.seedPrice();

        vm.startPrank(farmerAddress);
        saverville.buySeeds{value: cost}(quantity);
        saverville.plantSeed(0);
        vm.stopPrank();

        uint256 farmerBalance = address(farmerAddress).balance;

        // consumerAddress must call the random function
        vm.startPrank(consumerAddress);
        requestId = vrfCoordinator.requestRandomWords(keyHash, subId, blockConfirmations, callbackGasLimit, numWords);
        vrfCoordinator.fulfillRandomWords(requestId, consumerAddress);
        vm.stopPrank();

        vm.startPrank(farmerAddress);
        saverville.waterPlant(0);
        skip(saverville.getFarmPlots(farmerAddress, 0).harvestAt - block.timestamp + 1);

        saverville.harvestPlant(0);
        assertEq(saverville.getFarmPlots(farmerAddress, 0).state, 0); // Plot should be free

        (,, uint256 totalHarvestedPlants) = saverville.farms(farmerAddress);
        assertEq(totalHarvestedPlants, 1);
        vm.stopPrank();

        // Check farmer balance after
        uint256 farmerBalanceAfter = address(farmerAddress).balance;
        assertEq(farmerBalance + seedPrice + seedPrice * 5 / 10, farmerBalanceAfter);
    }

    // batch approve and buy seeds batch
}
