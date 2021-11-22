const { assert } = require("chai");
const truffleAssert = require('truffle-assertions');

const 
    OneToken = artifacts.require("OneTokenV1"),
    Factory = artifacts.require("OneTokenFactory"),
    ControllerNull = artifacts.require("NullController"),
    MintMasterIncremental = artifacts.require("Incremental"),
    OraclePegged = artifacts.require("ICHIPeggedOracle"),
    MemberToken = artifacts.require("MemberToken"),
    CollateralToken = artifacts.require("CollateralToken");
    RoleGuard = artifacts.require("RoleGuardOneTokenV1");
    

const 
    NULL_ADDRESS = "0x0000000000000000000000000000000000000000",
    NEW_RATIO = "500000000000000000", // 50%
    FEE =         "2000000000000000"; // 0.2%
    MAX_FEE =  "1000000000000000000"; // 100%

const moduleType = {
    version: 0, 
    controller: 1, 
    strategy: 2, 
    mintMaster: 3, 
    oracle: 4, 
    voterRoll: 5
}

let governance,
    badAddress,
    version,
    factory,
    oneToken,
    controller,
    mintMaster,
    oracle,
    memberToken,
    collateralToken,
    roleGuardOneTokenV1;

contract("Role Guard OneToken V1", accounts => {

    beforeEach(async () => {
        let oneTokenAddress;
        deployer = accounts[0];
        badAddress = accounts[1];
        governance = accounts[2];
        badAddress = accounts[3];
        version = await OneToken.deployed();
        factory = await Factory.deployed();
        controller = await ControllerNull.deployed();
        mintMaster = await MintMasterIncremental.deployed();
        oracle = await OraclePegged.deployed();
        memberToken = await MemberToken.deployed();
        collateralToken = await CollateralToken.deployed();
        oneTokenAddress = await factory.oneTokenAtIndex(0);
        oneToken = await OneToken.at(oneTokenAddress);
        roleGuardOneTokenV1 = await RoleGuard.deployed();
    });

    it("should be ready to test", async () => {
        assert.isAtLeast(accounts.length, 2, "There are not at least two accounts to work with");
    });
    
    it("constructor should work", async () => {
        
    });

    it("Access hashes should match up", async () => {

    });

    it("All access control should be correct", async () => {
        
    });
    

});
