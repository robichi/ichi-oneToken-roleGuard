// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

import '../../components/Composable.sol';

contract ComposableOneTokenStrategyRoleGuard is Composable {

    function initialize() external uninitialized {
        registerFunction('init()', false);
        registerFunction('execute()', false);
        registerFunction('setAllowance(address,uint256)', false);
        registerFunction('toVault(address,uint256)', false);
        registerFunction('fromVault(address uint256)', false);
        registerFunction('closeAllPositions()', false);
        registerFunction('closePositions(address)', false);
        registerFunction('updateDescription(address,string)', false);
        registerFunction('oneToken()', false); // VS: do we need this?
        setInitialized();
    }

}