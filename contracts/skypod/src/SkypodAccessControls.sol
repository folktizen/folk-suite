// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.24;

import "./SkypodErrors.sol";
import "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";

contract SkypodAccessControls {
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
            revert SkypodErrors.NotAdmin();
        }
        _;
    }

    modifier onlyAgentOrAdmin() {
        if (!_admins[msg.sender] && !_agents[msg.sender]) {
            revert SkypodErrors.NotAgentOrAdmin();
        }
        _;
    }

    modifier onlyAgentContractOrAdmin() {
        if (msg.sender != agentsContract && !_admins[msg.sender]) {
            revert SkypodErrors.OnlyAgentContract();
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
        name = "SkypodAccessControls";
        symbol = "SAC";
    }

    function addAdmin(address admin) external onlyAdmin {
        if (_admins[admin]) {
            revert SkypodErrors.AdminAlreadyExists();
        }
        _admins[admin] = true;
        emit AdminAdded(admin);
    }

    function removeAdmin(address admin) external onlyAdmin {
        if (!_admins[admin]) {
            revert SkypodErrors.AdminDoesntExist();
        }

        if (admin == msg.sender) {
            revert SkypodErrors.CannotRemoveSelf();
        }

        _admins[admin] = false;
        emit AdminRemoved(admin);
    }

    function addVerifiedContract(address verifiedContract) external onlyAdmin {
        if (_verifiedContracts[verifiedContract]) {
            revert SkypodErrors.ContractAlreadyExists();
        }
        _verifiedContracts[verifiedContract] = true;
        _verifiedContractsList.add(verifiedContract);
        emit VerifiedContractAdded(verifiedContract);
    }

    function removeVerifiedContract(
        address verifiedContract
    ) external onlyAdmin {
        if (!_verifiedContracts[verifiedContract]) {
            revert SkypodErrors.ContractDoesntExist();
        }

        _verifiedContractsList.remove(verifiedContract);
        _verifiedContracts[verifiedContract] = false;
        emit VerifiedContractRemoved(verifiedContract);
    }

    function addVerifiedPool(address verifiedPool) external onlyAdmin {
        if (_verifiedPools[verifiedPool]) {
            revert SkypodErrors.PoolAlreadyExists();
        }
        _verifiedPools[verifiedPool] = true;
        _verifiedPoolsList.add(verifiedPool);
        emit VerifiedPoolAdded(verifiedPool);
    }

    function removeVerifiedPool(address verifiedPool) external onlyAdmin {
        if (!_verifiedPools[verifiedPool]) {
            revert SkypodErrors.PoolDoesntExist();
        }

        _verifiedPoolsList.remove(verifiedPool);

        _verifiedPools[verifiedPool] = false;
        emit VerifiedPoolRemoved(verifiedPool);
    }

    function setAcceptedToken(address token) external onlyAdmin {
        if (_acceptedTokens[token]) {
            revert SkypodErrors.TokenAlreadyExists();
        }

        _acceptedTokensList.add(token);

        _acceptedTokens[token] = true;

        emit AcceptedTokenSet(token);
    }

    function removeAcceptedToken(address token) external onlyAdmin {
        if (!_acceptedTokens[token]) {
            revert SkypodErrors.TokenDoesntExist();
        }

        _acceptedTokensList.remove(token);

        delete _acceptedTokens[token];

        emit AcceptedTokenRemoved(token);
    }

    function addAgent(address agent) external onlyAgentContractOrAdmin {
        if (_agents[agent]) {
            revert SkypodErrors.AgentAlreadyExists();
        }
        _agents[agent] = true;
        emit AgentAdded(agent);
    }

    function removeAgent(address agent) external onlyAgentContractOrAdmin {
        if (!_agents[agent]) {
            revert SkypodErrors.AgentDoesntExist();
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
            revert SkypodErrors.TransferFailed();
        }
    }

    receive() external payable {}

    fallback() external payable {}
}
