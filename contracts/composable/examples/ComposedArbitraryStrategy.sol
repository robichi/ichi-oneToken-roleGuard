// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;
pragma abicoder v2;

import "../Composed.sol";

contract ComposedArbitraryStrategy is Composed { 

    constructor(address _composableArbitraryStrategy) {
        addComposable(_composableArbitraryStrategy, _composableArbitraryStrategy);
        // make the composition immutible
        renounceRole(ROLE_COMPOSER,  msg.sender);
    }

}
