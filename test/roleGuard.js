const { assert } = require("chai");
const truffleAssert = require('truffle-assertions');
const { expectEvent } = require("@openzeppelin/test-helpers");
const { getBigNumber } = require("./utilities");
const { BigNumber, utils } = require("ethers");
// const { artifacts } = require("hardhat");
// const { factory } = require("typescript");

const
    ArbitraryStrategy = artifacts.require("Arbitrary"),
    OneToken = artifacts.require("OneTokenV1"),
    Factory = artifacts.require("OneTokenFactory"),
    RoleGuard = artifacts.require("RoleGuardOneTokenV1ArbitraryStrategy"),
    OraclePegged = artifacts.require("ICHIPeggedOracle"),
    MintMasterIncremental = artifacts.require("Incremental"),
    MemberToken = artifacts.require("MemberToken"),
    CollateralToken = artifacts.require("CollateralToken"),
    NullStrategy = artifacts.require("NullStrategy"),
    ControllerCommon = artifacts.require("ControllerCommon"),
    TestController = artifacts.require("TestController"),
    ControllerNull = artifacts.require("NullController");

const
    NULL_ADDRESS = "0x0000000000000000000000000000000000000000";

const moduleType = {
    version: 0,
    controller: 1,
    strategy: 2,
    mintMaster: 3,
    oracle: 4,
    voterRoll: 5
}

let owner,
    alice,
    bob,
    version,
    factory,
    oneTokenAddress,
    oneToken,
    rg,
    controller,
    mintMaster,
    oracle,
    memberToken,
    collateralToken,
    secondOneTokenAddress,
    secondOneToken;

contract('Role Guard', accounts => {

    before(async () => {
        owner = accounts[0];
        alice = accounts[1];
        bob = accounts[2];

        version = await OneToken.deployed();
        factory = await Factory.deployed();
        oneTokenAddress = await factory.oneTokenAtIndex(0);
        oneToken = await OneToken.at(oneTokenAddress);

        controller = await ControllerNull.deployed();
        mintMaster = await MintMasterIncremental.deployed();
        oracle = await OraclePegged.deployed();
        memberToken = await MemberToken.deployed();
        collateralToken = await CollateralToken.deployed();

        const roleGuard = await RoleGuard.new(oneTokenAddress);
        RoleGuard.setAsDeployed(roleGuard);

        rg = await RoleGuard.deployed();

        arbitraryStrategy = await ArbitraryStrategy.new(factory.address, oneTokenAddress, "Test StrategyCommon");

        await factory.admitModule(arbitraryStrategy.address, moduleType.strategy, "arbitraryStrategy", "#");
        let allowance1 = 1000;
        let tx = await oneToken.setStrategy(collateralToken.address, arbitraryStrategy.address, allowance1);
        expectEvent(tx, 'StrategySet', {
            sender: owner,
            token: collateralToken.address,
            strategy: arbitraryStrategy.address,
            allowance: allowance1.toString()
        });

        // set RoleGuard as oneToken owner
        await oneToken.transferOwnership(rg.address, { from: owner });
        // set RoleGuard as ArbitraryStrategy owner
        await arbitraryStrategy.transferOwnership(rg.address, { from: owner });

    });

    it("should be ready to test", async () => {
        assert.isAtLeast(accounts.length, 3, "There are not at least three accounts to work with")
    });

    it("should have the right address set", async () => {
        let a = await rg.target();
        assert.strictEqual(a, oneTokenAddress, "the address of oneToken was not set properly");
    });

    it("Arbitrary Strategy functions", async () => {
        const 
            msg1 = "RoleGuardOneTokenV1::403 - unauthorized",
            msg2 = "ICHIOwnable: caller is not the owner",
            msg3 = "AccessControl: sender must be an admin to grant";


        const transferAmount = 1;
        await collateralToken.transfer(oneTokenAddress, transferAmount)

        const balance = await collateralToken.balanceOf(oneTokenAddress)
        const signature = "balanceOf(address)";
        const parameters = web3.eth.abi.encodeParameter('address', oneTokenAddress);

        // even RG owner needs a role to execute functions 
        await truffleAssert.reverts(rg.strategyExecuteTransaction(arbitraryStrategy.address, 
            collateralToken.address, 0, signature, parameters, { from: owner }), msg1);
        // owner is no longer able to access strategy's functions - RG is a new owner now
		await truffleAssert.reverts(arbitraryStrategy.executeTransaction(collateralToken.address, 0, 
            signature, parameters, { from: owner }), msg2);
        // RG is a true owner - but can't execute anything. It has no ETH and can't receive any

        let role = utils.keccak256(utils.toUtf8Bytes("function strategyExecuteTransaction(address strategy, address _target, uint256 value, string memory signature, bytes memory data)"));

		// only owner of RG can grant roles
        await truffleAssert.reverts(rg.grantRole(role, alice, { from: alice }), msg3);
        await rg.grantRole(role, alice, { from: owner });

        // alice can't execute strategy directly, but can do it via RG
		await truffleAssert.reverts(arbitraryStrategy.executeTransaction(collateralToken.address, 0, 
            signature, parameters, { from: alice }), msg2);
        let tx = await rg.strategyExecuteTransaction.call(arbitraryStrategy.address, 
            collateralToken.address, 0, signature, parameters, { from: alice });
        assert.notEqual(balance.toNumber(), 0, "should have positive balance");
        assert.equal(balance.toNumber(), web3.utils.hexToNumber(tx), "should return same balance");
        await rg.strategyExecuteTransaction(arbitraryStrategy.address, 
            collateralToken.address, 0, signature, parameters, { from: alice });

        // owner still can't do it without a role         
        await truffleAssert.reverts(rg.strategyExecuteTransaction(arbitraryStrategy.address, 
            collateralToken.address, 0, signature, parameters, { from: owner }), msg1);

    });

    it("Common Strategy functions", async () => {
        const 
            msg1 = "RoleGuardOneTokenV1::403 - unauthorized",
            msg2 = "StrategyCommon: not token controller or owner.",
            msg3 = "AccessControl: sender must be an admin to grant",
            msg4 = "ICHIOwnable: caller is not the owner";

        // **** execute ****

        // even RG owner needs a role to execute functions 
        await truffleAssert.reverts(rg.execute(arbitraryStrategy.address, { from: owner }), msg1);
        // owner is no longer able to access strategy's functions - RG is a new owner now
		await truffleAssert.reverts(arbitraryStrategy.execute({ from: owner }), msg2);
        // RG is a true owner - but can't execute anything. It has no ETH and can't receive any

        let role = utils.keccak256(utils.toUtf8Bytes("function execute(address strategy)"));

		// only owner of RG can grant roles
        await truffleAssert.reverts(rg.grantRole(role, alice, { from: alice }), msg3);
        await rg.grantRole(role, alice, { from: owner });

        // alice can't execute strategy directly, but can do it via RG
		await truffleAssert.reverts(arbitraryStrategy.execute({ from: alice }), msg2);
        await rg.execute(arbitraryStrategy.address, { from: alice });
        // owner still can't do it without a role         
        await truffleAssert.reverts(rg.execute(arbitraryStrategy.address, { from: owner }), msg1);

        // **** setAllowance ****

        await truffleAssert.reverts(rg.setAllowance(arbitraryStrategy.address, collateralToken.address, 100, { from: owner }), msg1);
		await truffleAssert.reverts(arbitraryStrategy.setAllowance(collateralToken.address, 100, { from: owner }), msg2);
        role = utils.keccak256(utils.toUtf8Bytes("function setAllowance(address strategy, address token, uint256 amount)"));
        await truffleAssert.reverts(rg.grantRole(role, alice, { from: alice }), msg3);
        await rg.grantRole(role, alice, { from: owner });
		await truffleAssert.reverts(arbitraryStrategy.setAllowance(collateralToken.address, 100, { from: alice }), msg2);
        await rg.setAllowance(arbitraryStrategy.address, collateralToken.address, 100, { from: alice });
        await truffleAssert.reverts(rg.setAllowance(arbitraryStrategy.address, collateralToken.address, 100, { from: owner }), msg1);

        // **** toVault ****

        const transferAmount = 100;
        await collateralToken.transfer(arbitraryStrategy.address, transferAmount)

        await truffleAssert.reverts(rg.toVault(arbitraryStrategy.address, collateralToken.address, 100, { from: owner }), msg1);
		await truffleAssert.reverts(arbitraryStrategy.toVault(collateralToken.address, 100, { from: owner }), msg2);
        role = utils.keccak256(utils.toUtf8Bytes("function toVault(address strategy, address token, uint256 amount)"));
        await truffleAssert.reverts(rg.grantRole(role, alice, { from: alice }), msg3);
        await rg.grantRole(role, alice, { from: owner });
		await truffleAssert.reverts(arbitraryStrategy.toVault(collateralToken.address, 100, { from: alice }), msg2);
        await rg.toVault(arbitraryStrategy.address, collateralToken.address, 100, { from: alice });
        await truffleAssert.reverts(rg.toVault(arbitraryStrategy.address, collateralToken.address, 100, { from: owner }), msg1);

        // **** fromVault ****

        await truffleAssert.reverts(rg.fromVault(arbitraryStrategy.address, collateralToken.address, 100, { from: owner }), msg1);
		await truffleAssert.reverts(arbitraryStrategy.fromVault(collateralToken.address, 100, { from: owner }), msg2);
        role = utils.keccak256(utils.toUtf8Bytes("function fromVault(address strategy, address token, uint256 amount)"));
        await truffleAssert.reverts(rg.grantRole(role, alice, { from: alice }), msg3);
        await rg.grantRole(role, alice, { from: owner });
		await truffleAssert.reverts(arbitraryStrategy.fromVault(collateralToken.address, 100, { from: alice }), msg2);
        await rg.fromVault(arbitraryStrategy.address, collateralToken.address, 100, { from: alice });
        await truffleAssert.reverts(rg.fromVault(arbitraryStrategy.address, collateralToken.address, 100, { from: owner }), msg1);
        await rg.toVault(arbitraryStrategy.address, collateralToken.address, 100, { from: alice }); // cleanup

        // **** closeAllPositions ****

        await collateralToken.transfer(arbitraryStrategy.address, transferAmount)

        await truffleAssert.reverts(rg.closeAllPositions(arbitraryStrategy.address, { from: owner }), msg1);
		await truffleAssert.reverts(arbitraryStrategy.closeAllPositions({ from: owner }), msg2);
        role = utils.keccak256(utils.toUtf8Bytes("function closeAllPositions(address strategy)"));
        await truffleAssert.reverts(rg.grantRole(role, alice, { from: alice }), msg3);
        await rg.grantRole(role, alice, { from: owner });
		await truffleAssert.reverts(arbitraryStrategy.closeAllPositions({ from: alice }), msg2);
        await rg.closeAllPositions(arbitraryStrategy.address, { from: alice });
        await truffleAssert.reverts(rg.closeAllPositions(arbitraryStrategy.address, { from: owner }), msg1);
        let balance = await collateralToken.balanceOf(arbitraryStrategy.address)
        assert.equal(balance.toNumber(), 0, "no funds should remain in the strategy");

        // **** closePositions ****

        await collateralToken.transfer(arbitraryStrategy.address, transferAmount)

        await truffleAssert.reverts(rg.closePositions(arbitraryStrategy.address, collateralToken.address, { from: owner }), msg1);
		await truffleAssert.reverts(arbitraryStrategy.closePositions(collateralToken.address, { from: owner }), msg2);
        role = utils.keccak256(utils.toUtf8Bytes("function closePositions(address strategy, address token)"));
        await truffleAssert.reverts(rg.grantRole(role, alice, { from: alice }), msg3);
        await rg.grantRole(role, alice, { from: owner });
		await truffleAssert.reverts(arbitraryStrategy.closePositions(collateralToken.address, { from: alice }), msg2);
        await rg.closePositions(arbitraryStrategy.address, collateralToken.address, { from: alice });
        await truffleAssert.reverts(rg.closePositions(arbitraryStrategy.address, collateralToken.address, { from: owner }), msg1);
        balance = await collateralToken.balanceOf(arbitraryStrategy.address)
        assert.equal(balance.toNumber(), 0, "no funds should remain in the strategy");

        // **** updateDescription ****

        let newDescription = "new description";
        await truffleAssert.reverts(rg.updateDescription(arbitraryStrategy.address, newDescription, { from: owner }), msg1);
		await truffleAssert.reverts(arbitraryStrategy.updateDescription(newDescription, { from: owner }), msg4);
        role = utils.keccak256(utils.toUtf8Bytes("function updateDescription(address strategy, string memory description)"));
        await truffleAssert.reverts(rg.grantRole(role, alice, { from: alice }), msg3);
        await rg.grantRole(role, alice, { from: owner });
		await truffleAssert.reverts(arbitraryStrategy.updateDescription(newDescription, { from: alice }), msg4);
        await rg.updateDescription(arbitraryStrategy.address, newDescription, { from: alice });
        await truffleAssert.reverts(rg.updateDescription(arbitraryStrategy.address, newDescription, { from: owner }), msg1);
        let desc = await arbitraryStrategy.moduleDescription();
        assert.equal(desc, newDescription, "description should be updated");

    });

    it("V1 functions", async () => {
        const 
            msg1 = "RoleGuardOneTokenV1::403 - unauthorized",
            msg2 = "ICHIERC20: transfer amount exceeds allowance",
            msg3 = "AccessControl: sender must be an admin to grant",
            msg4 = "OTV1: NSF: collateral token",
            msg5 = "OTV1: NSF: oneToken",
            msg6 = "ICHIOwnable: caller is not the owner";

        // **** mint ****

        await truffleAssert.reverts(rg.mint(collateralToken.address, "1000", { from: owner }), msg1);
        // public function is allowed to anyone
		await truffleAssert.reverts(oneToken.mint(collateralToken.address, "1000", { from: owner }), msg2);

        let role = utils.keccak256(utils.toUtf8Bytes("function mint(address collateral, uint oneTokens)"));

        await truffleAssert.reverts(rg.grantRole(role, alice, { from: alice }), msg3);
        await rg.grantRole(role, alice, { from: owner });

		await truffleAssert.reverts(oneToken.mint(collateralToken.address, "1000", { from: alice }), msg4);
        // public function is allowed to anyone
        await truffleAssert.reverts(rg.mint(collateralToken.address, "1000", { from: alice }), msg4);
        await truffleAssert.reverts(rg.mint(collateralToken.address, "1000", { from: owner }), msg1);

        // **** redeem ****

        await truffleAssert.reverts(rg.redeem(collateralToken.address, "1000", { from: owner }), msg1);
		await truffleAssert.reverts(oneToken.redeem(collateralToken.address, "1000", { from: owner }), msg5);
        role = utils.keccak256(utils.toUtf8Bytes("function redeem(address collateral, uint amount)"));
        await truffleAssert.reverts(rg.grantRole(role, alice, { from: alice }), msg3);
        await rg.grantRole(role, alice, { from: owner });
		await truffleAssert.reverts(oneToken.redeem(collateralToken.address, "1000", { from: alice }), msg5);
        // public function is allowed to anyone
        await truffleAssert.reverts(rg.redeem(collateralToken.address, "1000", { from: alice }), msg5);
        await truffleAssert.reverts(rg.redeem(collateralToken.address, "1000", { from: owner }), msg1);

        // **** setMintingFee ****

        const FEE_10 =     "100000000000000000"; // 10%

        await truffleAssert.reverts(rg.setMintingFee(FEE_10, { from: owner }), msg1);
		await truffleAssert.reverts(oneToken.setMintingFee(FEE_10, { from: owner }), msg6);
        role = utils.keccak256(utils.toUtf8Bytes("function setMintingFee(uint fee)"));
        await truffleAssert.reverts(rg.grantRole(role, alice, { from: alice }), msg3);
        await rg.grantRole(role, alice, { from: owner });
		await truffleAssert.reverts(oneToken.setMintingFee(FEE_10, { from: alice }), msg6);
        await rg.setMintingFee(FEE_10, { from: alice });
        await truffleAssert.reverts(rg.setMintingFee(FEE_10, { from: owner }), msg1);
        await rg.setMintingFee(0, { from: alice });

        // **** setRedemptionFee ****

        await truffleAssert.reverts(rg.setRedemptionFee(FEE_10, { from: owner }), msg1);
		await truffleAssert.reverts(oneToken.setRedemptionFee(FEE_10, { from: owner }), msg6);
        role = utils.keccak256(utils.toUtf8Bytes("function setRedemptionFee(uint fee)"));
        await truffleAssert.reverts(rg.grantRole(role, alice, { from: alice }), msg3);
        await rg.grantRole(role, alice, { from: owner });
		await truffleAssert.reverts(oneToken.setRedemptionFee(FEE_10, { from: alice }), msg6);
        await rg.setRedemptionFee(FEE_10, { from: alice });
        await truffleAssert.reverts(rg.setRedemptionFee(FEE_10, { from: owner }), msg1);
        await rg.setRedemptionFee(0, { from: alice });

        // **** updateMintingRatio ****

        await truffleAssert.reverts(rg.updateMintingRatio(collateralToken.address, { from: owner }), msg1);
		await oneToken.updateMintingRatio(collateralToken.address, { from: owner });
        role = utils.keccak256(utils.toUtf8Bytes("function updateMintingRatio(address collateralToken)"));
        await truffleAssert.reverts(rg.grantRole(role, alice, { from: alice }), msg3);
        await rg.grantRole(role, alice, { from: owner });
		await oneToken.updateMintingRatio(collateralToken.address, { from: alice });
        await rg.updateMintingRatio(collateralToken.address, { from: alice });
        await truffleAssert.reverts(rg.updateMintingRatio(collateralToken.address, { from: owner }), msg1);

    });

    it("Base functions", async () => {
        const 
            msg1 = "RoleGuardOneTokenV1::403 - unauthorized",
            msg2 = "ICHIOwnable: caller is not the owner",
            msg3 = "AccessControl: sender must be an admin to grant",
            msg4 = "OTV1B: not owner or controller";

        // **** changeController ****

        // even RG owner needs a role to execute functions 
        await truffleAssert.reverts(rg.changeController(controller.address, { from: owner }), msg1);
        // owner is no longer able to access functions - RG is a new owner now
		await truffleAssert.reverts(oneToken.changeController(controller.address, { from: owner }), msg2);

        let role = utils.keccak256(utils.toUtf8Bytes("function changeController(address controller_)"));

        await truffleAssert.reverts(rg.grantRole(role, alice, { from: alice }), msg3);
        await rg.grantRole(role, alice, { from: owner });

		await truffleAssert.reverts(oneToken.changeController(controller.address, { from: alice }), msg2);
        let tx = await rg.changeController(controller.address, { from: alice });
		expectEvent.inTransaction(tx.tx, ControllerNull, 'ControllerInitialized', {})

        // **** changeMintMaster ****

        await truffleAssert.reverts(rg.changeMintMaster(mintMaster.address, oracle.address, { from: owner }), msg1);
		await truffleAssert.reverts(oneToken.changeMintMaster(mintMaster.address, oracle.address, { from: owner }), msg2);
        role = utils.keccak256(utils.toUtf8Bytes("function changeMintMaster(address mintMaster_, address oneTokenOracle)"));
        await truffleAssert.reverts(rg.grantRole(role, alice, { from: alice }), msg3);
        await rg.grantRole(role, alice, { from: owner });
		await truffleAssert.reverts(oneToken.changeMintMaster(mintMaster.address, oracle.address, { from: alice }), msg2);
        tx = await rg.changeMintMaster(mintMaster.address, oracle.address, { from: alice });
        expectEvent.inTransaction(tx.tx, MintMasterIncremental, 'MintMasterInitialized', {})

        // **** addAsset ****

        let cToken = await CollateralToken.new();
		const oraclePegged = await OraclePegged.new(factory.address, "oracleName", cToken.address);
		await factory.admitModule(oraclePegged.address, moduleType.oracle, "oraclePegged", "#")
		await factory.admitForeignToken(cToken.address, true, oraclePegged.address)

        await truffleAssert.reverts(rg.addAsset(cToken.address, oraclePegged.address, { from: owner }), msg1);
		await truffleAssert.reverts(oneToken.addAsset(cToken.address, oraclePegged.address, { from: owner }), msg2);
        role = utils.keccak256(utils.toUtf8Bytes("function addAsset(address token, address oracle)"));
        await truffleAssert.reverts(rg.grantRole(role, alice, { from: alice }), msg3);
        await rg.grantRole(role, alice, { from: owner });
		await truffleAssert.reverts(oneToken.addAsset(cToken.address, oraclePegged.address, { from: alice }), msg2);
        tx = await rg.addAsset(cToken.address, oraclePegged.address, { from: alice });
        expectEvent.inTransaction(tx.tx, OneToken, 'AssetAdded', {})

        // **** removeAsset ****

        await truffleAssert.reverts(rg.removeAsset(cToken.address, { from: owner }), msg1);
		await truffleAssert.reverts(oneToken.removeAsset(cToken.address, { from: owner }), msg2);
        role = utils.keccak256(utils.toUtf8Bytes("function removeAsset(address token)"));
        await truffleAssert.reverts(rg.grantRole(role, alice, { from: alice }), msg3);
        await rg.grantRole(role, alice, { from: owner });
		await truffleAssert.reverts(oneToken.removeAsset(cToken.address, { from: alice }), msg2);
        tx = await rg.removeAsset(cToken.address, { from: alice });
        expectEvent.inTransaction(tx.tx, OneToken, 'AssetRemoved', {})

        // **** setStrategy ****

        let newStrategy = await NullStrategy.new(factory.address, oneToken.address, "new strategy", { from: owner });
        await factory.admitModule(newStrategy.address, moduleType.strategy, "new strategy", "url");

        await truffleAssert.reverts(rg.setStrategy(collateralToken.address, newStrategy.address, 1000, { from: owner }), msg1);
		await truffleAssert.reverts(oneToken.setStrategy(collateralToken.address, newStrategy.address, 1000, { from: owner }), msg2);
        role = utils.keccak256(utils.toUtf8Bytes("function setStrategy(address token, address strategy, uint256 allowance)"));
        await truffleAssert.reverts(rg.grantRole(role, alice, { from: alice }), msg3);
        await rg.grantRole(role, alice, { from: owner });
		await truffleAssert.reverts(oneToken.setStrategy(collateralToken.address, newStrategy.address, 1000, { from: alice }), msg2);

        // "OTV1B: unknown strategy owner" is thrown if owner is not changed
        await newStrategy.transferOwnership(rg.address, { from: owner });

        tx = await rg.setStrategy(collateralToken.address, newStrategy.address, 1000, { from: alice });
        expectEvent.inTransaction(tx.tx, OneToken, 'StrategySet', {})

        // **** executeStrategy ****

        await truffleAssert.reverts(rg.executeStrategy(collateralToken.address, { from: owner }), msg1);
		await truffleAssert.reverts(oneToken.executeStrategy(collateralToken.address, { from: owner }), msg4);
        role = utils.keccak256(utils.toUtf8Bytes("function executeStrategy(address token)"));
        await truffleAssert.reverts(rg.grantRole(role, alice, { from: alice }), msg3);
        await rg.grantRole(role, alice, { from: owner });
		await truffleAssert.reverts(oneToken.executeStrategy(collateralToken.address, { from: alice }), msg4);
        tx = await rg.executeStrategy(collateralToken.address, { from: alice });
        expectEvent.inTransaction(tx.tx, OneToken, 'StrategyExecuted', {})

        // **** increaseStrategyAllowance ****

        await truffleAssert.reverts(rg.increaseStrategyAllowance(collateralToken.address, 100, { from: owner }), msg1);
		await truffleAssert.reverts(oneToken.increaseStrategyAllowance(collateralToken.address, 100, { from: owner }), msg4);
        role = utils.keccak256(utils.toUtf8Bytes("function increaseStrategyAllowance(address token, uint256 amount)"));
        await truffleAssert.reverts(rg.grantRole(role, alice, { from: alice }), msg3);
        await rg.grantRole(role, alice, { from: owner });
		await truffleAssert.reverts(oneToken.increaseStrategyAllowance(collateralToken.address, 100, { from: alice }), msg4);
        tx = await rg.increaseStrategyAllowance(collateralToken.address, 100, { from: alice });
        expectEvent.inTransaction(tx.tx, OneToken, 'StrategyAllowanceIncreased', {})

        // **** decreaseStrategyAllowance ****

        await truffleAssert.reverts(rg.decreaseStrategyAllowance(collateralToken.address, 100, { from: owner }), msg1);
		await truffleAssert.reverts(oneToken.decreaseStrategyAllowance(collateralToken.address, 100, { from: owner }), msg4);
        role = utils.keccak256(utils.toUtf8Bytes("function decreaseStrategyAllowance(address token, uint256 amount)"));
        await truffleAssert.reverts(rg.grantRole(role, alice, { from: alice }), msg3);
        await rg.grantRole(role, alice, { from: owner });
		await truffleAssert.reverts(oneToken.decreaseStrategyAllowance(collateralToken.address, 100, { from: alice }), msg4);
        tx = await rg.decreaseStrategyAllowance(collateralToken.address, 100, { from: alice });
        expectEvent.inTransaction(tx.tx, OneToken, 'StrategyAllowanceDecreased', {})

        // **** toStrategy ****

        await collateralToken.transfer(oneToken.address, 100);

        await truffleAssert.reverts(rg.toStrategy(newStrategy.address, collateralToken.address, 100, { from: owner }), msg1);
		await truffleAssert.reverts(oneToken.toStrategy(newStrategy.address, collateralToken.address, 100, { from: owner }), msg4);
        role = utils.keccak256(utils.toUtf8Bytes("function toStrategy(address strategy, address token, uint256 amount)"));
        await truffleAssert.reverts(rg.grantRole(role, alice, { from: alice }), msg3);
        await rg.grantRole(role, alice, { from: owner });
		await truffleAssert.reverts(oneToken.toStrategy(newStrategy.address, collateralToken.address, 100, { from: alice }), msg4);
        tx = await rg.toStrategy(newStrategy.address, collateralToken.address, 100, { from: alice });
        expectEvent.inTransaction(tx.tx, OneToken, 'ToStrategy', {})
        let balance = await collateralToken.balanceOf(newStrategy.address)
        assert.equal(balance.toNumber(), 100, "incorrect funds in strategy");

        // **** fromStrategy ****

        await truffleAssert.reverts(rg.fromStrategy(newStrategy.address, collateralToken.address, 100, { from: owner }), msg1);
		await truffleAssert.reverts(oneToken.fromStrategy(newStrategy.address, collateralToken.address, 100, { from: owner }), msg4);
        role = utils.keccak256(utils.toUtf8Bytes("function fromStrategy(address strategy, address token, uint256 amount)"));
        await truffleAssert.reverts(rg.grantRole(role, alice, { from: alice }), msg3);
        await rg.grantRole(role, alice, { from: owner });
		await truffleAssert.reverts(oneToken.fromStrategy(newStrategy.address, collateralToken.address, 100, { from: alice }), msg4);
        tx = await rg.fromStrategy(newStrategy.address, collateralToken.address, 100, { from: alice });
        expectEvent.inTransaction(tx.tx, OneToken, 'FromStrategy', {})
        balance = await collateralToken.balanceOf(newStrategy.address)
        assert.equal(balance.toNumber(), 0, "incorrect funds in strategy");

        // **** closeStrategy ****

        await truffleAssert.reverts(rg.closeStrategy(collateralToken.address, { from: owner }), msg1);
		await truffleAssert.reverts(oneToken.closeStrategy(collateralToken.address, { from: owner }), msg4);
        role = utils.keccak256(utils.toUtf8Bytes("function closeStrategy(address token)"));
        await truffleAssert.reverts(rg.grantRole(role, alice, { from: alice }), msg3);
        await rg.grantRole(role, alice, { from: owner });
		await truffleAssert.reverts(oneToken.closeStrategy(collateralToken.address, { from: alice }), msg4);
        tx = await rg.closeStrategy(collateralToken.address, { from: alice });
        expectEvent.inTransaction(tx.tx, OneToken, 'StrategyClosed', {})

        // **** removeStrategy ****

        await truffleAssert.reverts(rg.removeStrategy(collateralToken.address, { from: owner }), msg1);
		await truffleAssert.reverts(oneToken.removeStrategy(collateralToken.address, { from: owner }), msg2);
        role = utils.keccak256(utils.toUtf8Bytes("function removeStrategy(address token)"));
        await truffleAssert.reverts(rg.grantRole(role, alice, { from: alice }), msg3);
        await rg.grantRole(role, alice, { from: owner });
		await truffleAssert.reverts(oneToken.removeStrategy(collateralToken.address, { from: alice }), msg2);
        tx = await rg.removeStrategy(collateralToken.address, { from: alice });
        expectEvent.inTransaction(tx.tx, OneToken, 'StrategyRemoved', {})

        // **** setFactory ****

        await truffleAssert.reverts(rg.setFactory(factory.address, { from: owner }), msg1);
		await truffleAssert.reverts(oneToken.setFactory(factory.address, { from: owner }), msg2);
        role = utils.keccak256(utils.toUtf8Bytes("function setFactory(address newFactory)"));
        await truffleAssert.reverts(rg.grantRole(role, alice, { from: alice }), msg3);
        await rg.grantRole(role, alice, { from: owner });
		await truffleAssert.reverts(oneToken.setFactory(factory.address, { from: alice }), msg2);
        tx = await rg.setFactory(factory.address, { from: alice });
        expectEvent.inTransaction(tx.tx, OneToken, 'NewFactory', {})

    });

    it("ERC20 operations", async () => {
        const 
            msg1 = "RoleGuardOneTokenV1::403 - unauthorized",
            msg2 = "ICHIOwnable: caller is not the owner",
            msg3 = "AccessControl: sender must be an admin to grant",
            msg4 = "ICHIERC20: transfer amount exceeds allowance";

        const transferAmount = 1000;
        await collateralToken.transfer(rg.address, transferAmount)
        let balance = await collateralToken.balanceOf(rg.address)

        // even RG owner needs a role to execute functions 
        await truffleAssert.reverts(rg.erc20Transfer(collateralToken.address, alice, 100, { from: owner }), msg1);
        await truffleAssert.reverts(rg.erc20Approve(collateralToken.address, alice, 100, { from: owner }), msg1);
        await truffleAssert.reverts(rg.erc20IncreaseAllowance(collateralToken.address, alice, 100, { from: owner }), msg1);
        await truffleAssert.reverts(rg.erc20DecreaseAllowance(collateralToken.address, alice, 100, { from: owner }), msg1);

        let role = utils.keccak256(utils.toUtf8Bytes("Role Guard Treasurer"));

        await truffleAssert.reverts(rg.grantRole(role, alice, { from: alice }), msg3);
        await rg.grantRole(role, alice, { from: owner });

        await truffleAssert.reverts(rg.erc20Transfer(collateralToken.address, alice, 100, { from: owner }), msg1);
        await rg.erc20Transfer(collateralToken.address, alice, 100, { from: alice });

        balance = await collateralToken.balanceOf(rg.address)
        assert.equal(balance.toNumber(), 900, "should return new balance");

        await truffleAssert.reverts(collateralToken.transferFrom(rg.address, alice, 100, { from: alice }), msg4);
        await rg.erc20Approve(collateralToken.address, alice, 100, { from: alice });
        await truffleAssert.reverts(collateralToken.transferFrom(rg.address, alice, 100, { from: owner }), msg4);
        await collateralToken.transferFrom(rg.address, alice, 100, { from: alice });

        balance = await collateralToken.balanceOf(rg.address)
        assert.equal(balance.toNumber(), 800, "should return new balance");

        await truffleAssert.reverts(collateralToken.transferFrom(rg.address, alice, 100, { from: alice }), msg4);
        await rg.erc20IncreaseAllowance(collateralToken.address, alice, 200, { from: alice });
        await rg.erc20DecreaseAllowance(collateralToken.address, alice, 100, { from: alice });
        await truffleAssert.reverts(collateralToken.transferFrom(rg.address, alice, 101, { from: alice }), msg4);
        await collateralToken.transferFrom(rg.address, alice, 100, { from: alice });

        balance = await collateralToken.balanceOf(rg.address)
        assert.equal(balance.toNumber(), 700, "should return new balance");

    });

    it("roleGuardExecuteTransaction functions", async () => {
        const 
            msg1 = "RoleGuardOneTokenV1::403 - unauthorized";

        const transferAmount = 1;
        await collateralToken.transfer(rg.address, transferAmount)

        const balance = await collateralToken.balanceOf(rg.address)
        const signature = "balanceOf(address)";
        const parameters = web3.eth.abi.encodeParameter('address', rg.address);

        // user needs a role to execute functions 
        await truffleAssert.reverts(rg.roleGuardExecuteTransaction(collateralToken.address, 0, 
            signature, parameters, { from: alice }), msg1);

        // owner has the right role
        let tx = await rg.roleGuardExecuteTransaction.call(collateralToken.address, 0, 
            signature, parameters, { from: owner });
        assert.notEqual(balance.toNumber(), 0, "should have positive balance");
        assert.equal(balance.toNumber(), web3.utils.hexToNumber(tx), "should return same balance");
        await rg.roleGuardExecuteTransaction(collateralToken.address, 0, signature, parameters, { from: owner });

    });

});