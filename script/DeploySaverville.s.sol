// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Saverville} from "../src/Saverville.sol";
import {VRFCoordinatorV2Mock} from "chainlink/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {MockLendingPool} from "../src/mocks/MockLendingPool.sol";


contract DeploySaverville is Script {
    Saverville public saverville;
    address vrfCoordinator = 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625;
    MockLendingPool public lendingPool;
    MockERC20 public wETH;
    uint64 subId = 11695;

    bytes32 keyHash = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
    uint32 callbackGasLimit = 200000;
    uint16 blockConfirmations = 3;
    uint32 numWords = 1;

    // function run() external {
    //     uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
    //     vm.startBroadcast(deployerPrivateKey);

    //     // Deploy VRFCoordinatorV2Mock
    //     vrfCoordinator = new VRFCoordinatorV2Mock(1, 1);
    //     console.log("Deployed VRFCoordinatorV2Mock at:", address(vrfCoordinator));

    //     // Create a subscription
    //     subId = vrfCoordinator.createSubscription();
    //     console.log("Created subscription with ID:", subId);

    //     // Fund the subscription
    //     vrfCoordinator.fundSubscription(subId, 100 ether);
    //     console.log("Funded subscription with 100 ETH");

    //     // Deploy MockERC20 for WETH
    //     wETH = new MockERC20("Wrapped Ether", "WETH");
    //     console.log("Deployed MockERC20 (WETH) at:", address(wETH));

    //     // // Deploy MockLendingPool
    //     // lendingPool = new MockLendingPool(address(wETH));
    //     // console.log("Deployed MockLendingPool at:", address(lendingPool));

    //     // Deploy Saverville
    //     saverville = new Saverville(subId, address(vrfCoordinator), address(lendingPool));
    //     console.log("Deployed Saverville at:", address(saverville));

    //     // Add Saverville as a consumer to the VRF subscription
    //     vrfCoordinator.addConsumer(subId, address(saverville));
    //     console.log("Added Saverville as a consumer to the subscription");

    //     vm.stopBroadcast();
    // }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);


        // // Deploy MockERC20 for WETH
        // wETH = new MockERC20("Wrapped Ether", "WETH");
        // console.log("Deployed MockERC20 (WETH) at:", address(wETH));

        // // Deploy MockLendingPool
        // lendingPool = new MockLendingPool(address(wETH));
        // console.log("Deployed MockLendingPool at:", address(lendingPool));

        // Deploy Saverville
        saverville = new Saverville(subId, vrfCoordinator, address(lendingPool));
        console.log("Deployed Saverville at:", address(saverville));


        vm.stopBroadcast();
    }
}
