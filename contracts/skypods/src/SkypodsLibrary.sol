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

contract SkypodsLibrary {
    struct Agent {
        EnumerableSet.AddressSet wallets;
        EnumerableSet.AddressSet owners;
        string metadata;
        address creator;
        uint256 id;
        uint256 scorePositive;
        uint256 scoreNegative;
        uint256 active;
    }

    struct Snapshot {
        string data;
        uint256 blocktimestamp;
    }
}
