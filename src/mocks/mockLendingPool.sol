// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./MockERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title MockLendingPool
/// @notice This contract simulates a lending pool where users can supply WETH to earn interest.
/// @custom:experimental This is an experimental contract.
contract MockLendingPool {
    /// @notice Instance of the Wrapped Ether (WETH) token.
    MockERC20 public wETH;

    /// @notice Mapping of user balances of WETH in the lending pool.
    mapping(address => uint256) public balances;

    /// @notice Mappings of referral codes to referrer addresses.
    mapping(uint16 => address) public referralCodes;

    /// @dev Mock interest-bearing wETH wrapper
    constructor(address _wETH) {
        wETH = MockERC20(_wETH);
    }

    /// @notice Supply WETH to the Aave pool.
    /// @param _amount The amount of WETH to supply.
    /// @param _onBehalfOf The address that will receive the supplied wETH.
    /// @param _referralCode The referral code used for rewarding referrers.
    function supply(uint256 _amount, address _onBehalfOf, uint16 _referralCode) public {
        require(_amount > 0, "Amount must be greater than 0.");
        // Transfer WETH from the user to this contract.
        IERC20(address(wETH)).transferFrom(msg.sender, address(this), _amount);
        // Update the balance of the onBehalfOf address.
        balances[_onBehalfOf] += _amount;
        // Mint equivalent aTokens (for simplicity, using the same wETH token).
        wETH.mint(_onBehalfOf, _amount);

        // Reward given to the referrer if a referral code was entered.
        if (referralCodes[_referralCode] != address(0)) {
            uint256 reward = _amount / 100; // 1% reward
            wETH.mint(referralCodes[_referralCode], reward);
        }

    }

    /// @notice Withdraw WETH from the Aave pool.
    /// @param _amount The amount of WETH to withdraw.
    /// @param _to The address that will receive the withdrawn WETH.
    /// @return The amount of WETH withdrawn.
    function withdraw(uint256 _amount, address _to) public returns (uint256) {
        require(_amount > 0, "Amount must be greater than 0.");
        require(balances[msg.sender] >= _amount, "Insufficient balance.");
        // Burn equivalent aTokens (for simplicity, using the same wETH token).
        wETH.burn(msg.sender, _amount);
        // Update the balance of the user.
        balances[msg.sender] -= _amount;
        // Transfer WETH from the contract to the specified address.
        IERC20(address(wETH)).transfer(_to, _amount);
        return _amount;
    }

    /// @notice Sets a referral code for a referrer address.
    /// @param rCode The referral code.
    /// @param referrerAddr The address of the referrer.
    function setReferralCode(uint16 rCode, address referrerAddr) external {
        referralCodes[rCode] = referrerAddr;
    }

}