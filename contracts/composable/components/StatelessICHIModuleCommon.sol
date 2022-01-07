// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "./ICHIModuleCommonState.sol";
import "../../interface/IModule.sol";
import "../../interface/IOneTokenFactory.sol";
import "../../interface/IOneTokenV1Base.sol";
import "../../common/ICHICommon.sol";

abstract contract StatelessICHIModuleCommon is IModule, ICHICommon {
    
    address public immutable moduleState;
    ModuleType public immutable override moduleType;
    address public immutable override oneTokenFactory;

    event DeployedICHIModuleCommonState(address sender, address state);
    event ModuleDeployed(address sender, ModuleType moduleType, string description);
    event DescriptionUpdated(address sender, string description);
   
    modifier onlyKnownToken {
        require(IOneTokenFactory(oneTokenFactory).isOneToken(msg.sender), "StatelessICHIModuleCommon: msg.sender is not a known oneToken");
        _;
    }
    
    modifier onlyTokenOwner (address oneToken) {
        require(msg.sender == IOneTokenV1Base(oneToken).owner(), "StatelessICHIModuleCommon: msg.sender is not oneToken owner");
        _;
    }

    modifier onlyModuleOrFactory {
        if(!IOneTokenFactory(oneTokenFactory).isModule(msg.sender)) {
            require(msg.sender == oneTokenFactory, "StatelessICHIModuleCommon: msg.sender is not module owner, token factory or registed module");
        }
        _;
    }
    
    /**
     @notice modules are bound to the factory at deployment time
     @param oneTokenFactory_ factory to bind to
     @param moduleType_ type number helps prevent governance errors
     @param description_ human-readable, descriptive only
     */    
    constructor (address oneTokenFactory_, ModuleType moduleType_, string memory description_) {
        require(oneTokenFactory_ != NULL_ADDRESS, "StatelessICHIModuleCommon: oneTokenFactory cannot be empty");
        require(bytes(description_).length > 0, "StatelessICHIModuleCommon: description cannot be empty");
        address state = address(new ICHIModuleCommonState());
        moduleState = state;
        oneTokenFactory = oneTokenFactory_;
        moduleType = moduleType_;
        ICHIModuleCommonState(state).setModuleDescription(description_);
        emit DeployedICHIModuleCommonState(msg.sender, state);
        emit ModuleDeployed(msg.sender, moduleType_, description_);
    }

    /**
     @notice set a module description
     @param description new module desciption
     */
    function updateDescription(string memory description) external onlyOwner override {
        require(bytes(description).length > 0, "StatelessICHIModuleCommon: description cannot be empty");
        ICHIModuleCommonState(moduleState).setModuleDescription(description);
        emit DescriptionUpdated(msg.sender, description);
    }  
}
