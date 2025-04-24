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

import "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";

contract FolksyLibrary {
    enum CollectionType {
        Digital,
        IRL
    }

    struct Collection {
        EnumerableSet.AddressSet erc20Tokens;
        EnumerableSet.UintSet agentIds;
        uint256[] tokenIds;
        string metadata;
        address artist;
        address forArtist;
        uint256 id;
        uint256 fulfillerId;
        uint256 dropId;
        uint256 amount;
        uint256 amountSold;
        uint256 remixId;
        CollectionType collectionType;
        bool active;
        bool remixable;
        bool agent;
    }

    struct Drop {
        EnumerableSet.UintSet collectionIds;
        string metadata;
        address artist;
        uint256 id;
    }

    struct CollectionInput {
        address[] tokens;
        uint256[] prices;
        uint256[] agentIds;
        string metadata;
        address forArtist;
        CollectionType collectionType;
        uint256 amount;
        uint256 fulfillerId;
        uint256 remixId;
        bool remixable;
    }

    struct Agent {
        EnumerableSet.UintSet collectionIdsHistory;
        EnumerableSet.UintSet activeCollectionIds;
    }

    struct CollectionWorker {
        string instructions;
        uint256 publishFrequency;
        uint256 remixFrequency;
        uint256 leadFrequency;
        uint256 mintFrequency;
        bool publish;
        bool remix;
        bool lead;
        bool mint;
    }

    struct Order {
        uint256[] mintedTokens;
        string fulfillmentDetails;
        address token;
        uint256 amount;
        uint256 totalPrice;
        uint256 id;
        uint256 collectionId;
        bool fulfilled;
    }

    struct OrderRent {
        address buyer;
        uint256 blockTimestamp;
    }

    struct Fulfiller {
        EnumerableSet.UintSet activeOrders;
        uint256[] orderHistory;
        string metadata;
        address wallet;
        uint256 id;
    }

    struct FulfillerInput {
        string metadata;
        address wallet;
    }

    struct ShareResponse {
        address remixArtist;
        uint256 remixShare;
        uint256 agentShare;
        uint256 perAgentShare;
        uint256 artistShare;
    }
}
