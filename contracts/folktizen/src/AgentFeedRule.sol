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

import "./skypod/SkypodAccessControls.sol";

struct KeyValue {
    bytes32 key;
    bytes value;
}

struct RuleSelectorChange {
    bytes4 ruleSelector;
    bool isRequired;
    bool enabled;
}

struct RuleConfigurationChange {
    bool configure;
    KeyValue[] ruleParams;
}

struct RuleChange {
    address ruleAddress;
    bytes32 configSalt;
    RuleConfigurationChange configurationChanges;
    RuleSelectorChange[] selectorChanges;
}

struct CreatePostParams {
    address author;
    string contentURI;
    uint256 repostedPostId;
    uint256 quotedPostId;
    uint256 repliedPostId;
    RuleChange[] ruleChanges;
    KeyValue[] extraData;
}

struct EditPostParams {
    string contentURI;
    KeyValue[] extraData;
}

struct RuleConfiguration {
    address ruleAddress;
    bytes configData;
    bool isRequired;
}

interface IFeedRule {
    function configure(
        bytes32 configSalt,
        KeyValue[] calldata ruleParams
    ) external;

    function processCreatePost(
        bytes32 configSalt,
        uint256 postId,
        CreatePostParams calldata postParams,
        KeyValue[] calldata primitiveParams,
        KeyValue[] calldata ruleParams
    ) external;

    function processEditPost(
        bytes32 configSalt,
        uint256 postId,
        EditPostParams calldata postParams,
        KeyValue[] calldata primitiveParams,
        KeyValue[] calldata ruleParams
    ) external;

    function processDeletePost(
        bytes32 configSalt,
        uint256 postId,
        KeyValue[] calldata primitiveParams,
        KeyValue[] calldata ruleParams
    ) external;

    function processPostRuleChanges(
        bytes32 configSalt,
        uint256 postId,
        RuleChange[] calldata ruleChanges,
        KeyValue[] calldata ruleParams
    ) external;
}

contract AgentFeedRule is IFeedRule {
    SkypodAccessControls public skypodAccessControls;

    modifier onlyAdmin() {
        if (!skypodAccessControls.isAdmin(msg.sender)) {
            revert SkypodErrors.NotAdmin();
        }
        _;
    }

    constructor(address payable accessControls) {
        skypodAccessControls = SkypodAccessControls(accessControls);
    }

    function configure(
        bytes32 configSalt,
        KeyValue[] calldata ruleParams
    ) external override {}

    function processCreatePost(
        bytes32 configSalt,
        uint256 postId,
        CreatePostParams calldata postParams,
        KeyValue[] calldata primitiveParams,
        KeyValue[] calldata ruleParams
    ) external override {
        if (!skypodAccessControls.isAgent(msg.sender)) {
            revert SkypodErrors.NotAgent();
        }
    }

    function processEditPost(
        bytes32 configSalt,
        uint256 postId,
        EditPostParams calldata postParams,
        KeyValue[] calldata primitiveParams,
        KeyValue[] calldata ruleParams
    ) external override {}

    function processDeletePost(
        bytes32 configSalt,
        uint256 postId,
        KeyValue[] calldata primitiveParams,
        KeyValue[] calldata ruleParams
    ) external override {}

    function processPostRuleChanges(
        bytes32 configSalt,
        uint256 postId,
        RuleChange[] calldata ruleChanges,
        KeyValue[] calldata ruleParams
    ) external override {}

    function setAccessControls(
        address payable accessControls
    ) external onlyAdmin {
        skypodAccessControls = SkypodAccessControls(accessControls);
    }
}
