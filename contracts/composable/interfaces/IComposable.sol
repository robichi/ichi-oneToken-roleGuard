// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import './ComposableCommon.sol';
pragma abicoder v2;

interface IComposable is ComposableCommon {
    function functions() external view returns(Function[] memory);
}
