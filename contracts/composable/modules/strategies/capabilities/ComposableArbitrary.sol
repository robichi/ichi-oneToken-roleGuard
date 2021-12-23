// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;
pragma abicoder v2;

import { StrategyCommon } from "../../../../strategy/StrategyCommon.sol";
import { Composable } from "../../../components/Composable.sol";

contract ComposableArbitrary is Composable {

    /**
    @notice Composables must be initialized post-deployment before they can be consumed by compositions.
     */

    function initialize() external uninitialized {
        registerFunction("executeTransaction(address,uint256,string memory,bytes memory)", true);
        setInitialized();
    }

    /**
    @notice Governance can work with collateral and treasury assets. Can swap assets.
    @param target address/smart contract you are interacting with
    @param value msg.value (amount of eth in WEI you are sending. Most of the time it is 0)
    @param signature the function signature
    @param data abi-encodeded bytecode of the parameter values to send
    */

    function executeTransaction(address target, uint256 value, string memory signature, bytes memory data) external returns (bytes memory) {
        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{ value: value }(callData);
        require(success, "ComposableArbitrary:executeTransaction:: Transaction execution reverted.");
        return returnData;
    }

}
