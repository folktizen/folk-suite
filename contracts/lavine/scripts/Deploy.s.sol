// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/LavineWorkflows.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();

        LavineWorkflows lavineWorkflows = new LavineWorkflows();
        console2.log("LavineWorkflows deployed:", address(lavineWorkflows));

        vm.stopBroadcast();

        console2.log("\n--- DEPLOYED LAVINE CONTRACTS ---\n");
        console2.log(
            string.concat(
                "{\n",
                '  "workflows": "',
                vm.toString(address(lavineWorkflows)),
                '"\n',
                "}"
            )
        );
    }
}
