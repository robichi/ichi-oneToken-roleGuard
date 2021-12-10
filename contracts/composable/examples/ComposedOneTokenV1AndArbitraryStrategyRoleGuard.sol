// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;

import '../Composed.sol';

contract ComposedOneTokenV1AndStrategyRoleGuard is Composed { 

    constructor(
        address _composableOneTokenV1RoleGuard, 
        address _composableOneTokenStrategyRoleGuard, 
        address _composableArbitraryStrategyRoleGuard,
        address _oneTokenTarget, 
        address _strategyTarget
    ) {
        addComposable(_composableOneTokenV1RoleGuard, _oneTokenTarget);
        addComposable(_composableOneTokenStrategyRoleGuard, _strategyTarget);
        addComposable(_composableArbitraryStrategyRoleGuard, _strategyTarget);
        // make the composition immutible
        renounceRole(ROLE_COMPOSER,  msg.sender);
    }

}
