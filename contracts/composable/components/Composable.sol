// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

import './ComposableState.sol';
import '../interfaces/IComposable.sol';
import '../lib/Bytes4Set.sol';

/**************************************************************************************************************************
 * Composables should inherit this and register their external functions from constructors - append only
 **************************************************************************************************************************/

contract Composable is IComposable { 

    address public immutable composableState;

    modifier initialized {
        require(ComposableState(composableState).isInitialized(), 'Composable::initialized: not initialized');
        _;
    }
    
    modifier uninitialized {
        require(!ComposableState(composableState).isInitialized(), 'Composable::initialized: not initialized');
        _;
    }

    event Deployed(address sender, address state);
    event Initialized(address sender);
    event RegisterFunction(address sender, string nameAndParams, bytes4 signature);

    constructor() {
        address state = address(new ComposableState());
        composableState = state;
        emit Deployed(msg.sender, state);
    }

    /**********************************************************************************************************************
     * Call as many times as needed to register the complete function list. Discrete functions can only be registered once.
     * No effect after initialized.
     **********************************************************************************************************************/

    /**
     * @notice Composables should call, usually from constructor, to register their function surface 
     * @param nameAndParameters function name in the function interface style, e.g. 'foo(uint, bool)'
     * @param delegate an array of bools ascribing the execution mode of each functionName, true=delegateCall, false=call
     */

    function registerFunction(string memory nameAndParameters, bool delegate) internal {
        if(!ComposableState(composableState).isInitialized()) {
            emit RegisterFunction(
                msg.sender, 
                nameAndParameters, 
                ComposableState(composableState).registerFunction(nameAndParameters, delegate));
        }
    }

    function setInitialized() internal {
        ComposableState(composableState).setInitialized();
        emit Initialized(msg.sender);
    }

    /**********************************************************************************************************************
     * Composed contracts ingest this list.
     **********************************************************************************************************************/    
    
    /**
     * @notice returns a list of parsed functions
     * @return array of configured Functions incl. interface, selector and execution mode
     */

    function functions() external view override initialized returns(Function[] memory) {
        return ComposableState(composableState).functions();
    }

}
