// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "./../src/FolksyCollectionManager.sol";
import "./../src/FolksyAccessControls.sol";
import "./../src/FolksyErrors.sol";
import "./../src/FolksyLibrary.sol";
import "./../src/FolksyNFT.sol";
import "./../src/FolksyFulfillerManager.sol";
import "./../src/skypods/SkypodsAccessControls.sol";
import "./../src/skypods/SkypodsAgentManager.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract FolksyCollectionManagerTest is Test {
    FolksyCollectionManager private collectionManager;
    FolksyAccessControls private accessControls;
    FolksyFulfillerManager private fulfillerManager;
    SkypodsAccessControls private skypodsAccess;
    SkypodsAgentManager private skypodsAgent;
    FolksyAgents private agents;
    FolksyNFT private nft;
    address private admin = address(0x123);
    address private artist = address(0x456);
    address private market = address(0x789);
    address private fulfiller = address(0x1324);

    MockERC20 private token1;
    MockERC20 private token2;

    function setUp() public {
        skypodsAccess = new SkypodsAccessControls();
        skypodsAgent = new SkypodsAgentManager(payable(address(skypodsAccess)));
        accessControls = new FolksyAccessControls(
            payable(address(skypodsAccess))
        );
        collectionManager = new FolksyCollectionManager(
            payable(address(accessControls)),
            payable(address(skypodsAccess)),
            address(skypodsAgent)
        );
        nft = new FolksyNFT("NFT", "NFT", payable(address(accessControls)));
        fulfillerManager = new FolksyFulfillerManager(
            payable(address(accessControls))
        );
        agents = new FolksyAgents(
            payable(address(accessControls)),
            address(collectionManager),
            payable(address(skypodsAccess)),
            address(skypodsAgent)
        );
        token1 = new MockERC20("Token1", "TK1");
        token2 = new MockERC20("Token2", "TK2");
        skypodsAccess.setAcceptedToken(address(token1));
        skypodsAccess.setAcceptedToken(address(token2));
        skypodsAccess.setAgentsContract(address(skypodsAgent));
        accessControls.addAdmin(admin);
        accessControls.addFulfiller(fulfiller);
        accessControls.setTokenDetails(
            address(token1),
            10000000000000000000,
            1500000000000000000,
            6000000000000000000,
            4000000000000000000,
            8000000000000000000,
            6,
            20000000000000000000
        );
        accessControls.setTokenDetails(
            address(token2),
            100000000000000000,
            10000000000000000,
            50000000000000000,
            30000000000000000,
            7000000000000000000,
            10,
            2000000000000000000
        );

        vm.startPrank(admin);

        agents.setMarket(address(market));
        agents.setAmounts(30, 30, 40);

        collectionManager.setMarket(address(market));
        collectionManager.setAgents(payable(address(agents)));
        nft.setMarket(address(market));

        fulfillerManager.setMarket(address(market));
        vm.stopPrank();

        vm.startPrank(fulfiller);
        fulfillerManager.createFulfillerProfile(
            FolksyLibrary.FulfillerInput({
                metadata: "fulfiller metadata",
                wallet: fulfiller
            })
        );

        vm.stopPrank();
    }

    function testCreateDropAndCollections() public {
        vm.startPrank(artist);
        FolksyLibrary.CollectionInput memory inputs_1 = FolksyLibrary
            .CollectionInput({
                tokens: new address[](2),
                prices: new uint256[](2),
                agentIds: new uint256[](3),
                metadata: "Metadata 1",
                amount: 1,
                collectionType: FolksyLibrary.CollectionType.Digital,
                fulfillerId: 1,
                remixId: 0,
                remixable: true,
                forArtist: address(0)
            });
        inputs_1.tokens[0] = address(token1);
        inputs_1.tokens[1] = address(token2);
        inputs_1.prices[0] = 10000000000000000000;
        inputs_1.prices[1] = 25000000000000000000;
        inputs_1.agentIds[0] = 1;
        inputs_1.agentIds[1] = 3;
        inputs_1.agentIds[2] = 5;

        FolksyLibrary.CollectionInput memory inputs_2 = FolksyLibrary
            .CollectionInput({
                tokens: new address[](1),
                prices: new uint256[](1),
                agentIds: new uint256[](1),
                metadata: "Metadata 2",
                amount: 10,
                collectionType: FolksyLibrary.CollectionType.Digital,
                fulfillerId: 1,
                remixId: 0,
                remixable: true,
                forArtist: address(0)
            });

        inputs_2.tokens[0] = address(token2);
        inputs_2.prices[0] = 13200000000000000000;
        inputs_2.agentIds[0] = 3;

        FolksyLibrary.CollectionWorker[]
            memory workers_1 = new FolksyLibrary.CollectionWorker[](3);

        workers_1[0] = FolksyLibrary.CollectionWorker({
            publish: true,
            remix: true,
            lead: true,
            publishFrequency: 1,
            remixFrequency: 1,
            leadFrequency: 1,
            mintFrequency: 1,
            mint: true,
            instructions: "instruction 1"
        });
        workers_1[1] = FolksyLibrary.CollectionWorker({
            publish: true,
            remix: true,
            lead: true,
            publishFrequency: 1,
            remixFrequency: 1,
            leadFrequency: 1,
            mintFrequency: 1,
            mint: true,
            instructions: "instruction 2"
        });
        workers_1[2] = FolksyLibrary.CollectionWorker({
            publish: true,
            remix: true,
            lead: true,
            publishFrequency: 1,
            remixFrequency: 1,
            leadFrequency: 1,
            mintFrequency: 1,
            mint: true,
            instructions: "instruction 3"
        });

        FolksyLibrary.CollectionWorker[]
            memory workers_2 = new FolksyLibrary.CollectionWorker[](1);

        workers_2[0] = FolksyLibrary.CollectionWorker({
            publish: true,
            remix: true,
            lead: true,
            publishFrequency: 1,
            remixFrequency: 1,
            leadFrequency: 1,
            mintFrequency: 1,
            mint: true,
            instructions: "instruction 4"
        });

        collectionManager.create(inputs_1, workers_1, "some drop URI", 0);
        collectionManager.create(inputs_2, workers_2, "", 1);

        uint256[] memory dropIds = collectionManager.getDropIdsByArtist(artist);
        assertEq(dropIds.length, 1);
        assertEq(dropIds[0], 1);

        uint256[] memory collectionIds = collectionManager.getDropCollectionIds(
            1
        );
        assertEq(collectionIds.length, 2);
        assertEq(
            collectionManager.getCollectionMetadata(collectionIds[0]),
            "Metadata 1"
        );
        assertEq(
            collectionManager.getCollectionMetadata(collectionIds[1]),
            "Metadata 2"
        );
        assertEq(
            collectionManager.getCollectionERC20Tokens(collectionIds[0])[0],
            address(token1)
        );
        assertEq(
            collectionManager.getCollectionERC20Tokens(collectionIds[0])[1],
            address(token2)
        );

        assertEq(
            collectionManager.getCollectionTokenPrice(
                address(token1),
                collectionIds[0]
            ),
            10000000000000000000
        );
        assertEq(
            collectionManager.getCollectionTokenPrice(
                address(token2),
                collectionIds[0]
            ),
            25000000000000000000
        );
        assertEq(
            collectionManager.getCollectionAgentIds(collectionIds[0])[0],
            1
        );
        assertEq(
            collectionManager.getCollectionAgentIds(collectionIds[0])[1],
            3
        );
        assertEq(
            collectionManager.getCollectionAgentIds(collectionIds[0])[2],
            5
        );
        assertEq(collectionManager.getCollectionAmount(collectionIds[0]), 1);

        assertEq(
            collectionManager.getCollectionMetadata(collectionIds[1]),
            "Metadata 2"
        );
        assertEq(
            collectionManager.getCollectionERC20Tokens(collectionIds[1])[0],
            address(token2)
        );
        assertEq(
            collectionManager.getCollectionTokenPrice(
                address(token2),
                collectionIds[1]
            ),
            13200000000000000000
        );
        assertEq(
            collectionManager.getCollectionAgentIds(collectionIds[1])[0],
            3
        );
        assertEq(collectionManager.getCollectionAmount(collectionIds[1]), 10);

        assertEq(
            agents.getWorkerInstructions(1, collectionIds[0]),
            "instruction 1"
        );
        assertEq(
            agents.getWorkerInstructions(3, collectionIds[0]),
            "instruction 2"
        );
        assertEq(
            agents.getWorkerInstructions(5, collectionIds[0]),
            "instruction 3"
        );

        vm.stopPrank();
    }

    function testCreateCollectionExistingDrop() public {
        testCreateDropAndCollections();

        vm.startPrank(artist);
        FolksyLibrary.CollectionInput memory inputs_1 = FolksyLibrary
            .CollectionInput({
                tokens: new address[](2),
                prices: new uint256[](2),
                agentIds: new uint256[](3),
                metadata: "Metadata 1",
                amount: 1,
                collectionType: FolksyLibrary.CollectionType.Digital,
                fulfillerId: 1,
                remixId: 0,
                remixable: true,
                forArtist: address(0)
            });
        inputs_1.tokens[0] = address(token1);
        inputs_1.tokens[1] = address(token2);
        inputs_1.prices[0] = 10000000000000000000;
        inputs_1.prices[1] = 25000000000000000000;
        inputs_1.agentIds[0] = 1;
        inputs_1.agentIds[1] = 3;
        inputs_1.agentIds[2] = 5;

        FolksyLibrary.CollectionInput memory inputs_2 = FolksyLibrary
            .CollectionInput({
                tokens: new address[](1),
                prices: new uint256[](1),
                agentIds: new uint256[](1),
                metadata: "Metadata 2",
                amount: 10,
                collectionType: FolksyLibrary.CollectionType.Digital,
                fulfillerId: 1,
                remixId: 0,
                remixable: true,
                forArtist: address(0)
            });

        inputs_2.tokens[0] = address(token2);
        inputs_2.prices[0] = 13200000000000000000;
        inputs_2.agentIds[0] = 3;

        FolksyLibrary.CollectionWorker[]
            memory workers_1 = new FolksyLibrary.CollectionWorker[](3);

        workers_1[0] = FolksyLibrary.CollectionWorker({
            publish: true,
            remix: true,
            lead: true,
            publishFrequency: 1,
            remixFrequency: 1,
            leadFrequency: 1,
            instructions: "instruction 1",
            mintFrequency: 1,
            mint: true
        });
        workers_1[1] = FolksyLibrary.CollectionWorker({
            publish: true,
            remix: true,
            lead: true,
            publishFrequency: 1,
            remixFrequency: 1,
            leadFrequency: 1,
            instructions: "instruction 2",
            mintFrequency: 1,
            mint: true
        });
        workers_1[2] = FolksyLibrary.CollectionWorker({
            publish: true,
            remix: true,
            lead: true,
            publishFrequency: 1,
            remixFrequency: 1,
            leadFrequency: 1,
            instructions: "instruction 3",
            mintFrequency: 1,
            mint: true
        });

        FolksyLibrary.CollectionWorker[]
            memory workers_2 = new FolksyLibrary.CollectionWorker[](1);

        workers_2[0] = FolksyLibrary.CollectionWorker({
            publish: true,
            remix: true,
            lead: true,
            publishFrequency: 1,
            remixFrequency: 1,
            leadFrequency: 1,
            instructions: "instruction 4",
            mintFrequency: 1,
            mint: true
        });

        collectionManager.create(inputs_1, workers_1, "", 1);
        collectionManager.create(inputs_2, workers_2, "", 1);

        uint256[] memory dropIds = collectionManager.getDropIdsByArtist(artist);

        assertEq(dropIds.length, 1);
        assertEq(dropIds[0], 1);

        uint256[] memory collectionIds = collectionManager.getDropCollectionIds(
            1
        );
        assertEq(collectionIds.length, 4);

        vm.expectRevert(
            abi.encodeWithSelector(FolksyErrors.DropInvalid.selector)
        );
        collectionManager.create(inputs_1, workers_1, "", 2);
    }

    function testDeleteCollection() public {
        testCreateDropAndCollections();

        vm.startPrank(artist);
        collectionManager.deleteCollection(1, 0);

        vm.startPrank(admin);
        vm.expectRevert(
            abi.encodeWithSelector(FolksyErrors.NotArtist.selector)
        );
        collectionManager.deleteCollection(2, 0);

        uint256[] memory dropIds = collectionManager.getDropIdsByArtist(artist);
        assertEq(dropIds.length, 1);
        assertEq(dropIds[0], 1);

        uint256[] memory collectionIds = collectionManager.getDropCollectionIds(
            1
        );
        assertEq(collectionIds.length, 1);
        assertEq(collectionIds[0], 2);

        vm.startPrank(artist);
        collectionManager.deleteCollection(2, 0);

        uint256[] memory dropIds_saved = collectionManager.getDropIdsByArtist(
            artist
        );
        assertEq(dropIds_saved.length, 1);
    }

    function testDeleteDrop() public {
        testCreateDropAndCollections();
        uint256[] memory dropIds_first = collectionManager.getDropIdsByArtist(
            artist
        );
        assertEq(dropIds_first.length, 1);

        vm.startPrank(artist);
        collectionManager.deleteDrop(1, 0);

        uint256[] memory dropIds = collectionManager.getDropIdsByArtist(artist);
        assertEq(dropIds.length, 0);
    }

    function testSetMarket() public {
        vm.startPrank(admin);
        collectionManager.setMarket(address(0x1234));
        assertEq(collectionManager.market(), address(0x1234));
        vm.stopPrank();
    }

    function testSetAccessControls() public {
        FolksyAccessControls newAccessControls = new FolksyAccessControls(
            payable(address(skypodsAccess))
        );
        vm.startPrank(admin);
        collectionManager.setAccessControls(
            payable(address(newAccessControls))
        );
        assertEq(
            address(collectionManager.accessControls()),
            address(newAccessControls)
        );
        vm.stopPrank();
    }

    function testOnlyMarketModifier() public {
        vm.prank(artist);
        uint256[] memory mintedTokenIds = new uint256[](1);
        mintedTokenIds[0] = 1;
        vm.expectRevert(
            abi.encodeWithSelector(FolksyErrors.OnlyMarketContract.selector)
        );
        collectionManager.updateData(mintedTokenIds, 1, 1);
    }

    function testOnlyAdminModifier() public {
        vm.prank(artist);
        vm.expectRevert(abi.encodeWithSelector(FolksyErrors.NotAdmin.selector));
        collectionManager.setMarket(address(0x1234));
    }
}
