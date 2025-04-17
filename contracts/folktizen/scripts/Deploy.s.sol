// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/skypod/SkypodAccessControls.sol";
import "../src/skypod/SkypodAgentManager.sol";
import "../src/FolkAccessControls.sol";
import "../src/FolkFulfillerManager.sol";
import "../src/FolkNFT.sol";
import "../src/FolkCollectionManager.sol";
import "../src/FolkAgents.sol";
import "../src/FolkMarket.sol";
import "../src/AgentFeedRule.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        SkypodAccessControls skypodAC = new SkypodAccessControls();
        console2.log("SkypodAccessControls deployed:", address(skypodAC));

        SkypodAgentManager skypodAgents = new SkypodAgentManager(
            payable(address(skypodAC))
        );
        console2.log("SkypodAgentManager deployed:", address(skypodAgents));

        FolkAccessControls folkAC = new FolkAccessControls(
            payable(address(skypodAC))
        );
        console2.log("FolkAccessControls deployed:", address(folkAC));

        FolkFulfillerManager folkFulfiller = new FolkFulfillerManager(
            payable(address(folkAC))
        );
        console2.log("FolkFulfillerManager deployed:", address(folkFulfiller));

        FolkNFT folkNFT = new FolkNFT(
            "Folk NFT",
            "FOLK",
            payable(address(folkAC))
        );
        console2.log("FolkNFT deployed:", address(folkNFT));

        FolkCollectionManager folkCollection = new FolkCollectionManager(
            payable(address(folkAC)),
            payable(address(skypodAC)),
            payable(address(skypodAgents))
        );
        console2.log(
            "FolkCollectionManager deployed:",
            address(folkCollection)
        );

        FolkAgents folkAgents = new FolkAgents(
            payable(address(folkAC)),
            payable(address(folkCollection)),
            payable(address(skypodAC)),
            payable(address(skypodAgents))
        );
        console2.log("FolkAgents deployed:", address(folkAgents));

        FolkMarket folkMarket = new FolkMarket(
            payable(address(folkNFT)),
            payable(address(folkCollection)),
            payable(address(folkAC)),
            payable(address(folkAgents)),
            payable(address(folkFulfiller)),
            payable(address(skypodAC)),
            payable(address(skypodAgents))
        );
        console2.log("FolkMarket deployed:", address(folkMarket));

        AgentFeedRule agentFeedRule = new AgentFeedRule(
            payable(address(skypodAC))
        );
        console2.log("AgentFeedRule deployed:", address(agentFeedRule));

        vm.stopBroadcast();

        console2.log("\n--- DEPLOYED FOLK CONTRACTS ---");
        console2.log(
            string.concat(
                "{\n",
                '  "accessControls": "',
                vm.toString(address(folkAC)),
                '",\n',
                '  "fulfillerManager": "',
                vm.toString(address(folkFulfiller)),
                '",\n',
                '  "nft": "',
                vm.toString(address(folkNFT)),
                '",\n',
                '  "collectionManager": "',
                vm.toString(address(folkCollection)),
                '",\n',
                '  "agents": "',
                vm.toString(address(folkAgents)),
                '",\n',
                '  "market": "',
                vm.toString(address(folkMarket)),
                '",\n',
                '  "agentFeedRule": "',
                vm.toString(address(agentFeedRule)),
                '",\n',
                "}"
            )
        );

        console2.log("\n--- DEPLOYED SKYPOD CONTRACTS ---");
        console2.log(
            string.concat(
                "{\n",
                '  "accessControls": "',
                vm.toString(address(skypodAC)),
                '",\n',
                '  "agentManager": "',
                vm.toString(address(skypodAgents)),
                '"\n',
                "}"
            )
        );
    }
}
