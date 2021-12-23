// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import { Composed } from "./components/Composed.sol";
import { StatelessStrategyCommon } from "./components/StatelessStrategyCommon.sol";

// TODO: Consider a Factory to deploy instances of these

/**
 A Composed Strategy supporting the minimum viable interface to OneToken Vaults and Controllers and
 the ability to ingest Composable extensions. 
 */

contract ComposedStrategy is Composed, StatelessStrategyCommon {

    constructor(address oneTokenFactory_, address oneToken_, string memory description_)
        StatelessStrategyCommon(oneTokenFactory_, oneToken_, description_)
    {}

}
