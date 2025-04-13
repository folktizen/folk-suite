// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.24;

contract SkypodErrors {
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
    error OnlyNovoAccepted();
    error PoolDepositFailed();

    error InsufficientCycleBalance();
    error NoCycleRewards();
    error RewardClaimFailed();
    error BadUserInput();

    error TransferFailed();
}
