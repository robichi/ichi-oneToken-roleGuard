// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;

import { Composed } from "../../Composed.sol";
import { StrategyCommon } from "../../../strategy/StrategyCommon.sol";

// TODO: Consider a Factory to deploy instances of these

/**
 Deploys a Composed Strategy supporting the minimum viable interface to OneToken Vaults and Controllers, with
 the ability to ingest Composable extensions. 
 */

contract ComposedStrategy is StrategyCommon, Composed {

    constructor(address oneTokenFactory_, address oneToken_, string memory description_)
        StrategyCommon(oneTokenFactory_, oneToken_, description_)
    {}

}
