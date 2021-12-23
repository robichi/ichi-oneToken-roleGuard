// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

import '../lib/Bytes4Set.sol';
import '../interfaces/ComposableCommon.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract ComposedState is ComposableCommon, Ownable {

    using Bytes4Set for Bytes4Set.Set;

    Bytes4Set.Set implementationSet;
    mapping(bytes4 => Implementation) public implementation;

    function insert(bytes4 key, Implementation calldata imp) external onlyOwner {
        implementationSet.insert(key, 'ComposedState:insert');
        save(key, imp);
    }

    function remove(bytes4 key) external onlyOwner {
        implementationSet.remove(key, 'ComposedState:remove');
        delete implementation[key];
    }

    function save(bytes4 key, Implementation calldata imp) public onlyOwner {
        implementation[key] = imp;
    }    

    function exists(bytes4 key) external view returns(bool) {
        return implementationSet.exists(key);
    }

    function count() external view returns(uint) {
        return implementationSet.count();
    }

    function keyAtIndex(uint index) external view returns(bytes4) {
        return implementationSet.keyAtIndex(index);
    }

}
