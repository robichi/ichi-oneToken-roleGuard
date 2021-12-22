// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AccessControlState is Ownable {

    using EnumerableSet for EnumerableSet.AddressSet;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    // bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    function grantRole(bytes32 role, address account) public onlyOwner {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public onlyOwner {
        _revokeRole(role, account);
    }

    function renounceRole(bytes32 role, address account) public onlyOwner {
        _revokeRole(role, account);
    }

    function setupRole(bytes32 role, address account) public onlyOwner {
        _grantRole(role, account);
    }

    function setRoleAdmin(bytes32 role, bytes32 adminRole) public onlyOwner {
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        _roles[role].members.add(account);
    }

    function _revokeRole(bytes32 role, address account) private {
        _roles[role].members.remove(account);
    }
}
