// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/skypods/SkypodsAccessControls.sol";
import "../src/skypods/SkypodsAgentManager.sol";
import "../src/FolksyAccessControls.sol";
import "../src/FolksyFulfillerManager.sol";
import "../src/FolksyNFT.sol";
import "../src/FolksyCollectionManager.sol";
import "../src/FolksyAgents.sol";
import "../src/FolksyMarket.sol";
import "../src/AgentFeedRule.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();

        SkypodsAccessControls skypodsAC = new SkypodsAccessControls();
        console2.log("SkypodsAccessControls deployed:", address(skypodsAC));

        SkypodsAgentManager skypodsAgents = new SkypodsAgentManager(
            payable(address(skypodsAC))
        );
        console2.log("SkypodsAgentManager deployed:", address(skypodsAgents));

        FolksyAccessControls folksyAC = new FolksyAccessControls(
            payable(address(skypodsAC))
        );
        console2.log("FolksyAccessControls deployed:", address(folksyAC));

        FolksyFulfillerManager folksyFulfiller = new FolksyFulfillerManager(
            payable(address(folksyAC))
        );
        console2.log(
            "FolksyFulfillerManager deployed:",
            address(folksyFulfiller)
        );

        FolksyNFT folksyNFT = new FolksyNFT(
            "Folksy NFT",
            "FOLKSY",
            payable(address(folksyAC))
        );
        console2.log("FolksyNFT deployed:", address(folksyNFT));

        FolksyCollectionManager folksyCollection = new FolksyCollectionManager(
            payable(address(folksyAC)),
            payable(address(skypodsAC)),
            payable(address(skypodsAgents))
        );
        console2.log(
            "FolksyCollectionManager deployed:",
            address(folksyCollection)
        );

        FolksyAgents folksyAgents = new FolksyAgents(
            payable(address(folksyAC)),
            payable(address(folksyCollection)),
            payable(address(skypodsAC)),
            payable(address(skypodsAgents))
        );
        console2.log("FolksyAgents deployed:", address(folksyAgents));

        FolksyMarket folksyMarket = new FolksyMarket(
            payable(address(folksyNFT)),
            payable(address(folksyCollection)),
            payable(address(folksyAC)),
            payable(address(folksyAgents)),
            payable(address(folksyFulfiller)),
            payable(address(skypodsAC)),
            payable(address(skypodsAgents))
        );
        console2.log("FolksyMarket deployed:", address(folksyMarket));

        AgentFeedRule agentFeedRule = new AgentFeedRule(
            payable(address(skypodsAC))
        );
        console2.log("AgentFeedRule deployed:", address(agentFeedRule));

        vm.stopBroadcast();

        console2.log("\n--- DEPLOYED FOLKSY CONTRACTS ---\n");
        console2.log(
            string.concat(
                "{\n",
                '  "accessControls": "',
                vm.toString(address(folksyAC)),
                '",\n',
                '  "fulfillerManager": "',
                vm.toString(address(folksyFulfiller)),
                '",\n',
                '  "nft": "',
                vm.toString(address(folksyNFT)),
                '",\n',
                '  "collectionManager": "',
                vm.toString(address(folksyCollection)),
                '",\n',
                '  "agents": "',
                vm.toString(address(folksyAgents)),
                '",\n',
                '  "market": "',
                vm.toString(address(folksyMarket)),
                '",\n',
                '  "agentFeedRule": "',
                vm.toString(address(agentFeedRule)),
                '"\n',
                "}"
            )
        );

        console2.log("\n--- DEPLOYED SKYPODS CONTRACTS ---\n");
        console2.log(
            string.concat(
                "{\n",
                '  "accessControls": "',
                vm.toString(address(skypodsAC)),
                '",\n',
                '  "agentManager": "',
                vm.toString(address(skypodsAgents)),
                '"\n',
                "}"
            )
        );
    }
}
