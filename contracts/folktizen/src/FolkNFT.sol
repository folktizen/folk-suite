// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.24;

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

import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "./FolkErrors.sol";
import "./FolkAccessControls.sol";

contract FolkNFT is ERC721 {
    uint256 private _tokenCounter;
    address public market;
    FolkAccessControls public accessControls;
    mapping(uint256 => string) private _tokenURIs;

    modifier onlyAdmin() {
        if (!accessControls.isAdmin(msg.sender)) {
            revert FolkErrors.NotAdmin();
        }
        _;
    }

    event NFTMinted(
        address indexed to,
        uint256 indexed tokenId,
        string tokenURI
    );

    modifier onlyMarket() {
        if (msg.sender != market) {
            revert FolkErrors.OnlyMarketContract();
        }
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address payable _accessControls
    ) payable ERC721(name, symbol) {
        accessControls = FolkAccessControls(_accessControls);
    }

    function mint(
        uint256 amount,
        address to,
        string memory newTokenURI
    ) external onlyMarket returns (uint256[] memory) {
        if (to == address(0)) {
            revert FolkErrors.ZeroAddress();
        }

        if (amount <= 0) {
            revert FolkErrors.InvalidAmount();
        }

        uint256[] memory mintedTokenIds = new uint256[](amount);

        for (uint8 i = 0; i < amount; i++) {
            _tokenCounter++;
            uint256 _newTokenId = _tokenCounter;

            _safeMint(to, _newTokenId);
            _tokenURIs[_newTokenId] = newTokenURI;

            mintedTokenIds[i] = _newTokenId;
            emit NFTMinted(to, _newTokenId, newTokenURI);
        }

        return mintedTokenIds;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        return _tokenURIs[tokenId];
    }

    function getTokenCounter() public view returns (uint256) {
        return _tokenCounter;
    }

    function setMarket(address _market) external onlyAdmin {
        market = _market;
    }

    function setAccessControls(
        address payable _accessControls
    ) external onlyAdmin {
        accessControls = FolkAccessControls(_accessControls);
    }
}
