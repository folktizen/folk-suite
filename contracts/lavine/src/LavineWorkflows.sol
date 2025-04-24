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

import "./LavineLibrary.sol";
import "./LavineErrors.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract LavineWorkflows {
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 public workflowCounter;

    modifier onlyCreator(uint256 counter) {
        if (!_workflowsToCreator[msg.sender].contains(counter)) {
            revert LavineErrors.NotCreator();
        }
        _;
    }

    mapping(uint256 => LavineLibrary.Workflow) private _workflows;
    mapping(address => EnumerableSet.UintSet) private _workflowsToCreator;

    event WorkflowCreated(
        string workflowMetadata,
        address creator,
        uint256 counter
    );
    event WorkflowDeleted(uint256 counter);

    function createWorkflow(string memory workflowMetadata) public {
        workflowCounter++;

        _workflows[workflowCounter] = LavineLibrary.Workflow({
            workflowMetadata: workflowMetadata,
            counter: workflowCounter,
            creator: msg.sender
        });
        _workflowsToCreator[msg.sender].add(workflowCounter);

        emit WorkflowCreated(workflowMetadata, msg.sender, workflowCounter);
    }

    function deleteWorkflow(uint256 counter) public onlyCreator(counter) {
        delete _workflows[counter];

        _workflowsToCreator[msg.sender].remove(counter);

        emit WorkflowDeleted(counter);
    }

    function getWorkflowCreator(uint256 counter) public view returns (address) {
        return _workflows[counter].creator;
    }

    function getWorkflowMetadata(
        uint256 counter
    ) public view returns (string memory) {
        return _workflows[counter].workflowMetadata;
    }

    function getCreatorWorkflows(
        address creator
    ) public view returns (uint256[] memory) {
        return _workflowsToCreator[creator].values();
    }
}
