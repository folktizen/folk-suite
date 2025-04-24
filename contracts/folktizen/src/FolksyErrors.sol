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

contract FolksyErrors {
    error NotAdmin();
    error AlreadyAdmin();
    error CannotRemoveSelf();
    error AdminDoesntExist();
    error AdminAlreadyExists();
    error TokenAlreadyExists();
    error TokenDoesntExist();
    error InsufficientFunds();
    error TransferFailed();
    error FulfillerAlreadyExists();
    error FulfillerDoesntExist();
    error OnlyCollectionContract();

    error DropInvalid();
    error CannotRemix();

    error OnlyMarketContract();
    error OnlyMarketOrAgentContract();
    error ZeroAddress();
    error InvalidAmount();
    error NotArtist();
    error CantDeleteSoldCollection();
    error PriceTooLow();
    error OnlyFulfillerManager();
    error OnlyPoolManagerContract();
    error BadUserInput();

    error NotAvailable();
    error TokenNotAccepted();
    error PaymentFailed();

    error OnlyAgentsContract();
    error NotAgentOwner();
    error NotAgentCreator();
    error InvalidWorker();
    error NotAgent();
    error InsufficientBalance();
    error NoActiveAgents();
    error CollectionSoldOut();
    error InvalidWallet();
    error AgentCantBuyIRL();
    error NotAgentWallet();
    error CantChangeAgents();

    error CollectionAlreadyDeactivated();
    error CollectionAlreadyActive();
    error CollectionNotActive();

    error NotFulfiller();
    error ActiveOrders();

    error OnlyCollector();
    error NoShares();
}
