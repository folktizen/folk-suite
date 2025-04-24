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

import "./FolksyErrors.sol";
import "./FolksyLibrary.sol";
import "./FolksyAccessControls.sol";
import "./FolksyCollectionManager.sol";
import "./FolksyMarket.sol";
import "./skypods/SkypodsAgentManager.sol";
import "./skypods/SkypodsAccessControls.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";

contract FolksyAgents {
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 public ownerAmountPercent;
    uint256 public distributionAmountPercent;
    uint256 public devAmountPercent;
    FolksyAccessControls public accessControls;
    FolksyMarket public market;
    SkypodsAccessControls public skypodsAccessControls;
    SkypodsAgentManager public agentManager;
    FolksyCollectionManager public collectionManager;
    address public poolManager;

    mapping(uint256 => FolksyLibrary.Agent) private _activatedAgents;
    mapping(uint256 => mapping(address => mapping(uint256 => uint256)))
        private _agentRentBalances;
    mapping(uint256 => mapping(address => mapping(uint256 => uint256)))
        private _agentHistoricalRentBalances;
    mapping(uint256 => mapping(address => mapping(uint256 => uint256)))
        private _agentBonusBalances;
    mapping(uint256 => mapping(address => mapping(uint256 => uint256)))
        private _agentHistoricalBonusBalances;
    mapping(uint256 => mapping(uint256 => FolksyLibrary.CollectionWorker))
        private _workers;
    mapping(address => uint256) private _services;
    mapping(address => uint256) private _allTimeServices;
    mapping(address => mapping(address => mapping(uint256 => uint256)))
        private _collectorPayment;
    mapping(address => mapping(address => mapping(uint256 => uint256)))
        private _ownerPayment;
    mapping(address => uint256) private _devPayment;
    mapping(address => uint256) private _currentRewards;
    mapping(address => uint256) private _rewardsHistory;
    mapping(uint256 => mapping(address => mapping(address => uint256)))
        private _artistCollectBalanceByToken;

    event ActivateAgent(address wallet, uint256 agentId);
    event BalanceAdded(
        address token,
        uint256 agentId,
        uint256 amount,
        uint256 collectionId
    );
    event ArtistCollectBalanceAdded(
        address forArtist,
        address token,
        uint256 agentId,
        uint256 amount
    );
    event ArtistPaid(
        address forArtist,
        address token,
        uint256 agentId,
        uint256 collectionId,
        uint256 amount
    );
    event ArtistCollectBalanceSpent(
        address forArtist,
        address to,
        address token,
        uint256 agentId,
        uint256 collectionId,
        uint256 amount
    );
    event BalanceTransferred(address artist, uint256 agentId);
    event AgentMarketWalletEdited(address wallet, uint256 agentId);
    event RewardsCalculated(address token, uint256 amount);
    event AgentPaidRent(
        address[] tokens,
        uint256[] collectionIds,
        uint256[] amounts,
        uint256[] bonuses,
        uint256 indexed agentId
    );
    event AgentRecharged(
        address recharger,
        address token,
        uint256 agentId,
        uint256 collectionId,
        uint256 amount
    );
    event ServicesAdded(address token, uint256 amount);
    event WorkerAdded(uint256 agentId, uint256 collectionId);
    event WorkerUpdated(uint256 agentId, uint256 collectionId);
    event WorkerRemoved(uint256 agentId, uint256 collectionId);
    event ServicesWithdrawn(address token, uint256 amount);
    event CollectorPaid(
        address collector,
        address token,
        uint256 amount,
        uint256 collectionId
    );
    event OwnerPaid(
        address owner,
        address token,
        uint256 amount,
        uint256 collectionId
    );
    event DevTreasuryPaid(address token, uint256 amount, uint256 collectionId);

    modifier onlyAdmin() {
        if (!accessControls.isAdmin(msg.sender)) {
            revert FolksyErrors.NotAdmin();
        }
        _;
    }

    modifier onlyAgentOwnerOrCreator(uint256 agentId) {
        if (
            !agentManager.getIsAgentOwner(msg.sender, agentId) &&
            agentManager.getAgentCreator(agentId) != msg.sender
        ) {
            revert FolksyErrors.NotAgentOwner();
        }

        _;
    }

    modifier onlyAgentCreator(uint256 agentId) {
        if (agentManager.getAgentCreator(agentId) != msg.sender) {
            revert FolksyErrors.NotAgentCreator();
        }
        _;
    }

    modifier onlyMarket() {
        if (address(market) != msg.sender) {
            revert FolksyErrors.OnlyMarketContract();
        }
        _;
    }

    modifier onlyCollectionManager() {
        if (address(collectionManager) != msg.sender) {
            revert FolksyErrors.OnlyCollectionContract();
        }
        _;
    }

    modifier onlyValidWorker(FolksyLibrary.CollectionWorker memory worker) {
        if (!worker.remix && !worker.publish && !worker.lead && !worker.mint) {
            revert FolksyErrors.InvalidWorker();
        }
        _;
    }

    constructor(
        address payable _accessControls,
        address _collectionManager,
        address payable _skypodsAccessControls,
        address _agentManager
    ) payable {
        accessControls = FolksyAccessControls(_accessControls);
        collectionManager = FolksyCollectionManager(_collectionManager);
        skypodsAccessControls = SkypodsAccessControls(_skypodsAccessControls);
        agentManager = SkypodsAgentManager(_agentManager);
    }

    function activateAgent(
        uint256 agentId
    ) external onlyAgentOwnerOrCreator(agentId) {
        agentManager.setAgentActive(agentId);

        emit ActivateAgent(msg.sender, agentId);
    }

    function addWorker(
        FolksyLibrary.CollectionWorker memory worker,
        uint256 agentId,
        uint256 collectionId
    ) external onlyCollectionManager onlyValidWorker(worker) {
        _workers[agentId][collectionId] = worker;

        emit WorkerAdded(agentId, collectionId);
    }

    function updateWorker(
        FolksyLibrary.CollectionWorker memory worker,
        uint256 agentId,
        uint256 collectionId
    ) external onlyCollectionManager onlyValidWorker(worker) {
        _workers[agentId][collectionId] = worker;

        emit WorkerUpdated(agentId, collectionId);
    }

    function removeWorker(
        uint256 agentId,
        uint256 collectionId
    ) external onlyCollectionManager {
        address[] memory _tokens = skypodsAccessControls.getAcceptedTokens();

        for (uint8 i = 0; i < _tokens.length; i++) {
            if (_agentRentBalances[agentId][_tokens[i]][collectionId] > 0) {
                _services[_tokens[i]] += (_agentRentBalances[agentId][
                    _tokens[i]
                ][collectionId] +
                    _agentBonusBalances[agentId][_tokens[i]][collectionId]);

                _agentRentBalances[agentId][_tokens[i]][collectionId] = 0;
                _agentBonusBalances[agentId][_tokens[i]][collectionId] = 0;
            }
        }

        delete _workers[agentId][collectionId];

        emit WorkerRemoved(agentId, collectionId);
    }

    function transferBalance(
        address[] memory tokens,
        address artist,
        uint256 agentId
    ) external onlyCollectionManager {
        for (uint8 i = 0; i < tokens.length; i++) {
            _services[tokens[i]] += _artistCollectBalanceByToken[agentId][
                tokens[i]
            ][artist];
            _allTimeServices[tokens[i]] += _artistCollectBalanceByToken[
                agentId
            ][tokens[i]][artist];
            _artistCollectBalanceByToken[agentId][tokens[i]][artist] = 0;
        }

        emit BalanceTransferred(artist, agentId);
    }

    function addArtistCollectBalance(
        address forArtist,
        address token,
        uint256 agentId,
        uint256 amount
    ) external onlyMarket {
        _artistCollectBalanceByToken[agentId][token][forArtist] += amount;

        emit ArtistCollectBalanceAdded(forArtist, token, agentId, amount);
    }

    function spendArtistCollectBalance(
        address forArtist,
        address to,
        address token,
        uint256 agentId,
        uint256 amount,
        uint256 collectionId,
        bool spend
    ) external onlyMarket {
        if (amount > _artistCollectBalanceByToken[agentId][token][forArtist]) {
            revert FolksyErrors.InsufficientBalance();
        }

        if (spend) {
            if (!IERC20(token).transfer(address(to), amount)) {
                revert FolksyErrors.PaymentFailed();
            }
        }

        _artistCollectBalanceByToken[agentId][token][forArtist] -= amount;

        if (to == forArtist) {
            emit ArtistPaid(forArtist, token, agentId, collectionId, amount);
        } else {
            emit ArtistCollectBalanceSpent(
                forArtist,
                to,
                token,
                agentId,
                collectionId,
                amount
            );
        }
    }

    function addBalance(
        address token,
        uint256 agentId,
        uint256 amount,
        uint256 collectionId,
        bool soldOut
    ) external onlyMarket {
        uint256 _bonus = 0;
        uint256 _rent = _handleRent(token, agentId, collectionId);

        if (amount >= _rent) {
            _bonus = amount - _rent;
        }

        _agentRentBalances[agentId][token][collectionId] += _rent;
        _agentHistoricalRentBalances[agentId][token][collectionId] += _rent;
        _agentBonusBalances[agentId][token][collectionId] += _bonus;
        _agentHistoricalBonusBalances[agentId][token][collectionId] += _bonus;

        if (
            !_activatedAgents[agentId].activeCollectionIds.contains(
                collectionId
            ) && !soldOut
        ) {
            _activatedAgents[agentId].activeCollectionIds.add(collectionId);
        } else if (soldOut) {
            _activatedAgents[agentId].activeCollectionIds.remove(collectionId);
        }

        if (
            !_activatedAgents[agentId].collectionIdsHistory.contains(
                collectionId
            )
        ) {
            _activatedAgents[agentId].collectionIdsHistory.add(collectionId);
        }

        emit BalanceAdded(token, agentId, amount, collectionId);
    }

    function addRemixServices(
        address token,
        uint256 amount
    ) external onlyMarket {
        _services[token] += amount;
        _allTimeServices[token] += amount;

        emit ServicesAdded(token, amount);
    }

    function payRent(
        address[] memory tokens,
        uint256[] memory collectionIds,
        uint256 agentId
    ) external {
        if (collectionIds.length != tokens.length) {
            revert FolksyErrors.BadUserInput();
        }

        if (!skypodsAccessControls.isAgent(msg.sender)) {
            revert FolksyErrors.NotAgent();
        }

        uint256[] memory _amounts = new uint256[](collectionIds.length);
        uint256[] memory _bonuses = new uint256[](collectionIds.length);
        for (uint8 i = 0; i < collectionIds.length; i++) {
            _amounts[i] = _handleRent(tokens[i], agentId, collectionIds[i]);

            if (
                _agentRentBalances[agentId][tokens[i]][collectionIds[i]] <
                _amounts[i]
            ) {
                revert FolksyErrors.InsufficientBalance();
            }

            if (!collectionManager.getCollectionIsActive(collectionIds[i])) {
                revert FolksyErrors.CollectionNotActive();
            }

            if (
                _activatedAgents[agentId].activeCollectionIds.length() < 1 ||
                !_activatedAgents[agentId].activeCollectionIds.contains(
                    collectionIds[i]
                )
            ) {
                revert FolksyErrors.NoActiveAgents();
            }

            _agentRentBalances[agentId][tokens[i]][
                collectionIds[i]
            ] -= _amounts[i];

            _bonuses[i] = _agentBonusBalances[agentId][tokens[i]][
                collectionIds[i]
            ];

            _agentBonusBalances[agentId][tokens[i]][collectionIds[i]] = 0;
        }

        address[] memory _owners = agentManager.getAgentOwners(agentId);

        for (uint8 i = 0; i < collectionIds.length; i++) {
            _services[tokens[i]] += _amounts[i];
            _allTimeServices[tokens[i]] += _amounts[i];
            if (_bonuses[i] > 0) {
                _handleBonus(_owners, tokens[i], _bonuses[i], collectionIds[i]);
            }
        }

        emit AgentPaidRent(tokens, collectionIds, _amounts, _bonuses, agentId);
    }

    function _handleRent(
        address token,
        uint256 agentId,
        uint256 collectionId
    ) internal view returns (uint256) {
        uint256 _rent = 0;

        if (_workers[agentId][collectionId].remix) {
            _rent += accessControls.getTokenCycleRentRemix(token);
        }

        if (_workers[agentId][collectionId].lead) {
            _rent += accessControls.getTokenCycleRentLead(token);
        }

        if (_workers[agentId][collectionId].publish) {
            _rent += accessControls.getTokenCycleRentPublish(token);
        }

        if (_workers[agentId][collectionId].mint) {
            _rent += accessControls.getTokenCycleRentMint(token);
        }

        return _rent;
    }

    function _handleBonus(
        address[] memory owners,
        address token,
        uint256 bonus,
        uint256 collectionId
    ) internal {
        _currentRewards[token] += bonus;
        _rewardsHistory[token] += bonus;

        uint256 _ownerAmount = (bonus * ownerAmountPercent) / 100;
        uint256 _devAmount = (bonus * devAmountPercent) / 100;
        uint256 _distributionAmount = (bonus * distributionAmountPercent) / 100;
        address[] memory _collectors = market.getAllCollectorsByCollectionId(
            collectionId
        );

        uint256 totalWeight = 0;
        for (uint256 j = 1; j <= _collectors.length; j++) {
            totalWeight += 1e18 / j;
        }

        for (uint256 j = 0; j < _collectors.length; j++) {
            if (_collectors[j] != address(0)) {
                uint256 weight = 1e18 / (j + 1);
                uint256 payment = (_distributionAmount * weight) / totalWeight;

                IERC20(token).transfer(_collectors[j], payment);

                _collectorPayment[token][_collectors[j]][
                    collectionId
                ] += payment;

                emit CollectorPaid(
                    _collectors[j],
                    token,
                    payment,
                    collectionId
                );
            }
        }

        for (uint8 i = 0; i < owners.length; i++) {
            IERC20(token).transfer(owners[i], _ownerAmount / owners.length);

            _ownerPayment[token][owners[i]][collectionId] +=
                _ownerAmount /
                owners.length;

            emit OwnerPaid(
                owners[i],
                token,
                _ownerAmount / owners.length,
                collectionId
            );
        }

        _devPayment[token] += _devAmount;

        emit DevTreasuryPaid(token, _devAmount, collectionId);
    }

    function rechargeAgentRentBalance(
        address token,
        uint256 agentId,
        uint256 collectionId,
        uint256 amount
    ) public {
        if (
            collectionManager.getCollectionAmountSold(collectionId) >=
            collectionManager.getCollectionAmount(collectionId)
        ) {
            revert FolksyErrors.CollectionSoldOut();
        }
        uint256[] memory _ids = collectionManager.getCollectionAgentIds(
            collectionId
        );

        if (_ids.length < 1) {
            revert FolksyErrors.NoActiveAgents();
        } else {
            bool _notAgent = false;

            for (uint8 i = 0; i < _ids.length; i++) {
                if (_ids[i] == agentId) {
                    _notAgent = true;
                }
            }

            if (!_notAgent) {
                revert FolksyErrors.NoActiveAgents();
            }
        }

        if (
            !collectionManager.getCollectionERC20TokensSet(token, collectionId)
        ) {
            revert FolksyErrors.TokenNotAccepted();
        }

        if (!IERC20(token).transferFrom(msg.sender, address(this), amount)) {
            revert FolksyErrors.PaymentFailed();
        } else {
            _agentRentBalances[agentId][token][collectionId] += amount;
            _agentHistoricalRentBalances[agentId][token][
                collectionId
            ] += amount;

            if (
                !_activatedAgents[agentId].activeCollectionIds.contains(
                    collectionId
                )
            ) {
                _activatedAgents[agentId].activeCollectionIds.add(collectionId);
            }

            if (
                !_activatedAgents[agentId].collectionIdsHistory.contains(
                    collectionId
                )
            ) {
                _activatedAgents[agentId].collectionIdsHistory.add(
                    collectionId
                );
            }

            emit AgentRecharged(
                msg.sender,
                token,
                agentId,
                collectionId,
                amount
            );
        }
    }

    function withdrawServices(address token) public onlyAdmin {
        uint256 _amount = _services[token];
        if (IERC20(token).balanceOf(address(this)) > 0) {
            if (_services[token] < IERC20(token).balanceOf(address(this))) {
                _amount = IERC20(token).balanceOf(address(this));
            }

            IERC20(token).transfer(msg.sender, _amount);
        }

        _services[token] = 0;
        emit ServicesWithdrawn(token, _amount);
    }

    function getAgentRentBalance(
        address token,
        uint256 agentId,
        uint256 collectionId
    ) public view returns (uint256) {
        return _agentRentBalances[agentId][token][collectionId];
    }

    function getAgentHistoricalRentBalance(
        address token,
        uint256 agentId,
        uint256 collectionId
    ) public view returns (uint256) {
        return _agentHistoricalRentBalances[agentId][token][collectionId];
    }

    function getAgentHistoricalBonusBalance(
        address token,
        uint256 agentId,
        uint256 collectionId
    ) public view returns (uint256) {
        return _agentHistoricalBonusBalances[agentId][token][collectionId];
    }

    function getAgentBonusBalance(
        address token,
        uint256 agentId,
        uint256 collectionId
    ) public view returns (uint256) {
        return _agentBonusBalances[agentId][token][collectionId];
    }

    function getAllTimeServices(address token) public view returns (uint256) {
        return _allTimeServices[token];
    }

    function getServicesPaidByToken(
        address token
    ) public view returns (uint256) {
        return _services[token];
    }

    function getAgentCollectionIdsHistory(
        uint256 agentId
    ) public view returns (uint256[] memory) {
        return _activatedAgents[agentId].collectionIdsHistory.values();
    }

    function getAgentActiveCollectionIds(
        uint256 agentId
    ) public view returns (uint256[] memory) {
        return _activatedAgents[agentId].activeCollectionIds.values();
    }

    function getIsActiveCollectionId(
        uint256 agentId,
        uint256 collectionId
    ) public view returns (bool) {
        return
            _activatedAgents[agentId].activeCollectionIds.contains(
                collectionId
            );
    }

    function getCollectorPaymentByToken(
        address token,
        address collector,
        uint256 collectionId
    ) public view returns (uint256) {
        return _collectorPayment[token][collector][collectionId];
    }

    function getAgentOwnerPaymentByToken(
        address token,
        address owner,
        uint256 collectionId
    ) public view returns (uint256) {
        return _ownerPayment[token][owner][collectionId];
    }

    function getCurrentRewardsByToken(
        address token
    ) public view returns (uint256) {
        return _currentRewards[token];
    }

    function getRewardsHistoryByToken(
        address token
    ) public view returns (uint256) {
        return _rewardsHistory[token];
    }

    function getWorkerPublish(
        uint256 agentId,
        uint256 collectionId
    ) public view returns (bool) {
        return _workers[agentId][collectionId].publish;
    }

    function getWorkerMint(
        uint256 agentId,
        uint256 collectionId
    ) public view returns (bool) {
        return _workers[agentId][collectionId].mint;
    }

    function getWorkerLead(
        uint256 agentId,
        uint256 collectionId
    ) public view returns (bool) {
        return _workers[agentId][collectionId].lead;
    }

    function getWorkerRemix(
        uint256 agentId,
        uint256 collectionId
    ) public view returns (bool) {
        return _workers[agentId][collectionId].remix;
    }

    function getWorkerPublishFrequency(
        uint256 agentId,
        uint256 collectionId
    ) public view returns (uint256) {
        return _workers[agentId][collectionId].publishFrequency;
    }

    function getWorkerMintFrequency(
        uint256 agentId,
        uint256 collectionId
    ) public view returns (uint256) {
        return _workers[agentId][collectionId].mintFrequency;
    }

    function getWorkerLeadFrequency(
        uint256 agentId,
        uint256 collectionId
    ) public view returns (uint256) {
        return _workers[agentId][collectionId].leadFrequency;
    }

    function getWorkerRemixFrequency(
        uint256 agentId,
        uint256 collectionId
    ) public view returns (uint256) {
        return _workers[agentId][collectionId].remixFrequency;
    }

    function getWorkerInstructions(
        uint256 agentId,
        uint256 collectionId
    ) public view returns (string memory) {
        return _workers[agentId][collectionId].instructions;
    }

    function getArtistCollectBalanceByToken(
        address artist,
        address token,
        uint256 agentId
    ) public view returns (uint256) {
        return _artistCollectBalanceByToken[agentId][token][artist];
    }

    function getDevPaymentByToken(address token) public view returns (uint256) {
        return _devPayment[token];
    }

    function setAccessControls(
        address payable _accessControls
    ) external onlyAdmin {
        accessControls = FolksyAccessControls(_accessControls);
    }

    function setAgentManager(address payable _agentManager) external onlyAdmin {
        agentManager = SkypodsAgentManager(_agentManager);
    }

    function setSkypodsAccessControls(
        address payable _skypodsAccessControls
    ) external onlyAdmin {
        skypodsAccessControls = SkypodsAccessControls(_skypodsAccessControls);
    }

    function setMarket(address _market) external onlyAdmin {
        market = FolksyMarket(_market);
    }

    function setCollectionManager(
        address _collectionManager
    ) external onlyAdmin {
        collectionManager = FolksyCollectionManager(_collectionManager);
    }

    function setAmounts(
        uint256 _ownerAmountPercent,
        uint256 _distributionAmountPercent,
        uint256 _devAmountPercent
    ) external onlyAdmin {
        if (
            _ownerAmountPercent +
                _distributionAmountPercent +
                _devAmountPercent !=
            100
        ) {
            revert FolksyErrors.BadUserInput();
        }
        ownerAmountPercent = _ownerAmountPercent;
        distributionAmountPercent = _distributionAmountPercent;
        devAmountPercent = _devAmountPercent;
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
