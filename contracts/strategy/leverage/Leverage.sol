// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import '../StrategyCommon.sol';
import '../../interface/IICHIVaultFactory.sol';
import '../../interface/IICHIVault.sol';
import '../../interface/IOneTokenV1.sol';

contract Leverage is StrategyCommon {

    using SafeERC20 for IERC20;

    IICHIVault public immutable ichiVault;
    IICHIVaultFactory public immutable ichiVaultFactory;

    event LeverageStrategy(address sender, address oneToken, string description, address pool, address token0, address token1, bool allowToken0, bool allowToken1);

    /**
     @notice a strategy is dedicated to exactly one oneToken instance
     @param _oneTokenFactory bind this instance to oneTokenFactory instance
     @param _oneToken bind this instance to one oneToken vault
     @param _description metadata has no impact on logic
     */
    constructor(
        address _oneTokenFactory, 
        address _oneToken, 
        string memory _description,
        address _ichiVault,
        address _ichiVaultFactory
        ) 
        StrategyCommon(_oneTokenFactory, _oneToken, _description)
    {
        require(_ichiVaultFactory == IICHIVault(_ichiVault).ichiVaultFactory(), 'Leverage::constructor: vault-reported ichiVaultFactory mismatch');
        ichiVault = IICHIVault(_ichiVault);
        ichiVaultFactory = IICHIVaultFactory(_ichiVaultFactory);

        address pool = IICHIVault(_ichiVault).pool();
        address token0 = IICHIVault(_ichiVault).token0();
        bool allowToken0 = IICHIVault(_ichiVault).allowToken0();
        address token1 = IICHIVault(_ichiVault).token1();
        bool allowToken1 = IICHIVault(_ichiVault).allowToken1(); 

        require(IOneTokenV1(_oneToken).isAsset(token0), 'Leverage::constructor: assigned IchiVault token0 is not a OneToken vault asset');
        require(IOneTokenV1(_oneToken).isAsset(token1), 'Leverage::constructor: assigned IchiVault token1 is not a OneToken vault asset');

        emit LeverageStrategy(msg.sender, _oneToken, _description, pool, token0, token1, allowToken0, allowToken1);
    }

    /**
     @notice closes token positions and returns the funds to the oneToken vault
     @dev override this function to redeem and withdraw related funds from external contracts. Return false if any funds are unrecovered. 
     @param token asset to recover
     @param success true, complete success, false, 1 or more failed operations
     */
    function closePositions(address token) public strategyOwnerTokenOrController override virtual returns(bool success) {

    }



}
