// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Saverville {
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
        uint256 maxLockTime;
    }


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



    constructor() {
        owner = msg.sender;
    }

    function createCrop(uint256 _min, uint256 _max) private {
        if (msg.sender != owner) {
            revert("Not owner");
        }
        
        crops[cropId]=Crop(cropId, _min, _max);

        cropId++;
    }

    function deposit(uint256 _amount, uint _cropId) public payable {
        if (_amount < 0) {
            revert("Deposit must be greater than 0");
        }
        if (msg.value != _amount) {
            revert("Amount does not equal the Ether sent");
        }

        farmers[currentFarmerId] =
            Farmer(msg.sender, _cropId, currentFarmerId, block.timestamp, _amount, true);

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
        uint256 cropMaxTime = crops[cropType].maxLockTime;

        if (planetDate < planetDate + cropMinTime) {
            revert("It is not harvest time yet");
        }

        uint256 amount = farmers[_farmerId].weiStaked;

        payable(msg.sender).call{value: amount};
    }
}
