// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.24;

import "./BasePool.sol";

abstract contract GovernancePool is BasePool {
    constructor(
        address payable _accessControls,
        address payable _userManager,
        address payable _poolManager,
        address payable _devTreasury,
        address _novo,
        address _positionManager,
        address _tokenSnapshots
    )
        BasePool(
            _accessControls,
            _userManager,
            _poolManager,
            _devTreasury,
            _novo
        )
    {}
}
