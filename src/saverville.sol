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

    // Farm plots get seeded, watered, and harvested
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
        require(msg.sender == owner, "Not owner");
        _;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory _randomWords
    ) internal override {
        uint256 randomRange = (_randomWords[0] % 11);
        randomSeed = randomRange;
    }

    function plantSeed(uint256 _plotId) public payable {
        require(msg.value >= seedPrice, "Insufficient seed price");
        Farm storage farm = farms[msg.sender];
        require(_plotId < 100, "Invalid plot ID");
        require(farm.plots[_plotId].state == 0, "Plot not free");

        farm.plots[_plotId].state = 1; // Seeded
        farm.plantableSeeds += 1;

        // Logic to deposit into Aave should be implemented here
    }

    function waterPlant(uint256 _plotId) public {
        Farm storage farm = farms[msg.sender];
        require(_plotId < 100, "Invalid plot ID");
        require(farm.plots[_plotId].state == 1, "Plot not seeded");

        farm.plots[_plotId].state = 2; // Watered
        farm.plots[_plotId].harvestAt = block.timestamp + (averageDuration + randomSeed) * 1 minutes;
    }

    function harvestPlant(uint256 _plotId) public {
        Farm storage farm = farms[msg.sender];
        require(_plotId < 100, "Invalid plot ID");
        require(farm.plots[_plotId].state == 2, "Plot not watered");
        require(block.timestamp >= farm.plots[_plotId].harvestAt, "Not harvest time yet");

        farm.plots[_plotId].state = 0; // Free
        farm.totalHarvestedPlants += 1;

        // Logic to withdraw from Aave and transfer to the user should be implemented here
    }

    function buySeeds(uint256 _amount) public payable {
        require(msg.value >= _amount * seedPrice, "Insufficient ETH for seeds");
        Farm storage farm = farms[msg.sender];
        farm.plantableSeeds += _amount;
    }

    function withdraw(uint256 _amount) public onlyOwner {
        require(address(this).balance >= _amount, "Insufficient balance");
        payable(msg.sender).transfer(_amount);
    }
}
