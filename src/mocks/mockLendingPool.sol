// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MockERC20.sol";
import "hardhat/console.sol";

/// @title MockLendingPool
/// @notice This contract simulates a lending pool where users can supply assets to earn interest
/// @notice  Supply, withdraw, borrow, and repay assets
/// @custom:experimental This is an experimental contract.

contract MockLendingPool {
    /// @dev Aave Tokens
    MockERC20 public astETH;
    MockERC20 public asUSD;
    MockERC20 public aAAVE;
    MockERC20 public sUSDdebt;

    /// @notice Mappings of user balances, aTokens, referral codes
    mapping(address => mapping(address => uint)) public balances;
    mapping(address => MockERC20) public tokenToAToken;
    mapping(uint16 => address) public referralCodes;

    /// @dev Mock interest-bearing aToken wrappers
    constructor(address _stETH, address _sUSD, address _AAVE) {
        astETH = new MockERC20("Aave stETH", "astETH");
        asUSD = new MockERC20("Aave sUSD", "asUSD");
        aAAVE = new MockERC20("Aave AAVE", "aAAVE");
        sUSDdebt = new MockERC20("Aave sUSD debt", "sUSDdebt");

        tokenToAToken[_stETH] = astETH;
        tokenToAToken[_sUSD] = asUSD;
        tokenToAToken[_AAVE] = aAAVE;
    }

    /// @notice Sets a referral code for a referrer address
    function setReferralCode(uint16 rCode, address referrerAddr) external {
        referralCodes[rCode] = referrerAddr;
    }

    /// @notice Supply assets to Aave pool
    function supply(
        address asset,
        uint amount,
        address onBehalfOf,
        uint16 referralCode
    ) external {
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
        balances[onBehalfOf][asset] += amount;
        tokenToAToken[asset].mint(onBehalfOf, amount);

        /// @dev Reward given to the referrerAddr is a referal code was entered
        if (referralCodes[referralCode] != address(0)) {
            uint reward = amount / 100; // 1% reward
            tokenToAToken[asset].mint(referralCodes[referralCode], reward);
        }
    }

    /// @notice Withdraw assets from Aave pool
    function withdraw(
        address asset,
        uint amount,
        address to
    ) external returns (uint) {
        require(balances[msg.sender][asset] >= amount, "Insufficient balance");
        tokenToAToken[asset].burn(msg.sender, amount);
        balances[msg.sender][asset] -= amount;
        IERC20(asset).transfer(to, amount);
        return amount;
    }

    /// @notice Borrow assets from Aave pool
    function borrow(
        address asset,
        uint amount,
        uint interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external {
        require(
            IERC20(asset).balanceOf(address(this)) >= amount,
            "Invalid balance"
        );
        // balances[onBehalfOf][asset] -= amount;
        IERC20(asset).transfer(onBehalfOf, amount);

        // Calculate debt based on the interest rate mode
        uint debt;
        if (interestRateMode == 1) {
            // Stable interest rate mode: 5% increase
            debt = amount + ((amount * 5) / 100);
        } else if (interestRateMode == 2) {
            // Variable interest rate mode: random increase between 1% and 10%
            uint randomIncrease = (uint(
                keccak256(abi.encodePacked(block.timestamp, block.prevrandao))
            ) % 10) + 1;
            debt = amount + ((amount * randomIncrease) / 100);
        } else {
            revert("Invalid interest rate mode");
        }

        sUSDdebt.mint(onBehalfOf, debt); //  Mint debt token

        /// @dev Reward given to the referrerAddr is a referal code was entered
        if (referralCodes[referralCode] != address(0)) {
            uint reward = amount / 100; // 1% reward
            tokenToAToken[asset].mint(referralCodes[referralCode], reward);
        }
    }

    /// @notice Allows a user to repay their borrowed assets
    function repay(
        address asset,
        uint amount,
        uint interestRateMode,
        address onBehalfOf
    ) external returns (uint) {
        // Calculate repayment amount based on the rate mode
        uint repaymentAmount;
        if (interestRateMode == 1) {
            // Stable rate mode: repay exact amount
            repaymentAmount = amount;
        } else if (interestRateMode == 2) {
            // Variable rate mode: repay amount plus random increase between 1% and 10%
            uint randomIncrease = (uint(
                keccak256(abi.encodePacked(block.timestamp, block.prevrandao))
            ) % 10) + 1;
            repaymentAmount = amount + ((amount * randomIncrease) / 100);
        } else {
            revert("Invalid rate mode");
        }

        console.log("Repaying asset:", asset);
        console.log("Repayment amount:", repaymentAmount);
        console.log("Rate mode:", interestRateMode);
        console.log("On behalf of:", onBehalfOf);
        console.log(
            "Balance before repayment:",
            IERC20(asset).balanceOf(address(this))
        );

        IERC20(asset).transferFrom(msg.sender, address(this), repaymentAmount);
        console.log(
            "Balance after repayment:",
            IERC20(asset).balanceOf(address(this))
        );

        sUSDdebt.burn(onBehalfOf, amount); // burn debt token
        console.log(
            "Debt balance after repayment:",
            sUSDdebt.balanceOf(onBehalfOf)
        );

        balances[onBehalfOf][asset] += amount; // update debt balance
        console.log(
            "Asset balance after repayment:",
            balances[onBehalfOf][asset]
        );
        return repaymentAmount;
    }
}