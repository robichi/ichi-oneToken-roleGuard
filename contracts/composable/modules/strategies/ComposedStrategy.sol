// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;
pragma abicoder v2;

import { ComposedStrategyState } from "./state/ComposedStrategyState.sol";
import { Composed } from "../../Composed.sol";
import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { ICHIModuleCommon } from "../../../common/ICHIModuleCommon.sol";
import { IOneTokenV1Base } from "../../../interface/IOneTokenV1Base.sol";
import { IOneTokenFactory } from "../../../interface/IOneTokenFactory.sol";

abstract contract ComposedStrategy is ComposedStrategyState, ICHIModuleCommon, Composed {

    using SafeERC20 for IERC20;

    /**
     @notice a strategy is dedicated to exactly one oneToken instance
     @param oneTokenFactory_ bind this instance to oneTokenFactory instance
     @param oneToken_ bind this instance to one oneToken vault
     @param description_ metadata has no impact on logic
     */
    constructor(address oneTokenFactory_, address oneToken_, string memory description_)
        ICHIModuleCommon(oneTokenFactory_, ModuleType.Strategy, description_)
    {
        require(oneToken_ != NULL_ADDRESS, "StrategyCommon: oneToken cannot be NULL");
        require(IOneTokenFactory(IOneTokenV1Base(oneToken_).oneTokenFactory()).isOneToken(oneToken_), "StrategyCommon: oneToken is unknown");
        oneToken = oneToken_;
        emit StrategyDeployed(msg.sender, oneTokenFactory_, oneToken_, description_);
    }

}

