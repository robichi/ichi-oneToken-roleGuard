// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '../interfaces/IComposable.sol';
import '../lib/Bytes4Set.sol';

contract ComposableState is IComposable, Ownable { 

    using Bytes4Set for Bytes4Set.Set;
    // ensure uniqueness
    Bytes4Set.Set functionSet;
    // enable random access
    mapping(bytes4 => Function) public functionMap;
    // return entire set
    Function[] functionList;

    /**
     * @notice Composables should call, usually from constructor, to register their function surface 
     * @param nameAndParameters function name in the function interface style, e.g. 'foo(uint, bool)'
     * @param delegate an array of bools ascribing the execution mode of each functionName, true=delegateCall, false=call
     */

    function registerFunction(string memory nameAndParameters, bool delegate) external onlyOwner returns(bytes4 selecter) {
        selecter = bytes4(keccak256(bytes(nameAndParameters)));
        functionSet.insert(selecter, nameAndParameters);
        Function memory thisFunction = Function({
                nameAndParams: nameAndParameters,
                selecter: selecter,
                delegate: delegate
            });
        functionList.push(thisFunction);
        functionMap[selecter] = thisFunction;
    }

    /**********************************************************************************************************************
     * Composed contracts ingest this list.
     **********************************************************************************************************************/    
    
    /**
     * @notice returns a list of parsed functions
     * @return array of configured Functions incl. interface, selector and execution mode
     */

    function functions() external view override returns(Function[] memory) {
        return functionList;
    }

}
