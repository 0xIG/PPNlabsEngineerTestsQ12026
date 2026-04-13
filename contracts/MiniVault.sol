// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title IMiniVault - interface with events and errors for Simple ERC20 Vault
interface IMiniVault {
    /// @notice Emitted when assets are deposited into the vault
    /// @param user The address of the depositor
    /// @param assetsAmount Amount of underlying assets deposited
    /// @param sharesAmount Amount of vault shares minted to the depositor
    event Deposited(
        address indexed user,
        uint256 assetsAmount,
        uint256 sharesAmount
    );
    /// @notice Emitted when assets are withdrawn from the vault
    /// @param user The address of the withdrawer
    /// @param assetsAmount Amount of underlying assets withdrawn
    /// @param sharesAmount Amount of vault shares burned
    event Withdrawn(
        address indexed user,
        uint256 assetsAmount,
        uint256 sharesAmount
    );

    /// @notice Thrown when vault is constructed with zero address for asset
    error InvalidAssetAddress();
    /// @notice Thrown when deposit amount is zero
    error ZeroDepositAssetsAmount();
    /// @notice Thrown when calculated withdrawal assets amount is zero
    error ZeroWithdrawAssetsAmount();
    /// @notice Thrown when user attempts to withdraw zero shares or receives zero shares from deposit
    error ZeroUserSharesAmount();
    /// @notice Thrown when total shares is zero during withdrawal calculation
    error ZeroTotalSharesAmount();
    /// @notice Thrown when user attempts to withdraw more shares than they own
    /// @param available The user's current share balance
    /// @param required The amount of shares requested for withdrawal
    error InsufficientSharesBalance(uint256 available, uint256 required);
}

/// @title MiniVault - Simple ERC20 Token Vault
/// @notice A simple vault that accepts ERC20 token deposits and mints shares
/// @dev Implements basic deposit/withdraw functionality with share calculation
contract MiniVault is IMiniVault {
    using SafeERC20 for IERC20;

    /// @notice The ERC20 token accepted by this vault
    /// @dev Immutable token address set during construction
    IERC20 public immutable asset;

    /// @notice Mapping of user addresses to their share balance
    /// @dev Shares represent ownership of the vault's underlying assets
    mapping(address => uint256) public balanceOf;

    /// @notice Total number of shares minted by the vault
    /// @dev Used to calculate share price and user entitlements
    uint256 public totalShares;

    /// @notice Constructs a new MiniVault for the specified ERC20 token
    /// @param _assetAddress The address of the ERC20 token to be used as vault asset
    /// @dev Reverts if `_assetAddress` is the zero address
    constructor(address _assetAddress) {
        if (_assetAddress == address(0)) revert InvalidAssetAddress();
        asset = IERC20(_assetAddress);
    }

    /// @notice Returns the total amount of underlying assets held by the vault
    /// @return The vault's balance of the underlying ERC20 token
    /// @dev Simply queries the token balance of this contract
    function totalAssets() public view returns (uint256) {
        return asset.balanceOf(address(this));
    }

    /// @notice Deposit assets into the vault and receive shares
    /// @param depositAssetsAmount Amount of underlying assets to deposit
    /// @return userSharesAmount Amount of shares minted to the depositor
    /// @dev Uses SafeERC20's safeTransferFrom for secure token transfers
    /// @dev Reverts if deposit amount is zero or calculated shares is zero
    /// @dev For first deposit, shares are minted 1:1 with assets
    /// @dev For subsequent deposits, shares are minted proportionally to existing share supply
    function deposit(
        uint256 depositAssetsAmount
    ) external returns (uint256 userSharesAmount) {
        if (depositAssetsAmount == 0) revert ZeroDepositAssetsAmount();

        uint256 _currentTotalShares = totalShares;
        uint256 _currentTotalAssets = totalAssets();

        if (_currentTotalShares == 0 || _currentTotalAssets == 0) {
            userSharesAmount = depositAssetsAmount;
        } else {
            userSharesAmount =
                (depositAssetsAmount * _currentTotalShares) /
                _currentTotalAssets;
        }

        if (userSharesAmount == 0) revert ZeroUserSharesAmount();
        totalShares = _currentTotalShares + userSharesAmount;
        balanceOf[msg.sender] += userSharesAmount;

        asset.safeTransferFrom(msg.sender, address(this), depositAssetsAmount);

        emit Deposited(msg.sender, depositAssetsAmount, userSharesAmount);
    }

    /// @notice Withdraw assets from the vault by burning shares
    /// @param withdrawSharesAmount Amount of shares to burn for withdrawal
    /// @return withdrawAssetsAmount Amount of underlying assets returned to the user
    /// @dev Uses SafeERC20's safeTransfer for secure token transfers
    /// @dev Reverts if share amount is zero, user has insufficient shares, or calculated assets is zero
    /// @dev Assets are calculated proportionally based on share percentage of total supply
    function withdraw(
        uint256 withdrawSharesAmount
    ) external returns (uint256 withdrawAssetsAmount) {
        if (withdrawSharesAmount == 0) revert ZeroUserSharesAmount();
        uint256 _userSharesAmount = balanceOf[msg.sender];
        if (_userSharesAmount < withdrawSharesAmount)
            revert InsufficientSharesBalance(
                _userSharesAmount,
                withdrawSharesAmount
            );

        uint256 _currentTotalShares = totalShares;
        uint256 _currentTotalAssets = totalAssets();
        if (_currentTotalShares == 0) revert ZeroTotalSharesAmount();

        withdrawAssetsAmount =
            (withdrawSharesAmount * _currentTotalAssets) /
            _currentTotalShares;

        if (withdrawAssetsAmount == 0) revert ZeroWithdrawAssetsAmount();

        balanceOf[msg.sender] = _userSharesAmount - withdrawSharesAmount;
        totalShares = _currentTotalShares - withdrawSharesAmount;
        asset.safeTransfer(msg.sender, withdrawAssetsAmount);

        emit Withdrawn(msg.sender, withdrawAssetsAmount, withdrawSharesAmount);
    }
}
