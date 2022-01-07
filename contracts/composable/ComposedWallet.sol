// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import './interfaces/IComposedWallet.sol';
import './components/Composed.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

/**
 * A Composed Role Guard supporting wallet-like functions and the ability to ingest Composable extensions. 
 */

contract ComposedWallet is  Composed, IComposedWallet  { 

    using SafeERC20 for IERC20;
    
    // RoleGuard funds administration
    bytes32 public constant TREASURER_ROLE = keccak256('Role Guard Treasurer');

    event ExecuteTransaction(address target, uint256 value, string signature, bytes data, bytes returnData);

    // ERC20 operations facilitate management of funds held by this contract

    function erc20Transfer(IERC20 token, address to, uint256 value) external override onlyRole(TREASURER_ROLE) {
        token.safeTransfer(to, value);
    }

    function erc20Approve(IERC20 token, address spender, uint256 value) external override onlyRole(TREASURER_ROLE) {
        token.safeApprove(spender, value);
    }

    function erc20IncreaseAllowance(IERC20 token, address spender, uint256 value) external override onlyRole(TREASURER_ROLE) {
        token.safeIncreaseAllowance(spender, value);
    }

    function erc20DecreaseAllowance(IERC20 token, address spender, uint256 value) external override onlyRole(TREASURER_ROLE) {
        token.safeDecreaseAllowance(spender, value);
    }

    function roleGuardexecuteTransaction(address _target, uint256 value, string memory signature, bytes memory data) external override onlyRole(DEFAULT_ADMIN_ROLE) returns (bytes memory) {
        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = _target.call{ value: value }(callData);
        require(success, "ComposedWallet::roleGuardexecuteTransaction: Transaction execution reverted.");
        emit ExecuteTransaction(_target, value, signature, data, returnData);
        return returnData;
    }

}
