const lib = require("./lib");
const utils = require("./utils");
const Web3 = require('web3')
const net = require('net')
const ethutil = require("ethereumjs-util");
const pu = require('promisefy-util')


const StoremanGroupDelegate = artifacts.require('StoremanGroupDelegate')
const StoremanGroupProxy = artifacts.require('StoremanGroupProxy');

const wanUtil = require('wanchain-util');
const Tx = wanUtil.wanchainTx;



const { registerStart,stakeInPre, web3url,g, toSelect, } = require('./basee.js')

/*************************************
staker: 1000 ~ 1000+100
delegator: stakerId*100 ~ stakerID*100+1000
 ****************************************/




contract('TestSmg', async (accounts) => {

    let  smg
    let groupId
    let id
    let web3 = new Web3(new Web3.providers.HttpProvider(web3url))
    let wk1 = utils.getAddressFromInt(10000)

    let tester = g.sfs[8];

    before("init contracts", async() => {
        let smgProxy = await StoremanGroupProxy.deployed();
        smg = await StoremanGroupDelegate.at(smgProxy.address)

    })


    it('registerStart_1 ', async ()=>{
        groupId = await registerStart(smg);
        id = groupId
    })

    it('stakeInPre ', async ()=>{
        await stakeInPre(smg, groupId)
    })

    it('stakeIn', async ()=>{
        let stakingValue = 50000
        let tx = await smg.stakeIn(groupId, wk1.pk, wk1.pk,{value:stakingValue, from:tester});

        let candidate  = await smg.getStoremanInfo(wk1.addr)
        console.log("candidate:", candidate)
        assert.equal(candidate.sender.toLowerCase(), tester.toLowerCase())
        assert.equal(candidate.pkAddress.toLowerCase(), wk1.addr.toLowerCase())
        assert.equal(candidate.deposit, stakingValue)
    })
    it('test stakeIn2', async()=>{
        let stakingValue = 1000;
        let wk = utils.getAddressFromInt(10001)
        let tx =  await smg.stakeIn(id, wk.pk, wk.pk, {value:stakingValue, from:tester})
        
        console.log("txhash stakeIn:", tx.tx)
        let candidate  = await smg.getStoremanInfo(wk.addr)
        console.log("candidate:", candidate)
        assert.equal(candidate.sender.toLowerCase(), tester.toLowerCase())
        assert.equal(candidate.pkAddress.toLowerCase(), wk.addr.toLowerCase())
        assert.equal(candidate.deposit, stakingValue)
    })
    it('test stakeAppend', async()=>{
        let candidateOld  = await smg.getStoremanInfo(wk1.addr)

        const appendValue = 3000
        let tx = await smg.stakeAppend(wk1.addr,{from:tester, value:appendValue})

        let candidate  = await smg.getStoremanInfo(wk1.addr)
        console.log("candidate:", candidate)
        assert.equal(candidate.sender.toLowerCase(), tester.toLowerCase())
        assert.equal(candidate.pkAddress.toLowerCase(), wk1.addr)
        assert.equal(candidate.deposit, Number(candidateOld.deposit)+Number(appendValue))
    })

    it.skip('test delegateIn', async()=>{
        let ski = g.stakerCount-1;
        let depositValue = 3000;
        let deCount = 1;
        for(let j=0; j<deCount; j++){
            let de = utils.getAddressFromInt((ski+1000)*10*1000 + j)
            let sw = utils.getAddressFromInt(ski+2000)
            console.log("sw.addr:===============:", sw.addr)
            let payCount=1;
            await smg.delegateIn(sw.addr, {from:de.addr});
            let candidate  = await smg.getStoremanInfo(sw.addr)
            console.log("after delegateIn,  candidate:",candidate)
            assert.equal(candidate.delegatorCount, deCount)

            let nde = await smg.getSmDelegatorInfo(sw.addr, de.addr);
            assert.equal(nde.incentive, 0)
            assert.equal(nde.deposit, depositValue*payCount)
            console.log("nde: ", nde)

            let de2 = await smg.getSmDelegatorAddr(sw.addr, 0);
            console.log("de2:", de2);
        }
    })

    it.skip('[StoremanGroupDelegate_stakeOut] should fail: selecting', async () => {
        let i=g.stakerCount-1;
        let sf = utils.getAddressFromInt(i+1000)
        let sw = utils.getAddressFromInt(i+2000)
        let result = {};
        try {
            let txhash = await smg.stakeOut(sw.addr, {from: tester})
            console.log("stakeOut txhash:", txhash);
        } catch (e) {
            result = e;
            console.log("result:", result);
        }
        assert.equal(result.reason, 'selecting time, can\'t quit');
    })
  
    it.skip('test toSelect', async ()=>{
        await pu.sleep(10000)
        let tx = await smg.toSelect(id)
        console.log("toSelect tx:", tx.tx)
        await utils.waitReceipt(tx.tx)
        console.log("group:",await smg.getStoremanGroupInfo(id))

        
        let count = await smg.getSelectedSmNumber(id)
        console.log("selected count :", count)
        assert.equal(count, memberCountDesign)
    })
    it.skip('[StoremanGroupDelegate_stakeOut] should success', async () => {
        let i=g.stakerCount-1;
        let sf = utils.getAddressFromInt(i+1000)
        let sw = utils.getAddressFromInt(i+2000)
        let result = {};
        try {
            let txhash = await smg.stakeOut(sw.addr, {from: tester})
            console.log("stakeOut txhash:", txhash);
        } catch (e) {
            result = e;
            console.log("result:", result);
        }
        assert.equal(result.reason, undefined);
        let candidate  = await smg.getStoremanInfo(sw.addr)
        console.log("candidate:", candidate)
        assert.equal(candidate.sender.toLowerCase(), sf.addr)
        assert.equal(candidate.pkAddress.toLowerCase(), sw.addr)
        assert.equal(candidate.quited, true)
    })
    it.skip('[StoremanGroupDelegate_stakeClaim] should fail: not dismissed', async () => {
        let result = {};
        try {
            let txhash = await smg.stakeClaim(wAddr, {from: tester})
            console.log("stakeOut txhash:", txhash);
        } catch (e) {
            result = e;
            console.log("result:", result);
        }
        assert.equal(result.reason, 'group can\'t claim');
    })
    it.skip('[StoremanGroupDelegate_stakeClaim] should success:', async () => {
        console.log("xxxx end")
        let result = {};
        try {
            let txhash = await smg.stakeClaim(wAddr2, {from: tester})
            console.log("stakeOut txhash:", txhash);
        } catch (e) {
            result = e;
            console.log("result:", result);
        }
        assert.equal(result.reason, undefined);
    })

})
