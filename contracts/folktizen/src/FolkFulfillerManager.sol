// SPDX-License-Identifier: UNLICENSE
pragma solidity 0.8.24;

import "./FolkErrors.sol";
import "./FolkAccessControls.sol";
import "./FolkLibrary.sol";
import "./FolkMarket.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";

contract FolkFulfillerManager {
    using EnumerableSet for EnumerableSet.UintSet;

    FolkAccessControls public accessControls;
    FolkMarket public market;
    uint256 private _fulfillerCounter;
    mapping(uint256 => FolkLibrary.Fulfiller) private _fulfillers;

    modifier onlyAdmin() {
        if (!accessControls.isAdmin(msg.sender)) {
            revert FolkErrors.NotAdmin();
        }
        _;
    }

    modifier onlyFulfiller() {
        if (!accessControls.isFulfiller(msg.sender)) {
            revert FolkErrors.NotFulfiller();
        }

        _;
    }

    modifier onlyAdminOrMarket() {
        if (
            !accessControls.isAdmin(msg.sender) && msg.sender != address(market)
        ) {
            revert FolkErrors.NotAdmin();
        }
        _;
    }

    event OrderAdded(uint256 fulfillerId, uint256 orderId);
    event FulfillerCreated(address wallet, uint256 fulfillerId);
    event FulfillerDeleted(uint256 fulfillerId);
    event OrderFulfilled(uint256 fulfillerId, uint256 orderId);

    constructor(address payable _accessControls) payable {
        accessControls = FolkAccessControls(_accessControls);
        _fulfillerCounter = 0;
    }

    function createFulfillerProfile(
        FolkLibrary.FulfillerInput memory input
    ) public onlyFulfiller {
        _fulfillerCounter++;

        _fulfillers[_fulfillerCounter].id = _fulfillerCounter;
        _fulfillers[_fulfillerCounter].wallet = input.wallet;
        _fulfillers[_fulfillerCounter].metadata = input.metadata;

        emit FulfillerCreated(input.wallet, _fulfillerCounter);
    }

    function deleteFulfillerProfile(uint256 fulfillerId) public onlyFulfiller {
        if (_fulfillers[fulfillerId].wallet != msg.sender) {
            revert FolkErrors.NotFulfiller();
        }

        if (_fulfillers[fulfillerId].activeOrders.length() > 0) {
            revert FolkErrors.ActiveOrders();
        }

        delete _fulfillers[fulfillerId];

        emit FulfillerDeleted(fulfillerId);
    }

    function addOrder(
        uint256 fulfillerId,
        uint256 orderId
    ) external onlyAdminOrMarket {
        _fulfillers[fulfillerId].activeOrders.add(orderId);
        _fulfillers[fulfillerId].orderHistory.push(orderId);

        emit OrderAdded(fulfillerId, orderId);
    }

    function fulfillOrder(uint256 fulfillerId, uint256 orderId) public {
        if (_fulfillers[fulfillerId].wallet != msg.sender) {
            revert FolkErrors.NotFulfiller();
        }

        _fulfillers[fulfillerId].activeOrders.remove(orderId);

        market.fulfillIRLOrder(orderId);

        emit OrderFulfilled(fulfillerId, orderId);
    }

    function getFulfillerActiveOrders(
        uint256 fulfillerId
    ) public view returns (uint256[] memory) {
        return _fulfillers[fulfillerId].activeOrders.values();
    }

    function getFulfillerOrderHistory(
        uint256 fulfillerId
    ) public view returns (uint256[] memory) {
        return _fulfillers[fulfillerId].orderHistory;
    }

    function getFulfillerWallet(
        uint256 fulfillerId
    ) public view returns (address) {
        return _fulfillers[fulfillerId].wallet;
    }

    function getFulfillerMetadata(
        uint256 fulfillerId
    ) public view returns (string memory) {
        return _fulfillers[fulfillerId].metadata;
    }

    function getFulfillerCounter() public view returns (uint256) {
        return _fulfillerCounter;
    }

    function setAccessControls(
        address payable _accessControls
    ) external onlyAdmin {
        accessControls = FolkAccessControls(_accessControls);
    }

    function setMarket(address _market) external onlyAdmin {
        market = FolkMarket(_market);
    }
}
