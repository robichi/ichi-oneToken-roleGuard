// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;

import { ComposedStrategyState } from "./state/ComposedStrategyState.sol";
import { Composed } from "../../Composed.sol";
import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { ICHIModuleCommon } from "../../../common/ICHIModuleCommon.sol";
import { IOneTokenV1Base } from "../../../interface/IOneTokenV1Base.sol";
import { IOneTokenFactory } from "../../../interface/IOneTokenFactory.sol";

// TODO: Consider a Factory to deploy instances of these

/**
 Deploys a Composed Strategy supporting the minimum viable interface to OneToken Vaults and Controllers, with
 the ability to ingest Composable extensions. 
 */

contract ComposedStrategy is ComposedStrategyState, Composed {

    constructor(address oneTokenFactory_, address oneToken_, string memory description_)
        ComposedStrategyState(oneTokenFactory_, oneToken_, description_)
    {}

}
