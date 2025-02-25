// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import './StateSafeAccessControl.sol';

contract StatelessDestructableAccessControl is StateSafeAccessControl {

    event RoleDestroyed(address sender, bytes32 indexed role);

    /**
     * @notice tears down permissions for role
     * @param role role to destroy
     * @dev WARN: roles member counts should not be excessive
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