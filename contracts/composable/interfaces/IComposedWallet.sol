// SPDX-License-Identifier: ISC


// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
interface IComposedWallet {
    function erc20Transfer(IERC20 token, address to, uint256 value) external;
    function erc20Approve(IERC20 token, address spender, uint256 value) external;
    function erc20IncreaseAllowance(IERC20 token, address spender, uint256 value) external;
    function erc20DecreaseAllowance(IERC20 token, address spender, uint256 value) external;
    function roleGuardexecuteTransaction(address _target, uint256 value, string memory signature, bytes memory data) external returns (bytes memory);
}