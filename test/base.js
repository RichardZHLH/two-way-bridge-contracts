const utils = require("./utils");
const assert = require('chai').assert;
const Web3 = require('web3')
const optimist = require("optimist")

let web3url,leaderPk,sfs,leader,owner,web3;

const args = optimist.argv;
const WhiteCount = 4
const whiteBackup = 3
const memberCountDesign = 4
const threshold  = 3
const stakerCount = memberCountDesign+whiteBackup
const registerDuration = 5; // open staking for 10 days.
const gpkDuration = 3;
const htlcDuration = 9; // work 90 day.
const timeBase = 1;
const wanChainId = 2153201998;
const ethChainId = 2147483708;
const curve1 = 1, curve2 = 1;
const minStakeIn = 50000;
const minDelegateIn = 100;
const delegateFee = 1200;

const storemanGroupStatus  = {
    none                      : 0,
    initial                   : 1,
    curveSeted                : 2,
    failed                    : 3,
    selected                  : 4,
    ready                     : 5,
    unregistered              : 6,
    dismissed                 : 7
};

const g = {
    leader,owner,WhiteCount,whiteBackup,memberCountDesign,threshold,leaderPk,web3url,stakerCount,
    gpkDuration,registerDuration,htlcDuration,timeBase,wanChainId,ethChainId,curve1,curve2,storemanGroupStatus,
    minStakeIn,minDelegateIn,delegateFee
}

async function setupNetwork() {
    if (args.network == 'local' || args.network == 'coverage') {
        console.log("using network local");
        g.web3url = "http://127.0.0.1:8545";
        g.owner = "0xEf73Eaa714dC9a58B0990c40a01F4C0573599959";
        g.leader = ("0xdC49B58d1Dc15Ff96719d743552A3d0850dD7057").toLowerCase();

        web3 = new Web3(new Web3.providers.HttpProvider(g.web3url));
        let accounts = await web3.eth.getAccounts();
        g.leaderPk = "0xb6ee04e3c64e31578dd746d1024429179d83122fb926be19bd33aaeea55afeb6b10c6ff525eec7ca9a4e9a252a4c74b222c1273d4719d96e0f2c5199c42bc84b";
        sfs = accounts.slice(2);
        g.timeBase = 1;
        g.sfs = sfs;
    } else {
        g.web3url = "http://192.168.1.58:7654";
        g.owner = "0x2d0e7c0813a51d3bd1d08246af2a8a7a57d8922e";
        g.leader = "0x5793e629c061e7fd642ab6a1b4d552cec0e2d606";
        g.leaderPk = "0x25fa6a4190ddc87d9f9dd986726cafb901e15c21aafd2ed729efed1200c73de89f1657726631d29733f4565a97dc00200b772b4bc2f123a01e582e7e56b80cf8";
        sfs = [
            "0xe89476b7cc8fa1e503f2ae4a43e53eda4bfbac07",
            "0x8c36830398659c303e4aedb691af8c526290452a",
            "0x431039e7b144d6e46c8e98497e87a5da441c7abe",
            "0x82ef7751a5460bc10f731558f0741705ba972f4e",
            "0xffb044cd928c1b7ef6cc15932d06a9ce3351c2dc",
            "0x23dcbe0323605a7a00ce554babcff197baf99b10",
            "0xf45aedd5299d16440f67efe3fb1e1d1dcf358222",
        ];
        g.timeBase = 4;
        g.sfs = sfs;
        web3 = new Web3(new Web3.providers.HttpProvider(g.web3url));
    }
}

async function registerStart(smg, wlStartIndex = 0, option = {}){
    //await smg.updateStoremanConf(3,15000,10)
    let now = parseInt(Date.now()/1000);
    let wks = [g.leader]
    let srs= [g.leader]
    for(let i=1; i<WhiteCount;i++){
        let {addr:wk} = utils.getAddressFromInt(i+wlStartIndex+2000)
        wks.push(wk)
        srs.push(sfs[i])
    }
    let groupId = option.groupId ? option.groupId : utils.stringTobytes32(now.toString());
    let registerDuration = option.registerDuration ? option.registerDuration : g.registerDuration;
    let gpkDuration =  option.gpkDuration ? option.gpkDuration : g.gpkDuration;
    let htlcDuration =  option.htlcDuration ? option.htlcDuration : g.htlcDuration;
    let memberCountDesign = option.memberCountDesign ? option.memberCountDesign : g.memberCountDesign;
    let threshold = option.threshold ? option.threshold : g.threshold;
    let preGroupId =  option.preGroupId ? option.preGroupId : utils.stringTobytes32("");

    let smgIn = {
        groupId: groupId,
        preGroupId: preGroupId,
        workTime:now+(registerDuration+gpkDuration)*g.timeBase,
        totalTime:htlcDuration*g.timeBase,
        registerDuration: registerDuration*g.timeBase,
        memberCountDesign:memberCountDesign,
        threshold:threshold,
        chain1:ethChainId,
        chain2:wanChainId,
        curve1:curve1,
        curve2:curve2,
        minStakeIn:minStakeIn,
        minDelegateIn:minDelegateIn,
        delegateFee:delegateFee,
    }

    let tx = await smg.storemanGroupRegisterStart(smgIn, wks,srs, {from: g.owner})
    console.log("registerStart txhash:", tx.tx)
    let group = await smg.getStoremanGroupInfo(groupId)
    assert.equal(group.status, storemanGroupStatus.curveSeted)
    assert.equal(group.groupId, groupId)
    if(!preGroupId) {
        assert.equal(group.deposit, 0)
        assert.equal(group.memberCount, 1)
    }

    console.log("group:", group)
    return group.groupId
}


async function stakeInPre(smg, groupId, nodeStartIndex = 0, nodeCount = stakerCount){
    console.log("smg.contract:", smg.contract._address)
    let stakingValue = g.minStakeIn;
    for(let i=0; i<nodeCount; i++){
        let sw, tx
        if(i==0){
            sw = utils.getAddressFromInt(i+nodeStartIndex+2000)
            tx = await smg.stakeIn(groupId, g.leaderPk, g.leaderPk,{from:g.leader, value:stakingValue})  //TODO enodeID
            console.log("preE:", i, tx.tx);
            let candidate  = await smg.getStoremanInfo(g.leader)
            console.log("candidate:", candidate)
            assert.equal(candidate.sender.toLowerCase(), g.leader.toLowerCase())
            assert.equal(candidate.wkAddr.toLowerCase(), g.leader.toLowerCase())
            assert.equal(candidate.deposit, stakingValue)

        }else{
            sw = utils.getAddressFromInt(i+2000)
            console.log("send============================:", sfs[i])
            tx = await smg.stakeIn(groupId, sw.pk, sw.pk,{from:sfs[i], value:stakingValue})     
            
            console.log("preE:", i, tx.tx);
            let candidate  = await smg.getStoremanInfo(sw.addr)
            //console.log("candidate:", candidate)
            assert.equal(candidate.sender.toLowerCase(), sfs[i].toLowerCase())
            assert.equal(candidate.wkAddr.toLowerCase(), sw.addr.toLowerCase())
            assert.equal(candidate.deposit, stakingValue)
        }


    }
}

async function stakeInOne(smg, groupId, nodeIndex, value){
    console.log("smg.contract:", smg.contract._address)
    let sf = utils.getAddressFromInt(nodeIndex+1000)
    let sw = utils.getAddressFromInt(nodeIndex+2000)
    let en = utils.getAddressFromInt(nodeIndex+3000)
    let sdata =  smg.contract.methods.stakeIn(groupId, sw.pk,en.pk).encodeABI()
    //console.log("sdata:",sdata)
    let rawTx = {
        Txtype: 0x01,
        nonce:  await pu.promisefy(web3.eth.getTransactionCount,[sf.addr,"pending"], web3.eth),
        gasPrice: gGasPrice,
        gas: gGasLimit,
        to: smg.contract._address,
        chainId: 6,
        value: value,
        data: sdata,
    }
    //console.log("rawTx:", rawTx)
    let tx = new Tx(rawTx)
    tx.sign(sf.priv)
    const serializedTx = '0x'+tx.serialize().toString('hex');
    //console.log("serializedTx:",serializedTx)
    console.log("sm %d %s stakein %d", nodeIndex, sw.addr, value)
    await web3.eth.sendSignedTransaction(serializedTx)
    let candidate  = await smg.getStoremanInfo(sw.addr)
    //console.log("candidate:", candidate)
    assert.equal(candidate.sender.toLowerCase(), sf.addr)
    assert.equal(candidate.wkAddr.toLowerCase(), sw.addr)
    assert.equal(candidate.deposit, value)
    return sw.addr
}
async function toSelect(smg, groupId){
    let tx = await smg.select(groupId,{from: g.leader})
    console.log("group %s select tx:", groupId, tx.tx)
    let count = await smg.getSelectedSmNumber(groupId)
    console.log("slected sm number: %d", count);  
    for (let i = 0; i<count; i++) {
        let ski = await smg.getSelectedSmInfo(groupId, i)
        //console.log("selected node %d: %O", i, skAddr);
        let sk = await smg.getStoremanInfo(ski.wkAddr);
        //console.log("storeman %d info: %O", i, sk);
    }    
}
module.exports = {
    g,setupNetwork,
    registerStart,stakeInOne,
    stakeInPre,toSelect,
}
