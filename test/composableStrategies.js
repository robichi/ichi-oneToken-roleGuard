const truffleAssert = require("truffle-assertions");
const { assert } = require("chai");
const { expectEvent } = require("@openzeppelin/test-helpers");

const
	ArbitraryStrategy = artifacts.require("Arbitrary"),
	NullStrategy = artifacts.require("NullStrategy"),
	OraclePegged = artifacts.require("ICHIPeggedOracle"),
	Factory = artifacts.require("OneTokenFactory"),
    ControllerNull = artifacts.require("NullController"),
    MintMasterIncremental = artifacts.require("Incremental"),
    MemberToken = artifacts.require("MemberToken"),
	CollateralToken = artifacts.require("CollateralToken"),
	StrategyCommon = artifacts.require("StrategyCommon"),
    OneTokenProxyAdmin = artifacts.require("OneTokenProxyAdmin"),
	OneToken = artifacts.require("OneTokenV1");

const NULL_ADDRESS = "0x0000000000000000000000000000000000000000";

let governance, 
	oneTokenAddress, 
	oneToken, 
    secondOneToken,
    secondOneTokenAddress,
	factory, 
	arbitraryStrategy, 
    controller,
    mintMaster,
    oracle,
    memberToken,
	collateralToken;

const moduleType = {
	version: 0,
	controller: 1,
	strategy: 2,
	mintMaster: 3,
	oracle: 4,
	voterRoll: 5
}

contract("Composable strategies", accounts => {
	
	beforeEach(async () => {
		governance = accounts[0];
        badAddress = accounts[1];
		factory = await Factory.deployed();
        controller = await ControllerNull.deployed();
        mintMaster = await MintMasterIncremental.deployed();
        oracle = await OraclePegged.deployed();
        memberToken = await MemberToken.deployed();
        collateralToken1 = await CollateralToken.deployed();
		oneTokenAddress = await factory.oneTokenAtIndex(0);
		oneToken = await OneToken.at(oneTokenAddress);

		// deploy second oneToken
        const 
            oneTokenName = "Second OneToken Instance",
            symbol = "OTI-2",
            versionName = "OneTokenV1-2",
            url = "#";
        secondOneToken  = await OneToken.new();
        OneToken.setAsDeployed(secondOneToken);
        await factory.admitModule(secondOneToken.address, moduleType.version, versionName, url);
        await factory.deployOneTokenProxy(
            oneTokenName,
            symbol,
            governance,
            secondOneToken.address,
            controller.address,
            mintMaster.address,
            oracle.address,
            memberToken.address,
            collateralToken1.address
        )
        secondOneTokenAddress = await factory.oneTokenAtIndex(1);
        secondOneToken = await OneToken.at(secondOneTokenAddress);
	});
	
	it("should be ready to test", async () => {
		assert.isAtLeast(accounts.length, 2, "There are not at least two accounts to work with");
		assert.isNotNull(oneToken.address, "There is no token for strategy");
	});
	
	
	it("should be constructed with one token", async () => {
		const factory = await Factory.deployed();
		let contract = arbitraryStrategy = await ArbitraryStrategy.new(factory.address, oneTokenAddress, "Test StrategyCommon")
		assert.isNotNull(arbitraryStrategy.address, "There is no token for strategy");

		expectEvent.inConstruction(contract, 'StrategyDeployed', {
			sender: governance
		})
	});
	
	it("should have 0 allowance before init", async () => {
		const allowance = await oneToken.allowance(oneTokenAddress, arbitraryStrategy.address)
		assert.equal(allowance.toNumber(), 0, "should have 0 allowance before init");
	});
	
	it("should be able to init", async () => {
		await factory.admitModule(arbitraryStrategy.address, moduleType.strategy, "arbitraryStrategy", "#")
		
		collateralToken = await CollateralToken.new();
		const oraclePegged = await OraclePegged.new(factory.address, "oracleName", collateralToken.address);
		await factory.admitModule(oraclePegged.address, moduleType.oracle, "oraclePegged", "#")
		await factory.admitForeignToken(collateralToken.address, true, oraclePegged.address)
		await oneToken.addAsset(collateralToken.address, oraclePegged.address)
		
		// we need to init via oneToken to make it right
		let allowance1 = 1000;
		let tx = await oneToken.setStrategy(collateralToken.address, arbitraryStrategy.address, allowance1);
		expectEvent(tx, 'StrategySet', {
			sender: governance,
			token: collateralToken.address,
			strategy: arbitraryStrategy.address,
			allowance: allowance1.toString()
		})

		// test event from StrategyCommon
        expectEvent.inTransaction(tx.tx, StrategyCommon, 'StrategyInitialized', {
			sender: oneToken.address
		})
	});
	
	it("setAllowance to non-zero", async () => {
		const randomToken = await OneToken.new();
		let amount = 5;
		let tx = await arbitraryStrategy.setAllowance(randomToken.address, amount);
		const allowance = await randomToken.allowance(arbitraryStrategy.address, oneTokenAddress)
		assert.equal(allowance.toNumber(), amount, "should have amount allowance");

		expectEvent(tx, 'VaultAllowance', {
			sender: governance,
			token: randomToken.address,
			amount: amount.toString()
		})
	});
		
});
