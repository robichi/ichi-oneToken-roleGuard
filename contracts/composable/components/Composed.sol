// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

import './ComposedState.sol';
import './Composable.sol';
import './StatelessDestructableAccessControl.sol';
import '../interfaces/Common.sol';
import '../lib/Bytes4Set.sol';

contract Composed is Common, StatelessDestructableAccessControl { // is IStrategy

    bytes32 public constant ROLE_COMPOSER = keccak256('Composer Role');
    
    address public immutable composition;

    modifier onlyRole(bytes32 role) {
        require(hasRole(role, msg.sender), 'Composed::onlyRole: unauthorized');
        _;
    }

    event DeployedComposedState(address sender, address state);
    event ComposableAdded(address sender, address composable, address target);
    event ComposableRemoved(address sender, address composable);

    constructor() {
        address compo = address(new ComposedState());
        composition = compo;
        emit DeployedComposedState(msg.sender, compo);
    }

    /***************************************************************************
     * Composable Ingress, Egress
     ***************************************************************************/

    /**
     * @notice ingests the function list presented by the composable
     * @param composable contract that inherits from Composable.sol
     */

    function addComposable(address composable, address target) public onlyRole(ROLE_COMPOSER) {
        Function[] memory funcs = IComposable(composable).functions();

        for( uint256 i=0; i < funcs.length; i++ ) {
            bytes4 sel = funcs[i].selecter;

            Implementation memory imp = Implementation({
                nameAndParams: funcs[i].nameAndParams,
                implementation: target, // TODO: consider delegated, non-delegated logic here
                delegate: funcs[i].delegate
            });

            ComposedState(composition).insert(sel, imp);
            bytes32 role = getRole(sel);
            _setupRole(role, msg.sender);

        }
        emit ComposableAdded(msg.sender, composable, target);
    }

    /**
     * @notice ejects the function list presented by the composable. Msg.sender will be role admin.
     * @param composable contract that inherits from Composable.sol
     */

    function removeComposable(address composable) public onlyRole(ROLE_COMPOSER) {
        Function[] memory funcs = IComposable(composable).functions();

        for( uint256 i=0; i<funcs.length; i++ ) {
            bytes4 sel = funcs[i].selecter;
            ComposedState(composition).remove(sel);
            bytes32 role = getRole(sel);
            _destroyRole(role);
        }
        emit ComposableRemoved(msg.sender, composable);
    }

    /***************************************************************************
     * Forward transactions
     ***************************************************************************/

    fallback() external {
        _fallback();
    }

    receive() external payable {
        _fallback();
    }

    function _fallback() private {

        bytes4 sel = msg.sig;

        // cannot call an uncontrolled function
        require(ComposedState(composition).exists(sel), concat('Composed::fallback: unknown function selecter ', string(msg.data)));

        // must be authorized to call the function
        require(hasRole(getRole(sel), msg.sender), concat('Composed::fallback: permission denied ', string(msg.data)));

        (/* string */, address imp, bool delegate)= ComposedState(composition).implementation(sel);

        if(!delegate) {
            _call(imp);
        } else {
            _delegate(imp);
        }
        revert('Composed::_fallback: 500 - hit unreachable code');
    }

    /**
     * Based on open zeppelin Proxy.sol
     * Both functions satisfy return value expectations.
     */

    function _delegate(address _implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * Use assembly to pass return values back to the caller.
     */

    function _call(address _implementation) internal virtual {
        uint256 value = msg.value;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := call(gas(), _implementation, value, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /***************************************************************************
     * Improved error reporting
     ***************************************************************************/

    /**
     * @notice concatonates strings such as reason messages
     * @param s1 first string
     * @param s2 second string 
     * @return string concatenated 
     */

    function concat(string memory s1, string memory s2) internal pure returns (string memory) {
        return string(abi.encodePacked(s1, s2));
    }

    /***************************************************************************
     * View functions
     ***************************************************************************/

    /**
     * @notice returns the 4-byte selector for a function name and params
     * @param nameAndParams external function, e.g. 'foo(uint256, bool)`
     * @param selecter 4-byte function selector
     */

    function getSelecter(string memory nameAndParams) public pure returns(bytes4 selecter) {
        selecter = bytes4(keccak256(bytes(nameAndParams)));
    }

    /**
     * @notice returns the role code for a function selecter
     * @param selecter 4-byte function identifier
     * @return manageableRole role code for AccessControl.sol 
     */

    function getRole(bytes4 selecter) public view returns(bytes32 manageableRole) {
        manageableRole = keccak256(abi.encodePacked(address(this), selecter));
    }

    /**
     * Enumerate ingested functions
     */

    function isImplemented(string memory nameAndParams) external view returns(bool) {
        bytes4 sel = getSelecter(nameAndParams);
        return ComposedState(composition).exists(sel);
    }

    function implementationCount() external view returns(uint256 count) {
        count = ComposedState(composition).count();
    }

    function implementationAtIndex(uint256 index) external view returns(bytes4 selecter) {
        selecter = ComposedState(composition).keyAtIndex(index);
    }

}
