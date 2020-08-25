const utils = require("../utils");
const StoremanGroupDelegate = artifacts.require('StoremanGroupDelegate')
const StoremanGroupProxy = artifacts.require('StoremanGroupProxy');


const { registerStart,registerStart2,stakeInPre, sendIncentive,g, toSelect,setupNetwork } = require('../basee.js')

contract('StoremanGroupDelegate', async () => {
 
    let  smg
    let groupId
    let groupId2

    before("init contracts", async() => {
        let smgProxy = await StoremanGroupProxy.deployed();
        smg = await StoremanGroupDelegate.at(smgProxy.address)
        await setupNetwork();
    })


    it('T1 registerStart', async ()=>{
        groupId = await registerStart(smg);
        console.log("groupId: ", groupId)
    })

    it('stakeInPre ', async ()=>{
        await stakeInPre(smg, groupId)
    })
    it('T2 test select', async ()=>{
        await toSelect(smg, groupId);
        let count = await smg.getSelectedSmNumber(groupId)
        console.log("slected sm number: %d", count);  
        for (let i = 0; i<count; i++) {
            let skAddr = await smg.getSelectedSmInfo(groupId, i)
            let sk = await smg.getStoremanInfo(skAddr[0]);
            console.log("storeman %d info: %s, %s, %s", i, sk.pkAddress, sk.groupId, sk.nextGroupId);
        } 
    })
    it('T3 registerStart2', async ()=>{
        groupId2 = await registerStart2(smg, groupId, [], []);
        console.log("groupId2: ", groupId2)
        let sk = await smg.getSelectedSmInfo(groupId2, 1);
        console.log("registerStart2, 1:", sk)
    })
    it('T4', async ()=>{ 
        let wk = utils.getAddressFromInt(20001)
        let tx = await smg.stakeIn(groupId2, wk.pk, wk.pk,{value:60000});
        console.log("tx:", tx);

        let sk = await smg.getSelectedSmInfo(groupId2, 1);
        console.log("sk:=======", sk)
        //assert.equal(sk.pkAddress.toLowerCase(), wk.addr, "the node should be second one")
    })
    it('T5 select2', async ()=>{
        await toSelect(smg, groupId2);
        let count = await smg.getSelectedSmNumber(groupId2)
        console.log("slected sm number: %d", count);  
        for (let i = 0; i<count; i++) {
            let skAddr = await smg.getSelectedSmInfo(groupId2, i)
            let sk = await smg.getStoremanInfo(skAddr[0]);
            console.log("storeman %d info: %s, %s, %s", i, sk.pkAddress, sk.groupId, sk.nextGroupId);
        } 
    })
    it('T6 dismiss', async ()=>{
        let groupLeader = await smg.getSelectedSmInfo(groupId, 0);
        console.log("groupLeader:", groupLeader)
        await smg.storemanGroupDismiss(groupId,{from:g.leader})
        let count = await smg.getSelectedSmNumber(groupId)
        console.log("slected sm number: %d", count);  
        for (let i = 0; i<count; i++) {
            let skAddr = await smg.getSelectedSmInfo(groupId, i)
            let sk = await smg.getStoremanInfo(skAddr[0]);
            console.log("storeman %d info: %s, %s, %s", i, sk.pkAddress, sk.groupId, sk.nextGroupId);
        }  
    }) 

})
