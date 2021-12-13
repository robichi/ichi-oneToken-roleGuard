// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "../../../../interface/IModule.sol";

contract IStrategyStubs is IModule {

    string private constant error = "IStrategyStub: do not call IStrategy functions on Composable implementation";
    
    function init() external {
        revert(error);
    }
    function execute() external {
        revert(error);
    }
    function setAllowance(address token, uint256 amount) external {
        revert(error);
    }
    function toVault(address token, uint256 amount) external {
        revert(error);
    }
    function fromVault(address token, uint256 amount) external {
        revert(error);
    }
    function closeAllPositions() external returns(bool) {
        revert(error);
    }
    function closePositions(address token) external returns(bool success) {
        revert(error);
    }
    function oneToken() external view returns(address) {
        revert(error);
    }

    function oneTokenFactory() external override view returns(address) {
        revert(error);
    }
    function updateDescription(string memory description) external override {
        revert(error);
    }
    function moduleDescription() external view override returns(string memory) {
        revert(error);
    }
    function MODULE_TYPE() external view override returns(bytes32) {
        revert(error);
    }
    function moduleType() external view override returns(ModuleType) {
        revert(error);
    }

    function owner() external view override returns (address) {
        revert(error);
    }

    function renounceOwnership() external override {
        revert(error);
    }

    function transferOwnership(address newOwner) external override {
        revert(error);
    }  
}