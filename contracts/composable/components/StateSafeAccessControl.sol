// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./AccessControlState.sol";
import "@openzeppelin/contracts/utils/Context.sol";


abstract contract StateSafeAccessControl is Context {

    address public immutable state;
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    constructor() {
        state = address(new AccessControlState());
    }

    function hasRole(bytes32 role, address account) public view returns (bool) {
        return AccessControlState(state).hasRole(role, account);
    }

    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return AccessControlState(state).getRoleMemberCount(role);
    }

    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return AccessControlState(state).getRoleMember(role, index);
    }

    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return AccessControlState(state).getRoleAdmin(role);
    }

    function grantRole(bytes32 role, address account) public virtual {
        require(
            AccessControlState(state).hasRole(
                AccessControlState(state).getRoleAdmin(role),
                _msgSender()), 
            "AccessControl: sender must be an admin to grant");
        AccessControlState(state).grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(
                AccessControlState(state).getRoleAdmin(role), 
                _msgSender()), 
            "AccessControl: sender must be an admin to revoke");
        AccessControlState(state).revokeRole(role, account);
    }

    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");
        _revokeRole(role, account);
    }

    function _setupRole(bytes32 role, address account) internal virtual {
        AccessControlState(state).grantRole(role, account);
    }

    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, AccessControlState(state).getRoleAdmin(role), adminRole);
        AccessControlState(state).setRoleAdmin(role, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!AccessControlState(state).hasRole(role, account)) {
            AccessControlState(state).grantRole(role, account);
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (AccessControlState(state).hasRole(role, account)) {
            AccessControlState(state).revokeRole(role, account);
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}
