// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract BurnyToken is ERC20, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    address public constant burnAddress = address(0);
    bool public isBurningEnabled;
    bool public isRewardDistributionEnabled;
    uint256 public burnRate = 4; // 4% burn rate
    uint256 public rewardRate = 1; // 1% reward rate
    mapping(address => bool) private excludeFromBurn;
    mapping(address => bool) private includeInRewards;
    EnumerableSet.AddressSet private _holders;

    constructor() ERC20("Burny", "BURNY") {
        _mint(msg.sender, 10000000 * 10**decimals());
        isBurningEnabled = true;
        isRewardDistributionEnabled = true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        if (isBurningEnabled && recipient != burnAddress && !excludeFromBurn[sender]) {
            uint256 burnAmount = amount * burnRate / 100;
            uint256 transferAmount = amount - burnAmount;
            uint256 rewardAmount = transferAmount * rewardRate / 100;

            super._burn(sender, burnAmount);
            super._transfer(sender, recipient, transferAmount);

            if (isRewardDistributionEnabled && rewardAmount > 0) {
                distributeRewards(recipient, rewardAmount);
            }
        } else {
            super._transfer(sender, recipient, amount);
        }
    }

    function distributeRewards(address recipient, uint256 rewardAmount) private {
        uint256 totalRewardShares;
        uint256 totalHolders = _holders.length();

        for (uint256 i = 0; i < totalHolders; i++) {
            address holder = _holders.at(i);
            if (includeInRewards[holder]) {
                totalRewardShares += balanceOf(holder);
            }
        }

        for (uint256 i = 0; i < totalHolders; i++) {
            address holder = _holders.at(i);
            if (includeInRewards[holder]) {
                uint256 proportionalReward = rewardAmount * balanceOf(holder) / totalRewardShares;
                super._transfer(recipient, holder, proportionalReward);
            }
        }
    }

    function disableBurn() external onlyOwner {
        require(isBurningEnabled, "Burning is already disabled");
        isBurningEnabled = false;
    }

    function enableBurn() external onlyOwner {
        require(!isBurningEnabled, "Burning is already enabled");
        isBurningEnabled = true;
    }

    function disableRewardDistribution() external onlyOwner {
        require(isRewardDistributionEnabled, "Reward distribution is already disabled");
        isRewardDistributionEnabled = false;
    }

    function enableRewardDistribution() external onlyOwner {
        require(!isRewardDistributionEnabled, "Reward distribution is already enabled");
        isRewardDistributionEnabled = true;
    }

    function includeAddressInRewards(address account) external onlyOwner {
        includeInRewards[account] = true;
        _holders.add(account);
    }

    function excludeAddressFromRewards(address account) external onlyOwner {
        includeInRewards[account] = false;
        _holders.remove(account);
    }

    function burn(uint256 amount) external onlyOwner {
        _burn(msg.sender, amount);
    }
}
