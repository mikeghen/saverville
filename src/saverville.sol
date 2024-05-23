// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {VRFCoordinatorV2Interface} from "chainlink/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "chainlink/src/v0.8/vrf/VRFConsumerBaseV2.sol";

contract Saverville is VRFConsumerBaseV2 {
    address public owner;

    struct Farmer {
        address walletAddress;
        uint256 cropId;
        uint256 farmerId;
        uint256 lockDate;
        uint256 weiStaked;
        bool matured;
    }

    struct Crop {
        uint256 planetId;
        uint256 minLockTime;
    }

    // Test Crop
    Crop corn = Crop(0, 15 + randomDaysAdded);

    // List of Farmers in protocol
    mapping(uint256 => Farmer) public farmers;
    // List of Crops in protocol
    mapping(uint256 => Crop) public crops;
    // Id's of Farmers
    uint256 public currentFarmerId;
    // Id's of Crops
    uint256 public cropId;
    // Time when ether will be unlocked
    // Unlock Date is the min plus the lockDate
    uint256 public unlockDate;
    // Adding random number with chainlink vrf
    uint256 randomDaysAdded;

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
