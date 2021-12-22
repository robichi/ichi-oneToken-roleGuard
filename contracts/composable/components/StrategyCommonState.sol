// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import '@openzeppelin/contracts/access/Ownable.sol';

contract StrategyCommonState is Ownable {

    address public oneToken;

    function setOneToken(address oneToken_) external onlyOwner {
        oneToken =  oneToken_;
    }
}
