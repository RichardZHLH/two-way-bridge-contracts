const TokenManagerProxy         = artifacts.require('TokenManagerProxy');
const TokenManagerDelegate      = artifacts.require('TokenManagerDelegate');

const QuotaDelegate             = artifacts.require('QuotaDelegate.sol');
const QuotaProxy                = artifacts.require('QuotaProxy.sol');

const OracleDelegate            = artifacts.require('OracleDelegate.sol');
const OracleProxy               = artifacts.require('OracleProxy.sol');

const Bn128SchnorrVerifier      = artifacts.require('Bn128SchnorrVerifier.sol');
const Secp256k1SchnorrVerifier  = artifacts.require('Secp256k1SchnorrVerifier.sol');
const SignatureVerifier         = artifacts.require('SignatureVerifier.sol');

const HTLCTxLib                 = artifacts.require('HTLCTxLib');
const HTLCDebtLib               = artifacts.require('HTLCDebtLib');
const RapidityLib               = artifacts.require('RapidityLib');
const HTLCDebtLibV2             = artifacts.require('HTLCDebtLibV2');
const RapidityLibV2             = artifacts.require('RapidityLibV2');
const CrossDelegate             = artifacts.require('CrossDelegate.sol');
const CrossDelegateV2           = artifacts.require('CrossDelegateV2.sol');
const CrossProxy                = artifacts.require('CrossProxy.sol');

const TestStoremanAdmin         = artifacts.require('TestStoremanAdmin.sol');
const TestOrigTokenCreator      = artifacts.require("TestOrigTokenCreator.sol")

const optimist                  = require("optimist");
const schnorrTool               = require('../utils/schnorr/tools');

const {
    ADDRESS_0,
    htlcLockedTime,
    quotaDepositRate,
    chainTypes,
    defaultChainIDs,
    defaultCurve,
    defaultCurve2Schnorr,
    crossFees,
    crossFeesV2,
    userBTCAccount
} = require("./crossApproach/common");

const {
    storemanGroups,
    initStoremanGroup,
    addWanStoremanGroup,
    syncWanStoremanGroup,
} = require("./crossApproach/smg-config");

const {
    coins,
    tokens,
    startTokenPairID,
    deployOrigToken,
    transferOrigToken,
    addMappingToken,
    cleanTokenPairs,
    mergeTokenPairs,
    initOrigTokenPairs,
    addTokenPairs
} = require("./crossApproach/token-config");

const {
    updateOracle
} = require("./crossApproach/oracle-config");

const truffleConfig = require("../truffle-config");

const {
    testInit,
    getEventSignature,
    assert
}                               = require('./crossApproach/lib');

const {
    getBalance,
    toNonExponential,
    importMochaTest,
    setGlobal,
    clearGlobal
}                               = require('./utils');

contract('Test Cross Approach', (accounts) => {
    before("init...   -> success", async () => {
        testInit();

        let currNetwork = optimist.argv.network || "development";
        currNetwork = currNetwork.split("-")[0];
        const from = truffleConfig.networks[currNetwork].from;
        const owner = from ? (accounts.includes(from) ? from : accounts[0]) : accounts[0];
        const adminAccounts = {WAN: accounts[1], ETH: accounts[2]};
        const foundationAccounts = {WAN: accounts[3], ETH: accounts[4]};
        const aliceAccounts = {WAN: accounts[5], ETH: accounts[6], BTC: userBTCAccount};
        const smgAccounts = { src: {WAN: accounts[7], ETH: accounts[8]}, dest: {WAN: accounts[7], ETH: accounts[8]} }
        // const curveIDs = {WAN: defaultCurve.secp256K1, ETH: defaultCurve.bn128};
        const curveIDs = {WAN: defaultCurve.bn128, ETH: defaultCurve.bn128};

        console.log(`Deploy contracts, wait...`);
        let tokenPairs = {};
        let knownEvents = {};
        let deployed = {};
        deployed[chainTypes.WAN] = await deployCrossContracts(owner, {chainType: chainTypes.WAN, tokenPairs, curveIDs, alice:aliceAccounts.WAN, foundation: foundationAccounts.WAN, admin: adminAccounts.WAN});
        console.log("contracts:", chainTypes.WAN, JSON.stringify(deployed[chainTypes.WAN].scAddr));
        tokenPairs = deployed[chainTypes.WAN].tokenPairs;
        knownEvents[chainTypes.WAN] = deployed[chainTypes.WAN].knownEvents;
        deployed[chainTypes.ETH] = await deployCrossContracts(owner, {chainType: chainTypes.ETH, tokenPairs, curveIDs, alice:aliceAccounts.ETH, foundation: foundationAccounts.ETH, admin: adminAccounts.ETH});
        console.log("contracts:", chainTypes.ETH, JSON.stringify(deployed[chainTypes.ETH].scAddr));
        tokenPairs = deployed[chainTypes.ETH].tokenPairs;
        knownEvents[chainTypes.ETH] = deployed[chainTypes.ETH].knownEvents;
        await addChainTokenPairs(deployed[chainTypes.WAN].scAddr.TokenManagerProxy, tokenPairs);
        await addChainTokenPairs(deployed[chainTypes.ETH].scAddr.TokenManagerProxy, tokenPairs);

        let chainType;
        let chains = {};
        chainType = chainTypes.WAN;
        chains[chainType] = makeChainInfo(chainType, deployed[chainType].scAddr, coins[chainType], tokens[chainType])
        chainType = chainTypes.ETH;
        chains[chainType] = makeChainInfo(chainType, deployed[chainType].scAddr, coins[chainType], tokens[chainType])
        chainType = chainTypes.BTC;
        chains[chainType] = makeChainInfo(chainType, null, coins[chainType], null)

        // console.log("===chains:", JSON.stringify(chains, null, 2));
        // console.log("===tokenPairs:", JSON.stringify(tokenPairs, null, 2));
        // console.log("===chains:", JSON.stringify(chains, null, 2));
        // console.log("===coins:", JSON.stringify(coins, null, 2));
        // console.log("===tokens:", JSON.stringify(tokens, null, 2));

        // setGlobal("accounts", accounts);
        setGlobal("adminAccount", adminAccounts);
        setGlobal("foundationAccount", foundationAccounts);
        setGlobal("aliceAccount", aliceAccounts);
        setGlobal("smgAccount", smgAccounts);
        setGlobal("crossFees", crossFees);
        setGlobal("crossFeesV2", crossFeesV2);
        setGlobal("knownEvents", knownEvents);
        setGlobal("tokenPairs", tokenPairs);
        setGlobal("chains", chains);
        setGlobal("schnorr", schnorrTool);
        setGlobal("storemanGroups", storemanGroups);
        // set owner
        setGlobal("contractOwner", owner);
        setGlobal("getSmgProxy", getSmgProxy);

    });

    importMochaTest("Test Common V2", './crossApproach/common_v2_test');

    importMochaTest("Test Cross V2", './crossApproach/cross_v2_test');

    importMochaTest("Test Debt V2", './crossApproach/debt_v2_test');

    after("finish...   -> success", function () {
        clearGlobal("adminAccount");
        clearGlobal("foundationAccount");
        clearGlobal("aliceAccount");
        clearGlobal("smgAccount");
        clearGlobal("crossFees");
        clearGlobal("crossFeesV2");
        clearGlobal("knownEvents");
        clearGlobal("tokenPairs");
        clearGlobal("chains");
        clearGlobal("schnorr");
        clearGlobal("storemanGroups");
        // clear owner
        clearGlobal("contractOwner");
        clearGlobal("getSmgProxy");
        console.log("After all tests");
    });
});

function makeChainInfo(chainType, scAddr, coin, token) {
    let chain = {};
    chain.ID = defaultChainIDs[chainType];
    chain.scAddr = scAddr;
    chain.coin = coin;
    chain.tokens = token;
    return chain;
}

async function getSmgProxy(chainType, address) {
    let smg;
    if (chainTypes.WAN === chainType) {
      smg = await TestStoremanAdmin.at(address);
    } else {
      smg = await OracleDelegate.at(address);
    }
    return smg;
}

async function addChainTokenPairs(tokenManagerAddr, tokenPairs) {
    let tokenManager = await TokenManagerDelegate.at(tokenManagerAddr);
    return await addTokenPairs(tokenManager, tokenPairs);
}

async function deployCrossContracts(owner, options) {
    let opts = Object.assign({}, {
        chainType: chainTypes.WAN,
        depositSymbol: coins.WAN.symbol,
        tokenPairs: {},
        curveIDs:{ WAN:defaultCurve.secp256K1, ETH:defaultCurve.bn128 },
        alice: null,
        admin: null,
        foundation: null
    }, options);
    let isWAN = opts.chainType === chainTypes.WAN;
    let scAddr = {};
    let knownEvents = {};

    // quota
    let quotaProxy = await QuotaProxy.new({from: owner});
    let quotaDelegate = await QuotaDelegate.new({from: owner});
    await quotaProxy.upgradeTo(quotaDelegate.address, {from: owner});
    let quota = await QuotaDelegate.at(quotaProxy.address);
    scAddr["QuotaProxy"] = quota.address;
    scAddr["QuotaDelegate"] = quotaDelegate.address;
    knownEvents["QuotaDelegate"] = getEventSignature(quotaDelegate.abi);

    // oracle
    let oracleProxy = await OracleProxy.new({from: owner});
    let oracleDelegate = await OracleDelegate.new({from: owner});
    await oracleProxy.upgradeTo(oracleDelegate.address, {from: owner});
    let oracle = await OracleDelegate.at(oracleProxy.address);
    scAddr["OracleProxy"] = oracle.address;
    scAddr["OracleDelegate"] = oracleDelegate.address;
    knownEvents["OracleDelegate"] = getEventSignature(oracleDelegate.abi);

    // token manager proxy
    let tokenManagerProxy = await TokenManagerProxy.new({from: owner});
    let tokenManagerDelegate = await TokenManagerDelegate.new({from: owner});
    await tokenManagerProxy.upgradeTo(tokenManagerDelegate.address, {from: owner});
    let tokenManager = await TokenManagerDelegate.at(tokenManagerProxy.address);
    scAddr["TokenManagerProxy"] = tokenManager.address;
    scAddr["TokenManagerDelegate"] = tokenManagerDelegate.address;
    knownEvents["TokenManagerDelegate"] = getEventSignature(tokenManagerDelegate.abi);

    let smgAdminProxy;
    let schnorrs = Object.keys(opts.curveIDs).map(chainType => schnorrTool[defaultCurve2Schnorr[opts.curveIDs[chainType]]]);
    let wanCurveIDs = Object.values(opts.curveIDs);

    initStoremanGroup(storemanGroups, schnorrs);
    if (isWAN) {
        smgAdminProxy = await TestStoremanAdmin.new({from: owner});
        scAddr["TestStoremanAdmin"] = smgAdminProxy.address;
        knownEvents["TestStoremanAdmin"] = getEventSignature(smgAdminProxy.abi);

        await addWanStoremanGroup(smgAdminProxy, storemanGroups, wanCurveIDs, owner);
    } else {
        let ethCurveIDs = wanCurveIDs.reverse();
        await syncWanStoremanGroup(oracle, storemanGroups, ethCurveIDs, owner);
    }
    await updateOracle(oracle, storemanGroups, owner)

    // signature verifier
    let signatureVerifier = await SignatureVerifier.new({from: owner});
    let bn128 = await Bn128SchnorrVerifier.new({from: owner});
    if (isWAN) {
        let secp256K1 = await Secp256k1SchnorrVerifier.new({from: owner});
        await signatureVerifier.register(defaultCurve.secp256K1, secp256K1.address, {from: owner});
        scAddr["Secp256k1SchnorrVerifier"] = secp256K1.address;
    }
    // register signature verifier contracts
    await signatureVerifier.register(defaultCurve.bn128, bn128.address, {from: owner});
    scAddr["SignatureVerifier"] = signatureVerifier.address;
    scAddr["Bn128SchnorrVerifier"] = bn128.address;

    // cross approach
    let htlcTxLib = await HTLCTxLib.new({from: owner});
    await HTLCDebtLib.link("HTLCTxLib", htlcTxLib.address);
    let htlcDebtLib = await HTLCDebtLib.new({from: owner});
    let rapidityLib = await RapidityLib.new({from: owner});
    await CrossDelegate.link("HTLCTxLib", htlcTxLib.address);
    await CrossDelegate.link("HTLCDebtLib", htlcDebtLib.address);
    await CrossDelegate.link("RapidityLib", rapidityLib.address);
    let crossDelegate = await CrossDelegate.new({from: owner});

    let htlcTxLibV2 = await HTLCTxLib.new({from: owner});
    await HTLCDebtLib.link("HTLCTxLib", htlcTxLibV2.address);
    let htlcDebtLibV2 = await HTLCDebtLibV2.new({from: owner});
    let rapidityLibV2 = await RapidityLibV2.new({from: owner});
    await CrossDelegateV2.link("HTLCTxLib", htlcTxLibV2.address);
    await CrossDelegateV2.link("HTLCDebtLibV2", htlcDebtLibV2.address);
    await CrossDelegateV2.link("RapidityLibV2", rapidityLibV2.address);
    let crossDelegateV2 = await CrossDelegateV2.new({from: owner});

    let crossProxy = await CrossProxy.new({from: owner});
    await crossProxy.upgradeTo(crossDelegate.address, {from: owner});
    let cross = await CrossDelegate.at(crossProxy.address);
    await cross.setLockedTime(htlcLockedTime) //second
    scAddr["CrossProxy"] = crossProxy.address;
    scAddr["CrossDelegate"] = crossDelegate.address;
    scAddr["CrossDelegateV2"] = crossDelegateV2.address;
    knownEvents["RapidityLib"] = getEventSignature(rapidityLib.abi);
    knownEvents["HTLCDebtLib"] = getEventSignature(htlcDebtLib.abi);
    knownEvents["CrossDelegate"] = getEventSignature(crossDelegate.abi);
    knownEvents["RapidityLibV2"] = getEventSignature(rapidityLibV2.abi);
    knownEvents["HTLCDebtLibV2"] = getEventSignature(htlcDebtLibV2.abi);
    knownEvents["CrossDelegateV2"] = getEventSignature(crossDelegateV2.abi);

    for (let theChainType in crossFees[opts.chainType]) {
        for (let buddyChainType in crossFees[opts.chainType][theChainType]) {
            if (theChainType === opts.chainType || buddyChainType === opts.chainType) {
                await cross.setFees(defaultChainIDs[theChainType], defaultChainIDs[buddyChainType],
                    crossFees[opts.chainType][theChainType][buddyChainType].lockFee,
                    crossFees[opts.chainType][theChainType][buddyChainType].revokeFee
                );
            }
        }
    }

    if (!(await tokenManager.mapAdmin(cross.address))) {
        await tokenManager.addAdmin(cross.address);
    }

    // TestOrigTokenCreator
    let testOrigTokenCreator = await TestOrigTokenCreator.new();
    scAddr["TestOrigTokenCreator"] = testOrigTokenCreator.address;
    knownEvents["TestOrigTokenCreator"] = getEventSignature(testOrigTokenCreator.abi);
    // testOrigTokenCreator.setAdmin(crossApproach.address);
    await testOrigTokenCreator.setAdmin(owner);

    // token pairs
    let origTokens = tokens;
    origTokens[opts.chainType] = await deployOrigToken(testOrigTokenCreator, origTokens[opts.chainType]);
    await transferOrigToken(testOrigTokenCreator, origTokens[opts.chainType], opts.alice);

    let currTokenPairs = initOrigTokenPairs(coins, origTokens, chainTypes, defaultChainIDs, startTokenPairID);
    currTokenPairs = await addMappingToken(tokenManager, currTokenPairs, opts.chainType);

    currTokenPairs = cleanTokenPairs(currTokenPairs);
    currTokenPairs = mergeTokenPairs(currTokenPairs, opts.tokenPairs);

    await cross.setPartners(
        tokenManager.address,
        isWAN ? smgAdminProxy.address : oracle.address,
        isWAN ? smgAdminProxy.address : ADDRESS_0,
        quota.address,
        signatureVerifier.address,
        {from: owner}
    );
    await quota.config(
        oracle.address,
        crossProxy.address,
        crossProxy.address,
        isWAN ? smgAdminProxy.address : oracle.address,
        tokenManager.address,
        quotaDepositRate,
        opts.depositSymbol,
        {from: owner}
    );

    await crossProxy.upgradeTo(crossDelegateV2.address, {from: owner});
    let crossV2 = await CrossDelegateV2.at(crossProxy.address);
    await crossV2.setAdmin(opts.admin, {from: owner});
    let partners = await cross.getPartners();
    let partnersV2 = await crossV2.getPartners();
    // console.log("v1 lockedTime:", (await cross.lockedTime()))
    // console.log("proxy lockedTime:", (await crossProxy.lockedTime()))
    assert.equal((await cross.lockedTime()).eq(await crossProxy.lockedTime()), true, `v1 lockedTime is not the proxy lockedTime`);
    assert.equal(partners.tokenManager, partnersV2.tokenManager, `v1's tokenManager is not v2's tokenManager`);
    assert.equal(partners.smgAdminProxy, partnersV2.smgAdminProxy, `v1's smgAdminProxy is not v2's smgAdminProxy`);
    assert.equal(partners.smgFeeProxy, partnersV2.smgFeeProxy, `v1's smgFeeProxy is not v2's smgFeeProxy`);
    assert.equal(partners.quota, partnersV2.quota, `v1's quota is not v2's quota`);
    assert.equal(partners.sigVerifier, partnersV2.sigVerifier, `v1's sigVerifier is not v2's sigVerifier`);

    await crossV2.setPartners(partners.tokenManager, partners.smgAdminProxy, opts.foundation, partners.quota, partners.sigVerifier, {from: owner});
    assert.equal((await crossV2.getPartners()).smgFeeProxy, opts.foundation, `v2's smgFeeProxy is not the foundation account`);

    await crossV2.setChainID(defaultChainIDs[opts.chainType], {from: opts.admin});
    assert.equal((await crossV2.currentChainID()), defaultChainIDs[opts.chainType], `invalid currentChainID`);
    let multi = false;
    for (let buddyChainType in crossFeesV2[opts.chainType]) {
        if (!multi) {
            await crossV2.setFee({srcChainID: defaultChainIDs[opts.chainType], destChainID:defaultChainIDs[buddyChainType], contractFee: crossFeesV2[opts.chainType][buddyChainType].contractFee, agentFee: crossFeesV2[opts.chainType][buddyChainType].agentFee}, {from: opts.admin});
            let fee = await crossV2.getFee({srcChainID: defaultChainIDs[opts.chainType], destChainID:defaultChainIDs[buddyChainType]});
            assert.equal(fee.contractFee, crossFeesV2[opts.chainType][buddyChainType].contractFee, `invalid v2's ${opts.chainType} => ${buddyChainType} contractFee`);
            assert.equal(fee.agentFee, crossFeesV2[opts.chainType][buddyChainType].agentFee, `invalid v2's ${opts.chainType} => ${buddyChainType} agentFee`);
            multi = true;
            continue;
        }
        await crossV2.setFees([{srcChainID: defaultChainIDs[opts.chainType], destChainID:defaultChainIDs[buddyChainType], contractFee: crossFeesV2[opts.chainType][buddyChainType].contractFee, agentFee: crossFeesV2[opts.chainType][buddyChainType].agentFee}], {from: opts.admin});
        let fees = await crossV2.getFees([{srcChainID: defaultChainIDs[opts.chainType], destChainID:defaultChainIDs[buddyChainType]}]);
        assert.equal(fees[0].contractFee, crossFeesV2[opts.chainType][buddyChainType].contractFee, `invalid v2's ${opts.chainType} => ${buddyChainType} contractFee`);
        assert.equal(fees[0].agentFee, crossFeesV2[opts.chainType][buddyChainType].agentFee, `invalid v2's ${opts.chainType} => ${buddyChainType} agentFee`);
    }

    return {
        scAddr: scAddr,
        knownEvents: knownEvents,
        tokenPairs: currTokenPairs
    };
}
