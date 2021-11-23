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
    address public immutable token0;
    address public immutable token1;
    address public immutable memberToken;
    address public immutable collateral;
    bool public immutable allowToken0;
    bool public immutable allowToken1;

    event LeverageStrategy(address sender, address oneToken, string description, address pool, address token0, address token1, bool allowToken0, bool allowToken1);
    event Execute(address sender, uint256 allowance0, uint256 allowance1, uint256 shares);

    /**
     @notice A leverage strategy uses a deployed IchiVault that works with two assets that are known to the OneToken vault
     @param _oneTokenFactory bind this instance to oneTokenFactory instance
     @param _oneToken bind this instance to one oneToken vault
     @param _description metadata has no impact on logic
     @param _ichiVault ichiVault to use for LP position management
     @param _ichiVaultFactory _factory for validation purposes
     */
    constructor(
        address _oneTokenFactory, 
        address _oneToken, 
        string memory _description,
        address _collateral,
        address _ichiVault,
        address _ichiVaultFactory
        ) 
        StrategyCommon(_oneTokenFactory, _oneToken, _description)
    {
        // address pool = IICHIVault(_ichiVault).pool();
        try IICHIVault(_ichiVault).pool() returns(address _pool) {
            require(_ichiVaultFactory == IICHIVault(_ichiVault).ichiVaultFactory(), 'Leverage::constructor: vault-reported ichiVaultFactory mismatch');
            ichiVault = IICHIVault(_ichiVault);
            ichiVaultFactory = IICHIVaultFactory(_ichiVaultFactory);

            address _token0 = IICHIVault(_ichiVault).token0();
            address _token1 = IICHIVault(_ichiVault).token1();            
            bool _allowToken0 = IICHIVault(_ichiVault).allowToken0();
            bool _allowToken1 = IICHIVault(_ichiVault).allowToken1(); 
            address _memberToken = IOneTokenV1(oneToken).memberToken();
            address _leverageToken = (_memberToken != _token0) ? _token0 : _token1;

            if(_leverageToken == _token0) {
                require( _memberToken == _token1, 'Leverage::constructor: member token from OneToken is not used in the given IchiVault (1)');
            } else {
                require( _memberToken == _token0, 'Leverage::constructor: member token from OneToken is not used in the given IchiVault (2)');
            }
            require(_leverageToken == _oneToken, 'Leverage::constructor: oneToken is not used the given Ichivault');
            require(IOneTokenV1Base(_oneToken).isCollateral(_collateral), 'Leverage::constructor: collateral');
            require(IOneTokenV1(_oneToken).isAsset(IICHIVault(_ichiVault).token0()), 'Leverage::constructor: assigned IchiVault token0 is not a OneToken vault asset');
            require(IOneTokenV1(_oneToken).isAsset(IICHIVault(_ichiVault).token1()), 'Leverage::constructor: assigned IchiVault token1 is not a OneToken vault asset');

            token0 = _token0;
            token1 = _token1;
            allowToken0 = _allowToken0;
            allowToken1 = _allowToken1;
            memberToken = _memberToken;
            collateral = _collateral;

            emit LeverageStrategy(
                msg.sender, 
                _oneToken, 
                _description, 
                _pool, 
                _token0, 
                _token1, 
                _allowToken0,
                _allowToken1);
        } catch {
            revert('Leverage::constructor: ichiVault contract address is not an ichiVault.');
        }
    }

    /**
     TODO: This access control recognizes the OneToken owner which could be a roleGuard if the roleGuard is made aware of strategies, generally, and this one in particular.
     */

    /**
     @notice Increase leverage. Draws the maximum funds permitted by the allowance granted by the OneToken vault to the strategy
     @dev called from oneToken governance or the active controller. Overriding function should emit the event. 
     */  
    function execute() external virtual strategyOwnerTokenOrController override {
        uint256 allowance0 = IERC20(token0).allowance(oneToken, address(this));
        uint256 allowance1 = IERC20(token1).allowance(oneToken, address(this));
        uint256 depositMax0 = IICHIVault(ichiVault).deposit0Max();
        uint256 depositMax1 = IICHIVault(ichiVault).deposit1Max();

        if(allowance0 > 0) IERC20(token0).safeTransferFrom(oneToken, address(this), allowance0);
        if(allowance1 > 0) IERC20(token1).safeTransferFrom(oneToken, address(this), allowance1);



/*
maximum deposit

        allowance0 = (allowance0 <= depositMax0 || depositMax0 == 0) ? allowance0 : depositMax0;
        allowance1 = (allowance1 <= depositMax1 || depositMax1 == 0) ? allowance1 : depositMax0;

*/

        uint256 shares = IICHIVault(ichiVault).deposit(allowance0, allowance1, address(this));
        emit Execute(msg.sender, allowance0, allowance1, shares);
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
