// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

interface ComposableCommon {

    struct Function {
        bytes4 selecter;
        string nameAndParams;
        bool delegate;
    }

    // implementation is ignored for delegated functions
    
    struct Implementation {
        string nameAndParams;
        address implementation;
        bool delegate;
    }

}
