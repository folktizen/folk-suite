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

import "./FolksyLibrary.sol";
import "./FolksyErrors.sol";
import "./FolksyAccessControls.sol";
import "./FolksyAgents.sol";
import "./skypods/SkypodsAccessControls.sol";
import "./skypods/SkypodsAgentManager.sol";
import "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";

contract FolksyCollectionManager {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    mapping(address => EnumerableSet.UintSet) private _dropIdsByArtist;
    mapping(uint256 => FolksyLibrary.Collection) private _collections;
    mapping(uint256 => FolksyLibrary.Drop) private _drops;
    mapping(uint256 => mapping(address => uint256)) private _collectionPrices;
    mapping(address => EnumerableSet.UintSet) private _activeCollections;

    uint256 private _collectionCounter;
    uint256 private _dropCounter;
    address public market;
    FolksyAccessControls public accessControls;
    FolksyAgents public agents;
    SkypodsAccessControls public skypodsAccessControls;
    SkypodsAgentManager public skypodsAgentManager;

    event CollectionCreated(
        address artist,
        uint256 collectionId,
        uint256 indexed dropId
    );
    event CollectionPriceAdjusted(
        address sender,
        address token,
        uint256 collectionId,
        uint256 newPrice
    );
    event CollectionDropUpdated(
        address sender,
        uint256 collectionId,
        uint256 dropId,
        uint256 agentId
    );
    event DropCreated(address artist, uint256 indexed dropId);
    event DropDeleted(address sender, uint256 indexed dropId);
    event CollectionDeleted(address sender, uint256 indexed collectionId);
    event AgentDetailsUpdated(
        address sender,
        string[] customInstructions,
        uint256[] agentIds,
        uint256 collectionId
    );
    event CollectionDeactivated(address sender, uint256 collectionId);
    event CollectionActivated(address sender, uint256 collectionId);
    event Remixable(address sender, uint256 collectionId, bool remixable);

    modifier onlyMarket() {
        if (market != msg.sender) {
            revert FolksyErrors.OnlyMarketContract();
        }
        _;
    }

    modifier onlyAdmin() {
        if (!accessControls.isAdmin(msg.sender)) {
            revert FolksyErrors.NotAdmin();
        }
        _;
    }

    constructor(
        address payable _accessControls,
        address payable _skypodsAccessControls,
        address _skypodsAgentManager
    ) {
        accessControls = FolksyAccessControls(_accessControls);
        skypodsAccessControls = SkypodsAccessControls(_skypodsAccessControls);
        skypodsAgentManager = SkypodsAgentManager(_skypodsAgentManager);
    }

    function create(
        FolksyLibrary.CollectionInput memory collectionInput,
        FolksyLibrary.CollectionWorker[] memory workers,
        string memory dropMetadata,
        uint256 dropId
    ) external {
        if (
            collectionInput.remixId > 0 &&
            !_collections[collectionInput.remixId].remixable
        ) {
            revert FolksyErrors.CannotRemix();
        }

        if (
            collectionInput.agentIds.length != workers.length ||
            collectionInput.tokens.length != collectionInput.prices.length
        ) {
            revert FolksyErrors.BadUserInput();
        }

        for (uint8 i = 0; i < collectionInput.tokens.length; i++) {
            _checkToken(
                collectionInput.tokens[i],
                collectionInput.prices[i],
                collectionInput.collectionType,
                collectionInput.agentIds.length > 0
            );
        }

        for (uint8 i = 0; i < collectionInput.tokens.length; i++) {
            if (
                !skypodsAccessControls.isAcceptedToken(
                    collectionInput.tokens[i]
                )
            ) {
                revert FolksyErrors.TokenNotAccepted();
            }
        }

        uint256 _dropValue = dropId;

        if (_dropValue == 0) {
            _dropCounter++;
            _dropValue = _dropCounter;

            _drops[_dropValue].id = _dropValue;
            _drops[_dropValue].artist = msg.sender;
            _drops[_dropValue].metadata = dropMetadata;

            _dropIdsByArtist[msg.sender].add(_dropValue);
            emit DropCreated(msg.sender, _dropValue);
        } else {
            if (_drops[_dropValue].id != _dropValue) {
                revert FolksyErrors.DropInvalid();
            }
        }
        _collectionCounter++;

        _collections[_collectionCounter].id = _collectionCounter;
        _collections[_collectionCounter].dropId = _dropValue;
        _collections[_collectionCounter].metadata = collectionInput.metadata;
        _collections[_collectionCounter].artist = msg.sender;
        _collections[_collectionCounter].amount = collectionInput.amount;
        _collections[_collectionCounter].collectionType = collectionInput
            .collectionType;
        _collections[_collectionCounter].remixId = collectionInput.remixId;
        _collections[_collectionCounter].active = false;
        _collections[_collectionCounter].remixable = collectionInput.remixable;

        if (
            collectionInput.collectionType == FolksyLibrary.CollectionType.IRL
        ) {
            _collections[_collectionCounter].fulfillerId = collectionInput
                .fulfillerId;
        }

        if (skypodsAccessControls.isAgent(msg.sender)) {
            _collections[_collectionCounter].agent = true;

            if (collectionInput.remixId == 0) {
                _collections[_collectionCounter].forArtist = collectionInput
                    .forArtist;
            }
        }

        for (uint8 i = 0; i < collectionInput.agentIds.length; i++) {
            agents.addWorker(
                workers[i],
                collectionInput.agentIds[i],
                _collectionCounter
            );
        }

        for (uint8 i = 0; i < collectionInput.agentIds.length; i++) {
            _collections[_collectionCounter].agentIds.add(
                collectionInput.agentIds[i]
            );
        }

        for (uint8 i = 0; i < collectionInput.prices.length; i++) {
            _collectionPrices[_collectionCounter][
                collectionInput.tokens[i]
            ] = collectionInput.prices[i];
            _collections[_collectionCounter].erc20Tokens.add(
                collectionInput.tokens[i]
            );
        }

        _activeCollections[msg.sender].add(_collectionCounter);
        _drops[_dropValue].collectionIds.add(_collectionCounter);
        emit CollectionCreated(msg.sender, _collectionCounter, _dropValue);
    }

    function _checkToken(
        address token,
        uint256 price,
        FolksyLibrary.CollectionType collectionType,
        bool useAgent
    ) internal view {
        uint256 _base = accessControls.getTokenBase(token);
        if (
            (collectionType == FolksyLibrary.CollectionType.IRL &&
                price < _base) ||
            (price < accessControls.getTokenThreshold(token) && useAgent)
        ) {
            revert FolksyErrors.PriceTooLow();
        }
    }

    function updateCollectionWorkerAndDetails(
        FolksyLibrary.CollectionWorker[] memory workers,
        string[] memory customInstructions,
        uint256[] memory agentIds,
        uint256 collectionId,
        uint256 agentId
    ) public {
        _checkArtistOrAgentOwner(collectionId, agentId, false);

        if (
            agentIds.length != customInstructions.length ||
            workers.length != customInstructions.length
        ) {
            revert FolksyErrors.BadUserInput();
        }

        for (uint8 i = 0; i < agentIds.length; i++) {
            if (!_collections[collectionId].agentIds.contains(agentIds[i])) {
                revert FolksyErrors.CantChangeAgents();
            }
        }

        for (uint8 i = 0; i < workers.length; i++) {
            agents.updateWorker(workers[i], agentIds[i], collectionId);
        }

        emit AgentDetailsUpdated(
            msg.sender,
            customInstructions,
            agentIds,
            collectionId
        );
    }

    function adjustCollectionPrice(
        address token,
        uint256 collectionId,
        uint256 newPrice,
        uint256 agentId
    ) external {
        _checkArtistOrAgentOwner(collectionId, agentId, false);
        if (!_collections[collectionId].erc20Tokens.contains(token)) {
            revert FolksyErrors.TokenNotAccepted();
        }

        _checkToken(
            token,
            newPrice,
            _collections[collectionId].collectionType,
            _collections[collectionId].agentIds.length() > 0
        );

        _collectionPrices[collectionId][token] = newPrice;

        emit CollectionPriceAdjusted(msg.sender, token, collectionId, newPrice);
    }

    function deactivateCollection(
        uint256 collectionId,
        uint256 agentId
    ) external {
        _checkArtistOrAgentOwner(collectionId, agentId, false);
        if (!_collections[collectionId].active) {
            revert FolksyErrors.CollectionAlreadyDeactivated();
        }

        _collections[collectionId].active = false;
        _activeCollections[_collections[collectionId].artist].remove(
            collectionId
        );

        _updateAgentBalance(collectionId);

        emit CollectionDeactivated(msg.sender, collectionId);
    }

    function activateCollection(
        uint256 collectionId,
        uint256 agentId
    ) external {
        _checkArtistOrAgentOwner(collectionId, agentId, false);
        if (_collections[collectionId].active) {
            revert FolksyErrors.CollectionAlreadyActive();
        }

        _collections[collectionId].active = true;
        _activeCollections[_collections[collectionId].artist].add(collectionId);
        emit CollectionActivated(msg.sender, collectionId);
    }

    function deleteCollection(uint256 collectionId, uint256 agentId) external {
        address _artist = _checkArtistOrAgentOwner(
            collectionId,
            agentId,
            false
        );

        if (_collections[collectionId].amountSold > 0) {
            revert FolksyErrors.CantDeleteSoldCollection();
        }

        _updateAgentBalance(collectionId);

        uint256 _dropId = _collections[collectionId].dropId;

        if (_dropId != 0) {
            _drops[_dropId].collectionIds.remove(collectionId);
        }

        for (
            uint8 i = 0;
            i < _collections[collectionId].erc20Tokens.length();
            i++
        ) {
            delete _collectionPrices[collectionId][
                _collections[collectionId].erc20Tokens.at(i)
            ];
        }
        _activeCollections[_artist].remove(collectionId);
        delete _collections[collectionId];

        emit CollectionDeleted(msg.sender, collectionId);
    }

    function updateCollectionDrop(
        uint256 collectionId,
        uint256 dropId,
        uint256 agentId
    ) external {
        address _artist = _checkArtistOrAgentOwner(
            collectionId,
            agentId,
            false
        );
        if (!_dropIdsByArtist[_artist].contains(dropId)) {
            revert FolksyErrors.DropInvalid();
        }
        uint256 _oldDropId = _collections[collectionId].dropId;
        if (_oldDropId != 0) {
            _drops[_oldDropId].collectionIds.remove(collectionId);
        }

        _drops[dropId].collectionIds.add(collectionId);
        _collections[collectionId].dropId = dropId;

        emit CollectionDropUpdated(msg.sender, collectionId, dropId, agentId);
    }

    function deleteDrop(uint256 dropId, uint256 agentId) external {
        _checkArtistOrAgentOwner(dropId, agentId, true);
        uint256[] memory _collectionIds = _drops[dropId].collectionIds.values();
        for (uint8 i = 0; i < _collectionIds.length; i++) {
            _collections[_collectionIds[i]].dropId = 0;
        }

        _dropIdsByArtist[_drops[dropId].artist].remove(dropId);
        delete _drops[dropId];

        emit DropDeleted(msg.sender, dropId);
    }

    function updateData(
        uint256[] memory mintedTokenIds,
        uint256 collectionId,
        uint256 amount
    ) external onlyMarket {
        _collections[collectionId].amountSold += amount;
        for (uint8 i = 0; i < mintedTokenIds.length; i++) {
            _collections[collectionId].tokenIds.push(mintedTokenIds[i]);
        }

        if (
            _collections[collectionId].amountSold ==
            _collections[collectionId].amount
        ) {
            if (
                _activeCollections[_collections[collectionId].artist]
                    .length() == 1
            ) {
                _activeCollections[_collections[collectionId].artist].remove(
                    collectionId
                );
                _updateAgentBalance(collectionId);
            }
        }
    }

    function changeRemixable(
        uint256 collectionId,
        uint256 agentId,
        bool remixable
    ) external {
        _checkArtistOrAgentOwner(collectionId, agentId, false);
        _collections[collectionId].remixable = remixable;

        emit Remixable(msg.sender, collectionId, remixable);
    }

    function _updateAgentBalance(uint256 collectionId) internal {
        for (
            uint8 i = 0;
            i < _collections[collectionId].agentIds.length();
            i++
        ) {
            agents.removeWorker(
                _collections[collectionId].agentIds.at(i),
                collectionId
            );
            agents.transferBalance(
                _collections[collectionId].erc20Tokens.values(),
                _collections[collectionId].artist,
                _collections[collectionId].agentIds.at(i)
            );
        }
    }

    function _checkArtistOrAgentOwner(
        uint256 collectionId,
        uint256 agentId,
        bool drop
    ) internal view returns (address) {
        bool _revert = false;
        address _artist = address(0);

        _artist = _collections[collectionId].artist;
        if (drop) {
            _artist = _drops[collectionId].artist;
        }

        if (
            agentId > 0 &&
            skypodsAgentManager.getIsAgentWallet(_artist, agentId)
        ) {
            if (!skypodsAgentManager.getIsAgentOwner(msg.sender, agentId)) {
                _revert = true;
            }
        } else {
            if (_artist != msg.sender) {
                _revert = true;
            }
        }

        if (_revert) {
            revert FolksyErrors.NotArtist();
        }

        return _artist;
    }

    function getCollectionCount() public view returns (uint256) {
        return _collectionCounter;
    }

    function getDropCount() public view returns (uint256) {
        return _dropCounter;
    }

    function getDropCollectionIds(
        uint256 dropId
    ) public view returns (uint256[] memory) {
        return _drops[dropId].collectionIds.values();
    }

    function getDropMetadata(
        uint256 dropId
    ) public view returns (string memory) {
        return _drops[dropId].metadata;
    }

    function getDropIdsByArtist(
        address artist
    ) public view returns (uint256[] memory) {
        return _dropIdsByArtist[artist].values();
    }

    function getCollectionERC20Tokens(
        uint256 collectionId
    ) public view returns (address[] memory) {
        return _collections[collectionId].erc20Tokens.values();
    }

    function getCollectionERC20TokensSet(
        address token,
        uint256 collectionId
    ) public view returns (bool) {
        return _collections[collectionId].erc20Tokens.contains(token);
    }

    function getCollectionTokenPrice(
        address token,
        uint256 collectionId
    ) public view returns (uint256) {
        return _collectionPrices[collectionId][token];
    }

    function getCollectionTokenIds(
        uint256 collectionId
    ) public view returns (uint256[] memory) {
        return _collections[collectionId].tokenIds;
    }

    function getCollectionAgentIds(
        uint256 collectionId
    ) public view returns (uint256[] memory) {
        return _collections[collectionId].agentIds.values();
    }

    function getCollectionMetadata(
        uint256 collectionId
    ) public view returns (string memory) {
        return _collections[collectionId].metadata;
    }

    function getCollectionArtist(
        uint256 collectionId
    ) public view returns (address) {
        return _collections[collectionId].artist;
    }

    function getCollectionForArtist(
        uint256 collectionId
    ) public view returns (address) {
        return _collections[collectionId].forArtist;
    }

    function getCollectionDropId(
        uint256 collectionId
    ) public view returns (uint256) {
        return _collections[collectionId].dropId;
    }

    function getCollectionType(
        uint256 collectionId
    ) public view returns (FolksyLibrary.CollectionType) {
        return _collections[collectionId].collectionType;
    }

    function getCollectionAmount(
        uint256 collectionId
    ) public view returns (uint256) {
        return _collections[collectionId].amount;
    }

    function getCollectionFulfillerId(
        uint256 collectionId
    ) public view returns (uint256) {
        return _collections[collectionId].fulfillerId;
    }

    function getCollectionAmountSold(
        uint256 collectionId
    ) public view returns (uint256) {
        return _collections[collectionId].amountSold;
    }

    function getCollectionRemixId(
        uint256 collectionId
    ) public view returns (uint256) {
        return _collections[collectionId].remixId;
    }

    function getCollectionIsActive(
        uint256 collectionId
    ) public view returns (bool) {
        return _collections[collectionId].active;
    }

    function getCollectionIsRemixable(
        uint256 collectionId
    ) public view returns (bool) {
        return _collections[collectionId].remixable;
    }

    function getCollectionIsByAgent(
        uint256 collectionId
    ) public view returns (bool) {
        return _collections[collectionId].agent;
    }

    function getArtistActiveCollections(
        address artist
    ) public view returns (uint256[] memory) {
        return _activeCollections[artist].values();
    }

    function setMarket(address _market) external onlyAdmin {
        market = _market;
    }

    function setAccessControls(
        address payable _accessControls
    ) external onlyAdmin {
        accessControls = FolksyAccessControls(_accessControls);
    }

    function setSkypodsAccessControls(
        address payable _skypodsAccessControls
    ) external onlyAdmin {
        skypodsAccessControls = SkypodsAccessControls(_skypodsAccessControls);
    }

    function setSkypodsAgentManager(
        address payable _skypodsAgentManager
    ) external onlyAdmin {
        skypodsAgentManager = SkypodsAgentManager(_skypodsAgentManager);
    }

    function setAgents(address payable _agents) external onlyAdmin {
        agents = FolksyAgents(_agents);
    }
}
