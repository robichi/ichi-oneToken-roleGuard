// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;

import '@openzeppelin/contracts/access/AccessControl.sol';

contract DestructableAccessControl is AccessControl {

    event RoleDestroyed(address sender, bytes32 indexed role);

    /**
     * @notice tears down permissions for role
     * @param role role to destroy
     * @dev it is understood that roles should not be granted to excessive numbers of user accounts
     */

    function _destroyRole(bytes32 role) internal {
        uint256 memberCount = getRoleMemberCount(role);
        for ( uint i=0; i < memberCount; i++ ) {
            address member = getRoleMember(role, i);
            revokeRole(role, member);
        }
        emit RoleDestroyed(msg.sender, role);
    }
}