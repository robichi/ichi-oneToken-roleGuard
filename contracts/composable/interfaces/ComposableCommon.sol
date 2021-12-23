// SPDX-License-Identifier: Unlicensed

pragma solidity 0.7.6;

interface ComposableCommon {

    struct Function {
        bytes4 selecter;
        string nameAndParams;
        bool delegate;
    }

    struct Implementation {
        string nameAndParams;
        address implementation;
        bool delegate;
    }

}
