// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

//////////////////////////////////////////////////////////////////////////////////////
// @title   Folktizen
// @notice  Folktizen is a vibrant marketplace on Lens where creators can mint
//          their collections and assign customizable agents to manage and promote
//          them. These agents can be tailored with specific activation frequencies,
//          custom instructions, and other essential criteria.​
//          more at: https://folktizen.xyz
// @version 0.5.0
// @author  Folktizen Labs
//////////////////////////////////////////////////////////////////////////////////////

interface IPool {
    function claimCycleRewards() external;

    function depositToPool(uint256 amount) external;

    function cleanCycle(uint256 cycle) external;

    function getUserCurrentCycleRewards(
        address user
    ) external view returns (uint256);

    function getUserRewardsByCycle(
        address user,
        uint256 cycle
    ) external view returns (uint256);

    function getUserCurrentCycleBalances(
        address user
    ) external view returns (uint256);

    function getUserBalancesByCycle(
        address user,
        uint256 cycle
    ) external view returns (uint256);

    function getUserClaimedByCycle(
        address user,
        uint256 cycle
    ) external view returns (bool);

    function getAdditionalTokensUserBalancesByCycle(
        address user,
        address token,
        uint256 cycle
    ) external view returns (uint256);

    function getAdditionalTokensUserCurrentCycleBalances(
        address user,
        address token
    ) external view returns (uint256);

    function getCycleCounter() external view returns (uint256);

    function getPoolBalance() external view returns (uint256);

    function getPoolHistoricalBalance() external view returns (uint256);

    function getActiveTokens() external view returns (address[] memory);

    function getTotalRewardsByCycle(
        uint256 cycle
    ) external view returns (uint256);

    function getHistoricalPoolBalanceByToken(
        address token
    ) external view returns (uint256);

    function getPoolBalanceByToken(
        address token
    ) external view returns (uint256);

    function getCycleUsers(
        uint256 cycle
    ) external view returns (address[] memory);

    function setAccessControls(address payable _accessControls) external;

    function setUserManager(address payable _userManager) external;

    function setPoolManager(address payable _poolManager) external;

    function setFolkAddress(address _folk) external;

    function setDevTreasuryAddress(address _devTreasury) external;

    function emergencyWithdraw(uint256 amount) external;

    function setCycleUser(address user, uint256 reward) external;

    function setCycleUsers(
        address[] memory users,
        uint256[] memory rewards
    ) external;
}
