// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;

import "../../../../interface/IOneTokenFactory.sol";
import "../../../../interface/IOneTokenV1Base.sol";
import "../../../../interface/IStrategy.sol";

abstract contract ComposedStrategyState is IStrategy { 

    address public override oneToken;
    bytes32 public constant override MODULE_TYPE =
        keccak256(abi.encodePacked("ICHI V1 Strategy Implementation"));

    event StrategyDeployed(address sender, address oneTokenFactory, address oneToken_, string description);
    event StrategyInitialized(address sender);
    event StrategyExecuted(address indexed sender, address indexed token);
    event VaultAllowance(address indexed sender, address indexed token, uint256 amount);
    event FromVault(address indexed sender, address indexed token, uint256 amount);
    event ToVault(address indexed sender, address indexed token, uint256 amount);

    modifier onlyToken() {
        require(
            msg.sender == oneToken,
            "StrategyState: initialize from oneToken instance"
        );
        _;
    }

    /**
     @dev oneToken governance has privileges that may be delegated to a controller
     */
    modifier strategyOwnerTokenOrController() {
        if (msg.sender != oneToken) {
            if (msg.sender != IOneTokenV1Base(oneToken).controller()) {
                require(
                    msg.sender == IOneTokenV1Base(oneToken).owner(),
                    "StrategyState: not token controller or owner."
                );
            }
        }
        _;
    }

}
