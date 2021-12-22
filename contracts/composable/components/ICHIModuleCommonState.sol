// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import '@openzeppelin/contracts/access/Ownable.sol';

contract ICHIModuleCommonState is Ownable {

    string public moduleDescription;

    function setModuleDescription(string memory description) external onlyOwner {
        moduleDescription = description;
    }
}
