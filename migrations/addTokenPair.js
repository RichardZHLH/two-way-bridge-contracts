const path = require("path");
const fs = require("fs");
const Contract = require("./utils/contract");
const { defaultContractCfg, bipChainIdDict, ADDRESS_0 } = require('./utils/config');
const { concatObject, showTxInfo } = require("./utils/tool");

const tokenPairInfo = [
  {
    id: 114,
    aInfo: {
      account: ADDRESS_0,
      name: "XDC",
      symbol: "XDC",
      decimals: 18,
      chainID: bipChainIdDict.XDC
    },
    fromChainID: bipChainIdDict.XDC,
    fromAccount: ADDRESS_0,
    toChainID: bipChainIdDict.WAN,
    toAccount: "0x78c6523192078D1cf5C3eC355733A1B9131Be7f3"
  },
  {
    id: 115,
    aInfo: {
      account: ADDRESS_0,
      name: "XDC",
      symbol: "XDC",
      decimals: 18,
      chainID: bipChainIdDict.XDC
    },
    fromChainID: bipChainIdDict.XDC,
    fromAccount: ADDRESS_0,
    toChainID: bipChainIdDict.AVAX,
    toAccount: "0x3ecc2399611A26E70dbac73714395b13Bc3B69fA"
  },
  {
    id: 116,
    aInfo: {
      account: ADDRESS_0,
      name: "XDC",
      symbol: "XDC",
      decimals: 18,
      chainID: bipChainIdDict.XDC
    },
    fromChainID: bipChainIdDict.XDC,
    fromAccount: ADDRESS_0,
    toChainID: bipChainIdDict.BSC,
    toAccount: "0x95492fD2f5b2D2e558e8aF811f951e2DCbc846d3"
  },
  {
    id: 117,
    aInfo: {
      account: ADDRESS_0,
      name: "XDC",
      symbol: "XDC",
      decimals: 18,
      chainID: bipChainIdDict.XDC
    },
    fromChainID: bipChainIdDict.XDC,
    fromAccount: ADDRESS_0,
    toChainID: bipChainIdDict.MATIC,
    toAccount: "0x7e76Ae3b4791A3c36233655d1e37Ec82F666bEFf"
  },
  {
    id: 129,
    aInfo: {
      account: ADDRESS_0,
      name: "TRX",
      symbol: "TRX",
      decimals: 6,
      chainID: bipChainIdDict.TRX
    },
    fromChainID: bipChainIdDict.TRX,
    fromAccount: ADDRESS_0,
    toChainID: bipChainIdDict.WAN,
    toAccount: "0x2B6Bae71dBB0860A705D11A8604FaE228b1F5a7e"
  }
]

async function addTokenPair(argv) {
  let tp = tokenPairInfo.find(v => v.id === argv.id);
  if (!tp) {
    console.error("invalid token pair id");
    return;
  }

  let deployed = require(path.join(__dirname, "deployed", (argv.network + ".json")));
  let abiFile = path.join(__dirname, "deployed", deployed["TokenManagerDelegate"].abi);
  let abi = JSON.parse(fs.readFileSync(abiFile, 'utf-8'));

  let cfg = concatObject(defaultContractCfg[argv.network], {
    network: argv.network,
    nodeURL: argv.nodeURL,
    privateKey: argv.ownerPk,
    mnemonic: argv.mnemonic,
    index: argv.ownerIdx,
    gasPrice: argv.gasPrice,
    gasLimit: argv.gasLimit
  });
  let contract = new Contract(cfg, abi, deployed["TokenManagerProxy"].address);
  let receipt = await contract.send("addTokenPair", tp.id, tp.aInfo, tp.fromChainID, tp.fromAccount, tp.toChainID, tp.toAccount);
  showTxInfo(receipt, "TokenManagerProxy");
}

module.exports = addTokenPair;