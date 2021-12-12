// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;

import { ComposedStrategyState } from "./state/ComposedStrategyState.sol";
import { Composed } from "../../Composed.sol";
import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { ICHIModuleCommon } from "../../../common/ICHIModuleCommon.sol";
import { IOneTokenV1Base } from "../../../interface/IOneTokenV1Base.sol";
import { IOneTokenFactory } from "../../../interface/IOneTokenFactory.sol";

// TODO: Consider a Factory to deploy instances of these

/**
 Deploys a Composed Strategy supporting the minimum viable interface to OneToken Vaults and Controllers, with
 the ability to ingest Composable extensions. 
 */

contract ComposedStrategy is ComposedStrategyState, ICHIModuleCommon, Composed {

    using SafeERC20 for IERC20;

    /**
     @notice a strategy is dedicated to exactly one oneToken instance
     @param oneTokenFactory_ bind this instance to oneTokenFactory instance
     @param oneToken_ bind this instance to one oneToken vault
     @param description_ metadata has no impact on logic
     */
    constructor(address oneTokenFactory_, address oneToken_, string memory description_)
        ICHIModuleCommon(oneTokenFactory_, ModuleType.Strategy, description_)
    {
        require(oneToken_ != NULL_ADDRESS, "StrategyCommon: oneToken cannot be NULL");
        require(IOneTokenFactory(IOneTokenV1Base(oneToken_).oneTokenFactory()).isOneToken(oneToken_), "StrategyCommon: oneToken is unknown");
        oneToken = oneToken_;
        emit StrategyDeployed(msg.sender, oneTokenFactory_, oneToken_, description_);
    }

    /**
     @notice a strategy is dedicated to exactly one oneToken instance and must be re-initializable
     */
    function init() external onlyToken virtual override {
        IERC20(oneToken).safeApprove(oneToken, 0);
        IERC20(oneToken).safeApprove(oneToken, INFINITE);
        emit StrategyInitialized(oneToken);
    }

    /**
     @notice a controller invokes execute() to trigger automated logic within the strategy.
     @dev called from oneToken governance or the active controller. Overriding function should emit the event. 
     */  
    function execute() external virtual strategyOwnerTokenOrController override {
        // emit StrategyExecuted(msg.sender, oneToken);
    }  
        
    /**
     @notice gives the oneToken control of tokens deposited in the strategy
     @dev called from oneToken governance or the active controller
     @param token the asset
     @param amount the allowance. 0 = infinte
     */
    function setAllowance(address token, uint256 amount) external strategyOwnerTokenOrController override {
        if(amount == 0) amount = INFINITE;
        IERC20(token).safeApprove(oneToken, 0);
        IERC20(token).safeApprove(oneToken, amount);
        emit VaultAllowance(msg.sender, token, amount);
    }

    /**
     @notice closes all positions and returns the funds to the oneToken vault
     @dev override this function to withdraw funds from external contracts. Return false if any funds are unrecovered.
     */
    function closeAllPositions() external virtual strategyOwnerTokenOrController override returns(bool success) {
        success = _closeAllPositions();
    }

    /**
     @notice closes all positions and returns the funds to the oneToken vault
     @dev override this function to withdraw funds from external contracts. Return false if any funds are unrecovered.
     */
    function _closeAllPositions() internal virtual returns(bool success) {
        uint256 assetCount;
        success = true;
        assetCount = IOneTokenV1Base(oneToken).assetCount();
        for(uint256 i=0; i < assetCount; i++) {
            address thisAsset = IOneTokenV1Base(oneToken).assetAtIndex(i);
            closePositions(thisAsset);
        }
    }

    /**
     @notice closes token positions and returns the funds to the oneToken vault
     @dev override this function to redeem and withdraw related funds from external contracts. Return false if any funds are unrecovered. 
     @param token asset to recover
     @param success true, complete success, false, 1 or more failed operations
     */
    function closePositions(address token) public strategyOwnerTokenOrController override virtual returns(bool success) {
        // this naive process returns funds on hand.
        // override this to explicitly close external positions and return false if 1 or more positions cannot be closed at this time.
        success = true;
        uint256 strategyBalance = IERC20(token).balanceOf(address(this));
        if(strategyBalance > 0) {
            _toVault(token, strategyBalance);
        }
    }

    /**
     @notice let's the oneToken controller instance send funds to the oneToken vault
     @dev implementations must close external positions and return all related assets to the vault
     @param token the ecr20 token to send
     @param amount the amount of tokens to send
     */
    function toVault(address token, uint256 amount) external strategyOwnerTokenOrController override {
        _toVault(token, amount);
    }

    /**
     @notice close external positions send all related funds to the oneToken vault
     @param token the ecr20 token to send
     @param amount the amount of tokens to send
     */
    function _toVault(address token, uint256 amount) internal {
        IERC20(token).safeTransfer(oneToken, amount);
        emit ToVault(msg.sender, token, amount);
    }

    /**
     @notice let's the oneToken controller instance draw funds from the oneToken vault allowance
     @param token the ecr20 token to send
     @param amount the amount of tokens to send
     */
    function fromVault(address token, uint256 amount) external strategyOwnerTokenOrController override {
        _fromVault(token, amount);
    }

    /**
     @notice draw funds from the oneToken vault
     @param token the ecr20 token to send
     @param amount the amount of tokens to send
     */
    function _fromVault(address token, uint256 amount) internal {
        IERC20(token).safeTransferFrom(oneToken, address(this), amount);
        emit FromVault(msg.sender, token, amount);
    }

}
