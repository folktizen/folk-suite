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

import "./SkypodsErrors.sol";
import "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";

contract SkypodsAccessControls {
    using EnumerableSet for EnumerableSet.AddressSet;
    address public agentsContract;
    string public symbol;
    string public name;
    EnumerableSet.AddressSet private _verifiedContractsList;
    EnumerableSet.AddressSet private _verifiedPoolsList;
    EnumerableSet.AddressSet private _acceptedTokensList;

    mapping(address => bool) private _admins;
    mapping(address => bool) private _verifiedContracts;
    mapping(address => bool) private _verifiedPools;
    mapping(address => bool) private _agents;
    mapping(address => bool) private _acceptedTokens;

    modifier onlyAdmin() {
        if (!_admins[msg.sender]) {
            revert SkypodsErrors.NotAdmin();
        }
        _;
    }

    modifier onlyAgentOrAdmin() {
        if (!_admins[msg.sender] && !_agents[msg.sender]) {
            revert SkypodsErrors.NotAgentOrAdmin();
        }
        _;
    }

    modifier onlyAgentContractOrAdmin() {
        if (msg.sender != agentsContract && !_admins[msg.sender]) {
            revert SkypodsErrors.OnlyAgentContract();
        }
        _;
    }

    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event VerifiedContractAdded(address indexed verifiedContract);
    event VerifiedContractRemoved(address indexed verifiedContract);
    event VerifiedPoolAdded(address indexed pool);
    event VerifiedPoolRemoved(address indexed pool);
    event AgentAdded(address indexed agent);
    event AgentRemoved(address indexed agent);
    event AcceptedTokenSet(address token);
    event AcceptedTokenRemoved(address token);

    constructor() payable {
        _admins[msg.sender] = true;
        name = "SkypodsAccessControls";
        symbol = "SAC";
    }

    function addAdmin(address admin) external onlyAdmin {
        if (_admins[admin]) {
            revert SkypodsErrors.AdminAlreadyExists();
        }
        _admins[admin] = true;
        emit AdminAdded(admin);
    }

    function removeAdmin(address admin) external onlyAdmin {
        if (!_admins[admin]) {
            revert SkypodsErrors.AdminDoesntExist();
        }

        if (admin == msg.sender) {
            revert SkypodsErrors.CannotRemoveSelf();
        }

        _admins[admin] = false;
        emit AdminRemoved(admin);
    }

    function addVerifiedContract(address verifiedContract) external onlyAdmin {
        if (_verifiedContracts[verifiedContract]) {
            revert SkypodsErrors.ContractAlreadyExists();
        }
        _verifiedContracts[verifiedContract] = true;
        _verifiedContractsList.add(verifiedContract);
        emit VerifiedContractAdded(verifiedContract);
    }

    function removeVerifiedContract(
        address verifiedContract
    ) external onlyAdmin {
        if (!_verifiedContracts[verifiedContract]) {
            revert SkypodsErrors.ContractDoesntExist();
        }

        _verifiedContractsList.remove(verifiedContract);
        _verifiedContracts[verifiedContract] = false;
        emit VerifiedContractRemoved(verifiedContract);
    }

    function addVerifiedPool(address verifiedPool) external onlyAdmin {
        if (_verifiedPools[verifiedPool]) {
            revert SkypodsErrors.PoolAlreadyExists();
        }
        _verifiedPools[verifiedPool] = true;
        _verifiedPoolsList.add(verifiedPool);
        emit VerifiedPoolAdded(verifiedPool);
    }

    function removeVerifiedPool(address verifiedPool) external onlyAdmin {
        if (!_verifiedPools[verifiedPool]) {
            revert SkypodsErrors.PoolDoesntExist();
        }

        _verifiedPoolsList.remove(verifiedPool);

        _verifiedPools[verifiedPool] = false;
        emit VerifiedPoolRemoved(verifiedPool);
    }

    function setAcceptedToken(address token) external onlyAdmin {
        if (_acceptedTokens[token]) {
            revert SkypodsErrors.TokenAlreadyExists();
        }

        _acceptedTokensList.add(token);

        _acceptedTokens[token] = true;

        emit AcceptedTokenSet(token);
    }

    function removeAcceptedToken(address token) external onlyAdmin {
        if (!_acceptedTokens[token]) {
            revert SkypodsErrors.TokenDoesntExist();
        }

        _acceptedTokensList.remove(token);

        delete _acceptedTokens[token];

        emit AcceptedTokenRemoved(token);
    }

    function addAgent(address agent) external onlyAgentContractOrAdmin {
        if (_agents[agent]) {
            revert SkypodsErrors.AgentAlreadyExists();
        }
        _agents[agent] = true;
        emit AgentAdded(agent);
    }

    function removeAgent(address agent) external onlyAgentContractOrAdmin {
        if (!_agents[agent]) {
            revert SkypodsErrors.AgentDoesntExist();
        }

        _agents[agent] = false;
        emit AgentRemoved(agent);
    }

    function setAgentsContract(address _agentsContract) public onlyAdmin {
        agentsContract = _agentsContract;
    }

    function isAdmin(address admin) public view returns (bool) {
        return _admins[admin];
    }

    function isVerifiedContract(
        address verifiedContract
    ) public view returns (bool) {
        return _verifiedContracts[verifiedContract];
    }

    function isAgent(address _address) public view returns (bool) {
        return _agents[_address];
    }

    function isAcceptedToken(address token) public view returns (bool) {
        return _acceptedTokens[token];
    }

    function isPool(address token) public view returns (bool) {
        return _verifiedPools[token];
    }

    function getVerifiedContracts() public view returns (address[] memory) {
        return _verifiedContractsList.values();
    }

    function getVerifiedPools() public view returns (address[] memory) {
        return _verifiedPoolsList.values();
    }

    function getAcceptedTokens() public view returns (address[] memory) {
        return _acceptedTokensList.values();
    }

    function emergencyWithdraw(
        uint256 amount,
        uint256 gasAmount
    ) external onlyAdmin {
        (bool success, ) = payable(msg.sender).call{
            value: amount,
            gas: gasAmount
        }("");
        if (!success) {
            revert SkypodsErrors.TransferFailed();
        }
    }

    receive() external payable {}

    fallback() external payable {}
}
