// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

import '../../components/Composable.sol';

contract ComposableOneTokenV1RoleGuard is Composable {

    function initialize() external uninitialized {
            registerFunction('mint(address,uint)', false); // VS: do we want to normalize uint as unit256?
            registerFunction('redeem(address,uint256)', false);
            registerFunction('setMintingFee(uint)', false);
            registerFunction('setRedemptionFee(uint)', false);
            registerFunction('updateMintingRatio(address)', false);
            registerFunction('changeController(address)', false);
            registerFunction('changeMintMaster(address,address)', false);
            registerFunction('addAsset(address,address)', false);
            registerFunction('removeAsset(address)', false);
            registerFunction('setStrategy(address,address,uint256)', false);
            registerFunction('executeStrategy(address)', false);
            registerFunction('removeStrategy(address)', false);
            registerFunction('closeStrategy(address)', false);
            registerFunction('toStrategy(address,address,uint256)', false);
            registerFunction('fromStrategy(address,address,uint256)', false);
            registerFunction('increaseStrategyAllowance(address,uint256)', false);
            registerFunction('decreaseStrategyAllowance(address,uint256)', false);
            registerFunction('setFactory(address)', false);
            setInitialized();
    }

}