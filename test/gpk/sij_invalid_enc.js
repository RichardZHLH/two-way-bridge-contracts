const StoremanGroupProxy = artifacts.require('StoremanGroupProxy');
const StoremanGroupDelegate = artifacts.require('StoremanGroupDelegate');
const GpkProxy = artifacts.require('GpkProxy');
const GpkDelegate = artifacts.require('GpkDelegate');
const { g, curve1, curve2, setupNetwork, registerStart, stakeInPre, toSelect } = require('../base.js');
const { GpkStatus, CheckStatus, SlashType, Data } = require('./Data');
const utils = require('../utils.js');
const optimist = require("optimist");
const { assert } = require('chai');

const fakeSc = ['local', 'coverage'].includes(optimist.argv.network);

// group
let groupId = '';

// contract
let smgSc, gpkProxy, gpkDelegate, gpkSc;
let data;

contract('Gpk_UT_sij_invalid_enc', async () => {
  let owner, admin;

  before("should do all preparations", async() => {
    // config
    let ConfigDelegate = await ethers.getContractFactory("ConfigDelegate");
    cnf = await ConfigDelegate.deploy()
    await cnf.deployed();

    let FakeSkCurve = await ethers.getContractFactory("FakeSkCurve");
    secp256k1 = await FakeSkCurve.deploy();
    await secp256k1.deployed();
    let FakeBnCurve = await ethers.getContractFactory("FakeBnCurve");
    let bn256 = await FakeBnCurve.deploy();
    await bn256.deployed();

    // smg
    let CommonTool = await ethers.getContractFactory("CommonTool")
    let commonTool = await CommonTool.deploy()
    await commonTool.deployed()

    let StoremanUtil = await ethers.getContractFactory("StoremanUtil",{
      libraries:{
        CommonTool:commonTool.address,
      }
    })
    let storemanUtil = await StoremanUtil.deploy()
    await storemanUtil.deployed()
    g.storemanUtil = storemanUtil

    let StoremanLib = await ethers.getContractFactory("StoremanLib",{
      libraries:{
        StoremanUtil:storemanUtil.address,
      }
    })
    let storemanLib = await StoremanLib.deploy()
    await storemanLib.deployed()

    let IncentiveLib = await ethers.getContractFactory("IncentiveLib",{
      libraries:{
        StoremanUtil:storemanUtil.address,
      }
    })
    let incentiveLib = await IncentiveLib.deploy()
    await incentiveLib.deployed()

    let StoremanGroupDelegate = await ethers.getContractFactory("StoremanGroupDelegate",{
      libraries:{
        StoremanUtil:storemanUtil.address,
        StoremanLib:storemanLib.address,
        IncentiveLib:incentiveLib.address,
      }
    })
    smgSc = await StoremanGroupDelegate.deploy();
    await smgSc.deployed()
    g.storemanGroupProxy = smgSc

    let FakePosLib = await ethers.getContractFactory("FakePosLib")
    let fakePosLib = await FakePosLib.deploy()
    g.fakePosLib = fakePosLib
    await fakePosLib.deployed()
    let ListGroup = await ethers.getContractFactory("ListGroup",{
      libraries:{
        StoremanUtil:storemanUtil.address,
      }
    })
    let listGroup = await ListGroup.deploy(smgSc.address, fakePosLib.address)
    await listGroup.deployed()
    g.listGroup = listGroup

    let FakeQuota = await ethers.getContractFactory("fakeQuota")
    let fakeQuota = await FakeQuota.deploy()
    await fakeQuota.deployed()
    g.quota = fakeQuota
    let FakeMetric = await ethers.getContractFactory("FakeMetric")
    let fakeMetric = await FakeMetric.deploy()
    await fakeMetric.deployed()
    g.fakeMetric = fakeMetric

    await smgSc.setGlobalGroupScAddr(listGroup.address);

    // gpk
    let GpkProxy = await ethers.getContractFactory("GpkProxy")
    gpkProxy = await GpkProxy.deploy()
    await gpkProxy.deployed()
    let GpkLib = await ethers.getContractFactory("GpkLib",{
      libraries:{
        CommonTool:commonTool.address,
      }
    })
    let gpkLib = await GpkLib.deploy();
    await gpkLib.deployed();
    let GpkDelegate = await ethers.getContractFactory("GpkDelegate", {
      libraries : {
        GpkLib: gpkLib.address
      }
    });
    gpkDelegate = await GpkDelegate.deploy();
    await gpkDelegate.deployed();
    await gpkProxy.upgradeTo(gpkDelegate.address);
    gpkSc = await ethers.getContractAt('GpkDelegate', gpkProxy.address)
    console.log("Gpk contract address: %s", gpkProxy.address);

    // network
    await setupNetwork();

    owner = g.owner;
    admin = g.admin;
    console.log("onwer address: %s", owner);
    console.log("admin address: %s", admin);

    let curveIdArray = [curve1, curve2];
    let algoIdArray = [0, 1];
    let curveAddrArray = [secp256k1.address, bn256.address];
    await cnf.addAdmin(admin);
    assert.equal(await cnf.mapAdmin(admin), true);
    await cnf.connect(g.signerAdmin).setCurve(curveIdArray, curveAddrArray);
    assert.equal(await cnf.getCurve(curve1), curveAddrArray[0]);
    assert.equal(await cnf.getCurve(curve2), curveAddrArray[1]);

    await smgSc.addAdmin(owner);
    await smgSc.setDependence(fakeMetric.address,gpkSc.address,fakeQuota.address,fakePosLib.address)
    groupId = await registerStart(smgSc);
    console.log("storeman group started:", groupId);

    await gpkSc.addAdmin(admin);
    assert.equal(await gpkSc.mapAdmin(admin), true);
    await gpkSc.connect(g.signerAdmin).setGpkCfg(groupId, curveIdArray, algoIdArray);
    let gpkCount = await gpkSc.getGpkCount(groupId);
    assert.equal(gpkCount, 2);

    let regTime = parseInt(new Date().getTime());
    let gi = await smgSc.getStoremanGroupInfo(groupId);
    await stakeInPre(smgSc, groupId);
    await utils.sleepUntil(regTime + (parseInt(gi.registerDuration) + 5) * 1000);
    await toSelect(smgSc, groupId);

    data = new Data(smgSc, gpkSc, groupId);
    await data.init();

    await gpkSc.connect(g.signerOwner).setDependence(cnf.address, smgSc.address);
  })

  // setPolyCommit
  it('[GpkDelegate_setPolyCommit] should success', async () => {
    let result = {};
    try {
      for (let i = 0; i < data.smList.length; i++) {
        await data.setPolyCommit(0, 0, i);
      }
    } catch (e) {
      result = e;
    }
    let info = await gpkSc.getGroupInfo(groupId, 0);
    assert.equal(info.curve1Status, GpkStatus.Negotiate);
  })

  // setEncSij
  it('[GpkDelegate_setEncSij] should success', async () => {
    let result = {};
    try {
      if (!fakeSc) {
        data.round[0].src[0].send[1].encSij = data.round[0].src[0].send[1].encSij + '01';
      }
      await data.setEncSij(0, 0, 1, 0);
      await data.setCheckStatus(0, 0, 0, false, 1);
    } catch (e) {
      result = e;
    }
    let src = data.smList[0].address;
    let dest = data.smList[1].address;
    let info = await gpkSc.getSijInfo(groupId, 0, 0, src, dest);
    assert.equal(info.encSij, data.round[0].src[0].send[1].encSij);
    assert.equal(info.checkStatus, CheckStatus.Invalid);
  })

  // revealSij
  it('[GpkDelegate_revealSij] should success', async () => {
    let src = data.smList[0].address;
    let dest = data.smList[1].address;
    let sij = fakeSc? 0 : data.round[0].src[0].send[1].sij;
    let tx = await gpkSc.connect(g.signerLeader).revealSij(groupId, 0, 0, dest, sij, data.round[0].src[0].send[1].ephemPrivateKey);
    let result = await tx.wait();
    const eventAbi = [{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"groupId","type":"bytes32"},{"indexed":true,"internalType":"uint8","name":"slashType","type":"uint8"},{"indexed":true,"internalType":"address","name":"slashed","type":"address"},{"indexed":false,"internalType":"address","name":"partner","type":"address"},{"indexed":false,"internalType":"uint16","name":"round","type":"uint16"},{"indexed":false,"internalType":"uint8","name":"curveIndex","type":"uint8"}],"name":"SlashLogger","type":"event"}]
    let iface = new ethers.utils.Interface(eventAbi);
    // console.log("iface:", iface)
    result.logs = result.logs.map((log) => {
      try {
        return iface.parseLog(log);
      } catch (e) {
        return log;
      }
    });
    let event = result.logs.find(log => log.name === "SlashLogger").args;
    assert.equal(event.slashed.toLowerCase(), src.toLowerCase());
    assert.equal(event.slashType.toString(), SlashType.SijInvalid);
  })
})
