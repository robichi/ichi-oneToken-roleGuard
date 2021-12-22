// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;
pragma abicoder v2;

import '../../components/Composable.sol';

contract ComposableOneTokenV1RoleGuard is Composable {

    constructor() {
            registerFunction('mint(address,oneTokens)', false);
            registerFunction('redeem(address,uint256)', false);
            registerFunction('setMintingFee(uint)', false);
            registerFunction('setRedemptionFee(uint)', false);
            registerFunction('updateMintingRatio(address)', false);
            registerFunction('changeController(address)', false);
            registerFunction('changeMintMaster(address,oneTokenOracle)', false);
            registerFunction('addAsset(address,oracle)', false);
            registerFunction('removeAsset(address)', false);
            registerFunction('setStrategy(address,address,uint256)', false);
            registerFunction('executeStrategy(address)', false);
            registerFunction('removeStrategy(address)', false);
            registerFunction('closeStrategy(address)', false);
            registerFunction('increaseStrategyAllowance(address,uint256)', false);
            registerFunction('decreaseStrategyAllowance(address,uint256)', false);
            registerFunction('setFactory(address)', false);
    }

}