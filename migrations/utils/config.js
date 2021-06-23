const chainDict = {
  WAN: "WAN",
  ETH: "ETH",
  ETC: "ETC",
  EOS: "EOS",
  BSC: "BSC",
  AVAX: "AVAX",
  TEST: "TEST"
};

const chainIndexDict = {
  WAN: 0x57414e,
  ETH: 0x3c,
  ETC: 0x3d,
  EOS: 0xc2,
  BSC: 0x2ca,
  AVAX: 0x2328,
};

const chainNature = {
  system: 1,
  custom: 2
};

const networkDict = {
  // WAN
  mainnet: {name:"mainnet", chainId: 1, chainType: chainDict.WAN, chainIndex:chainIndexDict.WAN, nature: chainNature.system},
  testnet: {name:"testnet", chainId: 3, chainType: chainDict.WAN, chainIndex:chainIndexDict.WAN, nature: chainNature.system},
  // ETH
  ethereum: {name:"ethereum", chainId: 1, chainType: chainDict.ETH, chainIndex:chainIndexDict.ETH, nature: chainNature.system},
  // ropsten: {name:"ropsten", chainId: 3, chainType: chainDict.ETH, chainIndex:chainIndexDict.ETH, nature: chainNature.system},
  rinkeby: {name:"rinkeby", chainId: 4,chainType: chainDict.ETH, chainIndex:chainIndexDict.ETH,nature: chainNature.system},
  // goerli: {name:"goerli", chainId: 6284, chainType: chainDict.ETH, chainIndex:chainIndexDict.ETH, nature: chainNature.system},
  // kovan: {name:"kovan", chainId: 42, chainType: chainDict.ETH, chainIndex:chainIndexDict.ETH, nature: chainNature.system},
  bscMainnet: {name:"bscMainnet", chainId: 56,chainType: chainDict.BSC, chainIndex:chainIndexDict.BSC,nature: chainNature.custom},
  bscTestnet: {name:"bscTestnet", chainId: 97,chainType: chainDict.BSC, chainIndex:chainIndexDict.BSC,nature: chainNature.custom},

  avalancheMainnet: {name:"avalancheMainnet", chainId: 43114,chainType: chainDict.AVAX, chainIndex:chainIndexDict.AVAX,nature: chainNature.custom},
  avalancheTestnet: {name:"avalancheTestnet", chainId: 43113,chainType: chainDict.AVAX, chainIndex:chainIndexDict.AVAX,nature: chainNature.custom},
}

const networks = Object.values(networkDict).map(v => v.name);

const defaultGas = {
  gasPrice: 10000000000,
  gasLimit: 800000
}

const defaultNodeUrlDict = {
  mainnet:  'http://gwan-mainnet.wandevs.org:26891', // http or wss
  testnet: 'http://gwan-testnet.wandevs.org:36891', // http or wss,
  ethereum: 'http://geth-mainnet.wandevs.org:26892', // http or wss,
  rinkeby: 'http://geth-testnet.wandevs.org:36892', // http or wss
  bscMainnet: 'https://bsc-dataseed1.binance.org:443', // http or wss,
  bscTestnet: 'https://data-seed-prebsc-1-s1.binance.org:8545', // http or wss
  avalancheMainnet: "https://api.avax.network/ext/bc/C/rpc",
  avalancheTestnet: "https://api.avax-test.network/ext/bc/C/rpc",
}

const defaultHadrfork = "byzantium";

let defaultContractCfg = {};
Object.keys(networkDict).forEach(network => {
  defaultContractCfg[network] = {};
  defaultContractCfg[network].network = networkDict[network].name;
  defaultContractCfg[network].nodeURL = defaultNodeUrlDict[network];
  defaultContractCfg[network].hardfork = defaultHadrfork;
  defaultContractCfg[network].privateKey = '';
  defaultContractCfg[network].mnemonic = '';
  defaultContractCfg[network].index = 0;
  defaultContractCfg[network].gasPrice = defaultGas.gasPrice;
  defaultContractCfg[network].gasLimit = defaultGas.gasLimit;
});

let defaultArgv = {};
Object.keys(defaultContractCfg).forEach(network => {
  defaultArgv[network] = {};
  defaultArgv[network].network = defaultContractCfg[network].network;
  defaultArgv[network].nodeURL = defaultContractCfg[network].nodeURL;
  defaultArgv[network].mnemonic = defaultContractCfg[network].mnemonic;
  defaultArgv[network].ownerIdx = defaultContractCfg[network].index;
  defaultArgv[network].adminIdx = defaultContractCfg[network].index;
  defaultArgv[network].ownerPk = defaultContractCfg[network].privateKey;
  defaultArgv[network].adminPk = defaultContractCfg[network].privateKey;
  defaultArgv[network].gasPrice = defaultContractCfg[network].gasPrice;
  defaultArgv[network].gasLimit = defaultContractCfg[network].gasLimit;
  defaultArgv[network].outputDir = '';
});

const curveMap = new Map([
  ['secp256k1', 0],
  ['bn256', 1]
]);
const priceSymbol = chainDict.WAN;
const quotaDepositRate = 15000;
const htlcTimeTestnet = 60*60; //unit: s
const fastCrossMinValue = 1000000000000000; // 0.001 USD
const ADDRESS_0 = "0x0000000000000000000000000000000000000000";

const contractLoad = "contract.js";

const deployScript = {
  clean: "deploy_clean.js",
  update: "deploy_update.js",
  wanchainSc: "wanchain_sc_deploy.js",
  // wanchainSc: "wanchain_sc_deploy_update_btc.js",
  // wanchainSc: "wanchain_sc_deploy_bsc.js",
  wanchainScUpdate: "wanchain_sc_deploy_update.js"
};

const wanchainScScript = deployScript.wanchainSc;
// const wanchainScScript = deployScript.wanchainScUpdate;
// const wanchainScScript = "wanchain_sc_deploy_update_tm.js";
// const wanchainScScript = "wanchain_sc_deploy_update_value.js";
// const wanchainScScript = "wanchain_sc_deploy_owner.js";

module.exports = {
  chainDict,
  chainIndexDict,
  chainNature,
  networkDict,
  networks,

  defaultGas,
  defaultNodeUrlDict,
  defaultContractCfg,
  defaultArgv,

  contractLoad,
  deployScript,
  wanchainScScript,

  curveMap,
  priceSymbol,
  quotaDepositRate,
  htlcTimeTestnet,
  fastCrossMinValue,
  ADDRESS_0,
};
