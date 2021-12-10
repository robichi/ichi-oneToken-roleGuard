// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;
pragma abicoder v2;

import '../Composable.sol';

contract ComposableArbitraryStrategyRoleGuard is Composable {

    constructor() {
        registerFunction('executeTransaction(address,uint256,string,bytes)', false);
    }

}