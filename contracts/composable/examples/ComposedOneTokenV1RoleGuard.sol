// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;

import '../ComposedWallet.sol';

contract ComposedOneTokenV1RoleGuard is ComposedWallet { 

    constructor(address _composableOneTokenV1RoleGuard, address target) {
        addComposable(_composableOneTokenV1RoleGuard, target);
        // make the composition immutible
        renounceRole(ROLE_COMPOSER,  msg.sender);
    }

}
