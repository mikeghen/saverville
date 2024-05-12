// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Saverville} from "../src/saverville.sol";

contract SavervilleTest is Test {
    Saverville public saverville;

    function setUp() public {
        saverville = new Saverville();
        
    }

    function testOwnerIsMsgSender() public view {
        assertEq(saverville.owner(), address(this));
    }

    function testCreateCrop() public {

    }

    function testDeposit() public {
        uint256 balanceBefore = address(saverville).balance;
        saverville.deposit{value: 1 ether}(0);
        uint256 balanceAfter = address(saverville).balance;

        assertEq(balanceAfter - balanceBefore, 1 ether, "expect increase of 1 ether");
    }

    function testHarvest() public {

    }
}
