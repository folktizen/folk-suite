// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

//////////////////////////////////////////////////////////////////////////////////////
// @title   Folktizen
// @notice  Folktizen is a vibrant marketplace on Polygon where creators can mint
//          their collections and assign customizable agents to manage and promote
//          them. These agents can be tailored with specific activation frequencies,
//          custom instructions, and other essential criteria.​
//          more at: https://folktizen.xyz
// @version 0.5.0
// @author  Folktizen Labs
//////////////////////////////////////////////////////////////////////////////////////

import "./../SkypodAccessControls.sol";
import "./../SkypodLibrary.sol";

contract TokenSnapshots {
    SkypodAccessControls public accessControls;
    mapping(address => mapping(uint256 => SkypodLibrary.Snapshot))
        private _snapshots;

    event SnapshotSet(string data, address verifiedContract, uint256 cycle);

    modifier onlyAdmin() {
        if (!accessControls.isAdmin(msg.sender)) {
            revert SkypodErrors.NotAdmin();
        }
        _;
    }

    constructor(address payable _accessControls) {
        accessControls = SkypodAccessControls(_accessControls);
    }

    function setSnapshot(
        string memory data,
        address verifiedContract,
        uint256 cycle
    ) public onlyAdmin {
        _snapshots[verifiedContract][cycle] = SkypodLibrary.Snapshot({
            blocktimestamp: block.timestamp,
            data: data
        });

        emit SnapshotSet(data, verifiedContract, cycle);
    }

    function getSnapshotTimestamp(
        address verifiedContract,
        uint256 cycle
    ) public view returns (uint256) {
        return _snapshots[verifiedContract][cycle].blocktimestamp;
    }

    function getSnapshotData(
        address verifiedContract,
        uint256 cycle
    ) public view returns (string memory) {
        return _snapshots[verifiedContract][cycle].data;
    }

    function setAccessControls(
        address payable _accessControls
    ) public onlyAdmin {
        accessControls = SkypodAccessControls(_accessControls);
    }
}
