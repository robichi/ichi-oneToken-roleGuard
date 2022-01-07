// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "./StatelessICHIModuleCommon.sol";
import "./StrategyCommonState.sol";
import "../../interface/IOneTokenFactory.sol";
import "../../interface/IStrategy.sol";
import "../../interface/IOneTokenV1Base.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract StatelessStrategyCommon is IStrategy, StatelessICHIModuleCommon {

    using SafeERC20 for IERC20;

    address public immutable strategyState;
    bytes32 constant public override MODULE_TYPE = keccak256(abi.encodePacked("ICHI V1 Strategy Implementation"));

    event DeployedStrategyCommonState(address sender, address state);
    event StrategyDeployed(address sender, address oneTokenFactory, address oneToken_, string description);
    event StrategyInitialized(address sender);
    event StrategyExecuted(address indexed sender, address indexed token);
    event VaultAllowance(address indexed sender, address indexed token, uint256 amount);
    event FromVault(address indexed sender, address indexed token, uint256 amount);
    event ToVault(address indexed sender, address indexed token, uint256 amount);

    modifier onlyToken {
        require(msg.sender == StrategyCommonState(moduleState).oneToken(), "StatelessStrategyCommon: initialize from oneToken instance");
        _;
    }
    
    /**
     @dev oneToken governance has privileges that may be delegated to a controller
     */
    modifier strategyOwnerTokenOrController {
        address oneToken_ = StrategyCommonState(moduleState).oneToken();
        if(msg.sender != oneToken_) {
            if(msg.sender != IOneTokenV1Base(oneToken_).controller()) {
                require(msg.sender == IOneTokenV1Base(oneToken_).owner(), "StatelessStrategyCommon: not token controller or owner.");
            }
        }
        _;
    }

    /**
     @notice a strategy is dedicated to exactly one oneToken instance
     @param oneTokenFactory_ bind this instance to oneTokenFactory instance
     @param oneToken_ bind this instance to one oneToken vault
     @param description_ metadata has no impact on logic
     */
    constructor(address oneTokenFactory_, address oneToken_, string memory description_)
        StatelessICHIModuleCommon(oneTokenFactory_, ModuleType.Strategy, description_)
    {
        require(oneToken_ != NULL_ADDRESS, "StatelessStrategyCommon: oneToken cannot be NULL");
        require(IOneTokenFactory(IOneTokenV1Base(oneToken_).oneTokenFactory()).isOneToken(oneToken_), "StatelessStrategyCommon: oneToken is unknown");
        address state = address(new StrategyCommonState());
        strategyState = state;
        StrategyCommonState(state).setOneToken(oneToken_);
        emit DeployedStrategyCommonState(msg.sender, state);
        emit StrategyDeployed(msg.sender, oneTokenFactory_, oneToken_, description_);
    }

    /**
     @notice a strategy is dedicated to exactly one oneToken instance and must be re-initializable
     */
    function init() external onlyToken virtual override {
        address oneToken_ = StrategyCommonState(moduleState).oneToken();
        IERC20(oneToken_).safeApprove(oneToken_, 0);
        IERC20(oneToken_).safeApprove(oneToken_, INFINITE);
        emit StrategyInitialized(oneToken_);
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
        address oneToken_ = StrategyCommonState(moduleState).oneToken();
        if(amount == 0) amount = INFINITE;
        IERC20(token).safeApprove(oneToken_, 0);
        IERC20(token).safeApprove(oneToken_, amount);
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
        address oneToken_ = StrategyCommonState(moduleState).oneToken();
        uint256 assetCount;
        success = true;
        assetCount = IOneTokenV1Base(oneToken_).assetCount();
        for(uint256 i=0; i < assetCount; i++) {
            address thisAsset = IOneTokenV1Base(oneToken_).assetAtIndex(i);
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
        address oneToken_ = StrategyCommonState(moduleState).oneToken();
        IERC20(token).safeTransfer(oneToken_, amount);
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
        address oneToken_ = StrategyCommonState(moduleState).oneToken();
        IERC20(token).safeTransferFrom(oneToken_, address(this), amount);
        emit FromVault(msg.sender, token, amount);
    }

    function oneToken() external view override returns(address) {
        return StrategyCommonState(moduleState).oneToken();
    }

    function moduleDescription() external view override returns(string memory) {
        return ICHIModuleCommonState(moduleState).moduleDescription();
    }
}
