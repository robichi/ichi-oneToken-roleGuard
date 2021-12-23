// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;
pragma abicoder v2;

import '../../components/Composable.sol';

contract ComposableArbitraryStrategyRoleGuard is Composable {

    /**
     * @notice initialize the composable module. Once, post deployment to enable consumption.
     */

    function initialize() external uninitialized {
        registerFunction('executeTransaction(address,uint256,string,bytes)', false);
        setInitialized();
    }

}
