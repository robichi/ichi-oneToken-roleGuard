// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;

import "../../../../interface/IOneTokenFactory.sol";
import "../../../../interface/IOneTokenV1Base.sol";
import "../../../../strategy/StrategyCommon.sol";

abstract contract ComposedStrategyState is StrategyCommon { 

    constructor(address oneTokenFactory_, address oneToken_, string memory description_)
        StrategyCommon(oneTokenFactory_, oneToken_, description_)
    {}

}
