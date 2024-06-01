// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {VRFCoordinatorV2Interface} from "chainlink/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "chainlink/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {MockLendingPool} from "./mocks/mockLendingPool.sol";
import {MockERC20} from "./mocks/mockErc20.sol";

contract Saverville is VRFConsumerBaseV2 {
    address public owner;
    MockLendingPool public lendingPool;

    // The price of a seed in ETH
    uint public seedPrice = 0.0025 ether;

    // Average duration, this amount is what we alter randomly
    uint256 averageDuration = 120; // 2 minutes

    // Each user has their own farm and a farm has many farm plots
    struct Farm {
        mapping(uint => FarmPlot) plots;
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
    uint256 public randomSeed;

    VRFCoordinatorV2Interface coordinator;
    uint256 subscriptionId;

    // Update the constructor to inhert the mockLending pool
    constructor(
        uint64 _subscriptionId,
        address _networkAddress,
        address _lendingPoolAddress
    ) VRFConsumerBaseV2(_networkAddress) 
      {
        coordinator = VRFCoordinatorV2Interface(_networkAddress);
        subscriptionId = _subscriptionId;
        owner = msg.sender;
        lendingPool = MockLendingPool(_lendingPoolAddress);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function fulfillRandomWords(
        uint256,
        uint256[] memory _randomWords
    ) internal override {
        uint256 randomRange = (_randomWords[0] % 11);
        randomSeed = randomRange;
    }


    // This function will allow users to buy as many seeds as they want with ETH
    // The Eth will be stored into this contract and the user will receive the seed which will be a wETH 
function buySeeds(uint256 _amount) public payable {
        require(msg.value >= _amount * seedPrice, "Insufficient ETH for seeds");
        Farm storage farm = farms[msg.sender];
        farm.plantableSeeds += _amount;

       // Convert ETH to wETH
        MockERC20 wETH = MockERC20(address(lendingPool.wETH()));
        wETH.mint(msg.sender, msg.value);
    }

    function plantSeed(uint256 _plotId) public {
        Farm storage farm = farms[msg.sender];
        require(_plotId < 100, "Invalid plot ID");
        require(farm.plots[_plotId].state == 0, "Plot not free");

        farm.plots[_plotId].state = 1; // Seeded
        farm.plantableSeeds -= 1;

        // Amount of WETH to deposit into Aave
        uint256 supplyAmount = seedPrice;
        
        MockERC20 wETH = MockERC20(address(lendingPool.wETH()));

        wETH.approve(address(lendingPool), supplyAmount);
        wETH.transferFrom(msg.sender, address(lendingPool), supplyAmount);
        
        // Call the supply function to deposit WETH into Aave
        lendingPool.supply(supplyAmount, msg.sender, 0); // Assuming 0 for referralCode for simplicity

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

        // Withdraw from Aave and transfer to the user
        uint256 amount = seedPrice; // The amount to withdraw should match the deposited amount plus any interest earned
        lendingPool.withdraw(amount, msg.sender);
    }

    function getFarmPlots(address _farmer, uint _plotId) public view returns (FarmPlot memory) {
        // farm is the current Farm
        Farm storage farm = farms[_farmer];
        // Returning a plot mapped to a uint in the current farm
        return farm.plots[_plotId];
    }
}
