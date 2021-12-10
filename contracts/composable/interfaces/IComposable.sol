// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import './Common.sol';
pragma abicoder v2;

interface IComposable is Common {
    function functions() external view returns(Function[] memory);
}
