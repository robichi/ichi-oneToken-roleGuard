// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;

import '../ComposedWallet.sol';

contract ComposedOneTokenV1AndStrategyRoleGuard is ComposedWallet { 

    constructor(
        address _composableOneTokenV1RoleGuard, 
        address _composableOneTokenStrategyRoleGuard, 
        address _oneTokenTarget, 
        address _strategyTarget
    ) {
        // addComposable(_composableOneTokenV1RoleGuard, _oneTokenTarget);
        // addComposable(_composableOneTokenStrategyRoleGuard, _strategyTarget);
        // make the composition immutible
        // renounceRole(ROLE_COMPOSER,  msg.sender);
    }

}
