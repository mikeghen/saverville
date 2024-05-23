// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {VRFCoordinatorV2Interface} from "chainlink/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "chainlink/src/v0.8/vrf/VRFConsumerBaseV2.sol";

contract Saverville is VRFConsumerBaseV2 {
    address public owner;

    // The price of a seed in ETH
    uint seedPrice = 0.0025 ether;

    // Average duration, this amount is what we alter randomly
    uint256 averageDuration = 120; // 2 minutes
    
    // Each user has their own farm and a farm has many farm plots
    struct Farm {
        FarmPlot[100] plots;
        uint256 plantableSeeds; // The amount of seeds that have been planted
        uint256 totalEarnings; // The amount of ETH earned in interest
        uint256 totalHarvestedPlants; // The number of plants that have been harvested
    }

    // Farm plots get seeded, watered and harvested
    // To seed a farm plot, the user has to buy seeds
    // Each farm plot is seeded with seedPrice amount of ETH
    // When a seed gets planted, it gets deposited into Aave 
    // When a plant gets harvested the ETH is withdrawn from Aave and added to their balance
    struct FarmPlot {
        uint state; // 0 = free, 1 = seeded, 2 = watered 
        // free -> seeded (plant)
        // seeded -> watered (water)
        // watered -> free (harvest)
        uint harvestAt; // Timestamp when this plot can be harvested, set when watered randomized a bit with chainlink
    }
    
    // List of Farms in protocol
    mapping(address => Farm) public farms;

    // This random seed is set by Chainlink, the value here is used to seed a random number generated with %
    // The `setRandomSeed` method is what calls this value to update
    uint256 randomSeed;

    VRFCoordinatorV2Interface coordinator;
    uint256 subscriptionId;

    constructor(
        uint64 _subscriptionId,
        address _networkAddress
    ) VRFConsumerBaseV2(_networkAddress) {
        coordinator = VRFCoordinatorV2Interface(_networkAddress);
        subscriptionId = _subscriptionId;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert("Not owner");
        _;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory _randomWords
    ) internal override {
        uint256 randomRange = (_randomWords[0] % 11);
        randomDaysAdded = randomRange;
    }

    function createCrop(uint256 _minDays) private onlyOwner {
        crops[cropId] = Crop(cropId, _minDays);
        cropId++;
    }

    function deposit(uint8 _cropId) public payable {
        if (msg.value < 0) {
            revert("Deposit must be greater than 0");
        }

        farmers[currentFarmerId] = Farmer(
            msg.sender,
            _cropId,
            currentFarmerId,
            block.timestamp,
            msg.value,
            false // Set matured to false initially
        );

        currentFarmerId++;
    }

    // Withdraw can only happen within the harvest range
    // The harvest date will be between a min and max
    function harvest(uint256 _farmerId) public payable {
        if (farmers[_farmerId].walletAddress != msg.sender) {
            revert("Only the farmer who planeted can withdraw");
        }

        if (farmers[_farmerId].matured != false) {
            revert("The crop has not matured yet");
        }

        uint256 planetDate = farmers[_farmerId].lockDate;
        uint256 cropType = farmers[_farmerId].cropId;
        uint256 cropMinTime = crops[cropType].minLockTime;

        if (planetDate < planetDate + cropMinTime) {
            revert("It is not harvest time yet");
        }

        uint256 amount = farmers[_farmerId].weiStaked;

        payable(msg.sender).call{value: amount};
    }
}
