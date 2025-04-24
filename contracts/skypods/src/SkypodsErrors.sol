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

contract SkypodsErrors {
    error AdminDoesntExist();
    error AdminAlreadyExists();
    error CannotRemoveSelf();
    error NotAdmin();
    error OnlyAgentContract();
    error AgentAlreadyExists();
    error AgentDoesntExist();
    error ContractDoesntExist();
    error ContractAlreadyExists();
    error PoolAlreadyExists();
    error PoolDoesntExist();
    error TokenDoesntExist();
    error TokenAlreadyExists();

    error NotVerifiedContract();
    error InvalidFunds();

    error NotAgent();
    error NotAgentOwner();
    error NotAgentCreator();
    error NotAgentOrAdmin();
    error AgentStillActive();
    error InvalidScore();
    error InvalidAmount();

    error TokenNotAccepted();
    error UseNotAllowed();
    error InvalidUseAmount();
    error NotVerifiedPool();
    error InvalidPercents();
    error OnlyFolkAccepted();
    error PoolDepositFailed();

    error InsufficientCycleBalance();
    error NoCycleRewards();
    error RewardClaimFailed();
    error BadUserInput();

    error TransferFailed();
}
