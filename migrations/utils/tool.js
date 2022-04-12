const fs = require("fs");
const path = require("path");
const {
  chainDict,
  networkDict,
  networks,
  defaultGas,
  ADDRESS_0
} = require("./config");

function mkdir(dirname) {
  if (fs.existsSync(dirname)) {
    return true;
  } else {
    if (mkdir(path.dirname(dirname))) {
      fs.mkdirSync(dirname);
      return true;
    }
  }
}

function exit(error) {
  console.log(error);
  console.log(`Abort...`);
  process.exit();
}

function parseNetwork(network) {
  let info = networkDict[network];
  if (info) {
    return {chainType: info.chainType, chainId: info.chainId, isMainnet: !!info.isMainnet};
  } else {
    throw new Error("invalid network: " + network);
  }
}

function getProxyDelegate(string) {
  return string.replace(/(.*)Proxy/, "$1Delegate")
}

function skipContract(string) {
  return string.includes("Delegate");
}

function getWorkspace(root, contractLoad, deployScriptFileName) {
  const workspace = {
    WAN: {
      contract: path.join(root, chainDict.WAN.toLowerCase(), contractLoad),
      deploy: path.join(root, chainDict.WAN.toLowerCase(), deployScriptFileName)
    },
    ETH: {
      contract: path.join(root, chainDict.ETH.toLowerCase(), contractLoad),
      deploy: path.join(root, chainDict.ETH.toLowerCase(), deployScriptFileName)
    },
    ETC: {
      contract: path.join(root, chainDict.ETC.toLowerCase(), contractLoad),
      deploy: path.join(root, chainDict.ETC.toLowerCase(), deployScriptFileName)
    },
    EOS: {
      contract: path.join(root, chainDict.EOS.toLowerCase(), contractLoad),
      deploy: path.join(root, chainDict.EOS.toLowerCase(), deployScriptFileName)
    },
    TEST: {
      contract: path.join(root, chainDict.TEST.toLowerCase(), contractLoad),
      deploy: path.join(root, chainDict.TEST.toLowerCase(), deployScriptFileName)
    },
    BSC: {
      contract: path.join(root, chainDict.BSC.toLowerCase(), contractLoad),
      deploy: path.join(root, chainDict.BSC.toLowerCase(), deployScriptFileName)
    },
    AVAX: {
      contract: path.join(root, chainDict.AVAX.toLowerCase(), contractLoad),
      deploy: path.join(root, chainDict.AVAX.toLowerCase(), deployScriptFileName)
    },
    MOONBEAM: {
      contract: path.join(root, chainDict.MOONBEAM.toLowerCase(), contractLoad),
      deploy: path.join(root, chainDict.MOONBEAM.toLowerCase(), deployScriptFileName)
    },
    MATIC: {
      contract: path.join(root, chainDict.MATIC.toLowerCase(), contractLoad),
      deploy: path.join(root, chainDict.MATIC.toLowerCase(), deployScriptFileName)
    },
    ADA: {
      contract: path.join(root, chainDict.ADA.toLowerCase(), contractLoad),
      deploy: path.join(root, chainDict.ADA.toLowerCase(), deployScriptFileName)
    },
    ARB: {
        contract: path.join(root, chainDict.ARB.toLowerCase(), contractLoad),
        deploy: path.join(root, chainDict.ARB.toLowerCase(), deployScriptFileName)
    },
    OPM: {
        contract: path.join(root, chainDict.OPM.toLowerCase(), contractLoad),
        deploy: path.join(root, chainDict.OPM.toLowerCase(), deployScriptFileName)
    },
    FTM: {
        contract: path.join(root, chainDict.FTM.toLowerCase(), contractLoad),
        deploy: path.join(root, chainDict.FTM.toLowerCase(), deployScriptFileName)
    },
    XDC: {
      contract: path.join(root, chainDict.XDC.toLowerCase(), contractLoad),
      deploy: path.join(root, chainDict.XDC.toLowerCase(), deployScriptFileName)
    },
  }
  return workspace;
}

function parseScArgs() {
  const optimist = require('optimist');
  let argv = optimist
  .usage("Usage: nodejs $0 --network [network] --nodeURL [nodeURL] --ownerPk [ownerPrivateKey] --adminPk [adminPrivateKey] --mnemonic [mnemonic] --ownerIdx [ownerIdx] --adminIdx [adminIdx] --gasPrice [gasPrice] --gasLimit [gasLimit] --outputDir[outputDir]")
  .alias('h', 'help')
  .describe('h', 'display the usage')
  .describe('network', `identify chain network, support ${networks}, mainnet means Wanchain mainnet, testnet means Wanchain testnet`)
  .describe('nodeURL', `identify node url`)
  .describe('gasPrice', `identify gasPrice, using ${defaultGas.gasPrice} as default`)
  .describe('gasLimit', `identify gasLimit, using ${defaultGas.gasLimit} as default`)
  .describe('mnemonic', `identify mnemonic`)
  .describe('ownerIdx', `identify owner index in the hd wallet, start with 0, using mix "--mnemonic" and "--ownerIdx"`)
  .describe('adminIdx', `identify admin index in the hd wallet, start with 0, using mix "--mnemonic" and "--adminIdx"`)
  .describe('ownerPk', `identify owner private key`)
  .describe('adminPk', `identify admin private key`)
  .describe('outputDir', `identify the output absolute directory`)
  .default('gasPrice', defaultGas.gasPrice)
  .default('gasLimit', defaultGas.gasLimit)
  .default('outputDir', path.join("deployed"))
  .string(["network", "nodeURL", "mnemonic", "ownerPk", "adminPk", "outputDir"])
  .demand(['network'])
  .argv;

  if (argv.help) {
    optimist.showHelp();
    process.exit(0);
  }
  return argv;
}

function parseOwnerArgs() {
  const optimist = require('optimist');
  let argv = optimist
  // .usage("Usage: nodejs $0 --network [network] --nodeURL [nodeURL] --address [address] --ownerPk [ownerPrivateKey] --mnemonic [mnemonic] --ownerIdx [ownerIdx] --gasPrice [gasPrice] --gasLimit [gasLimit] --inputDir[inputDir] --skipDelegate [skipDelegate] --leave [leave]")
  .usage("Usage: nodejs $0 --network [network] --nodeURL [nodeURL] --address [address] --ownerPk [ownerPrivateKey] --mnemonic [mnemonic] --ownerIdx [ownerIdx] --gasPrice [gasPrice] --gasLimit [gasLimit] --inputDir[inputDir] --skipDelegate [skipDelegate]")
  .alias('h', 'help')
  .describe('h', 'display the usage')
  .describe('network', `identify chain network, support ${networks}, mainnet means Wanchain mainnet, testnet means Wanchain testnet`)
  .describe('nodeURL', `identify node url`)
  .describe('gasPrice', `identify gasPrice, using ${defaultGas.gasPrice} as default`)
  .describe('gasLimit', `identify gasLimit, using ${defaultGas.gasLimit} as default`)
  .describe('address', `identify new owner address`)
  .describe('mnemonic', `identify mnemonic`)
  .describe('ownerIdx', `identify owner index in the hd wallet, start with 0, using mix "--mnemonic" and "--ownerIdx"`)
  .describe('ownerPk', `identify owner private key`)
  .describe('inputDir', `identify the intput absolute directory`)
  .describe('skipDelegate', `identify if skip the delegate contract`)
  // .describe('leave', `identify if set owner to ${ADDRESS_0}`)
  .default('skipDelegate', false)
  // .default('leave', false)
  .default('gasPrice', defaultGas.gasPrice)
  .default('gasLimit', defaultGas.gasLimit)
  .default('inputDir', path.join("deployed"))
  .string(["network", "nodeURL", "address", "mnemonic", "ownerPk", "inputDir"])
  .boolean(['skipDelegate', 'leave'])
  .demand(['network'])
  .argv;

  if (argv.help) {
    optimist.showHelp();
    process.exit(0);
  }
  return argv;
}

function parseTokenPairArgs() {
  const optimist = require('optimist');
  let argv = optimist
  .usage("Usage: nodejs $0 --network [network] --id [id] --nodeURL [nodeURL] --ownerPk [ownerPrivateKey] --mnemonic [mnemonic] --ownerIdx [ownerIdx] --gasPrice [gasPrice] --gasLimit [gasLimit]")
  .alias('h', 'help')
  .describe('h', 'display the usage')
  .describe('network', `identify chain network, support ${networks}, mainnet means Wanchain mainnet, testnet means Wanchain testnet`)
  .describe('nodeURL', `identify node url`)
  .describe('id', `identify token pair id`)
  .describe('gasPrice', `identify gasPrice, using ${defaultGas.gasPrice} as default`)
  .describe('gasLimit', `identify gasLimit, using ${defaultGas.gasLimit} as default`)
  .describe('mnemonic', `identify mnemonic`)
  .describe('ownerIdx', `identify owner index in the hd wallet, start with 0, using mix "--mnemonic" and "--ownerIdx"`)
  .describe('ownerPk', `identify owner private key`)
  .default('gasPrice', defaultGas.gasPrice)
  .default('gasLimit', defaultGas.gasLimit)
  .string(["network", "mnemonic", "ownerPk"])
  .demand(['network', 'id'])
  .argv;

  if (argv.help) {
    optimist.showHelp();
    process.exit(0);
  }
  return argv;
}

function hideObject(obj, keys = [], hide = "******") {
  let showObj = {...obj};
  keys.forEach(key => {
    if (showObj.hasOwnProperty(key)) {
      showObj[key] = hide;
    }
  });
  return showObj;
}

const showTxInfo = (receipt, name = "") => {
  console.log("");
  let title = `Sending transaction to contract ${name}`;
  console.log("   %s", title);
  console.log("   %s", new Array(title.length).join('-'));
  console.log("   > transaction hash:    %s", receipt.transactionHash);
  console.log("   > contract address:    %s", receipt.to);
  console.log("   > block number:        %d", receipt.blockNumber);
  console.log("   > sender:              %s", receipt.from);
  console.log("   > gas used:            %d", receipt.gasUsed);
  console.log("   > status:              %s", receipt.status);
}

const concatObject = (dest, src) => {
  let result = Object.assign({}, dest);
  for (let k in src) {
    let v = src[k];
    if (v !== undefined) {
      result[k] = v;
    }
  }
  return result;
}

module.exports = {
  mkdir,
  exit,
  parseNetwork,
  getProxyDelegate,
  skipContract,
  getWorkspace,
  parseScArgs,
  parseOwnerArgs,
  parseTokenPairArgs,
  hideObject,
  showTxInfo,
  concatObject
};
