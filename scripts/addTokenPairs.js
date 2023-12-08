const assert = require('assert')
const ethers = require('ethers')
const networks = require('./config.js')

async function main() {

    const records = require('./JSON_WAIT_SIGN.json')
    let nonce = {}
    let gasPrice = {}
    const abi = require('../artifacts/contracts/tokenManager/TokenManagerDelegateV2.sol/TokenManagerDelegateV2.json').abi
    let ifaTm = new ethers.utils.Interface( abi )
    
    for(let i=0; i<records.length; i++) {
        let record = records[i]
        let topic = record.topic
        console.log("topic:", topic)

        let info = topic.split('_')
        let [tokenPairId, execChain, fromChain, fromToken, toChain, toToken] = info
        console.log("info:", tokenPairId, execChain, fromChain, fromToken, toChain, toToken)
        assert.equal(record.chain, execChain, 'exec chain failed')
        let cfgChain = networks[execChain+'_mainnet']
        // console.log("cfgChain:", cfgChain)
        assert.equal(record.chainId, cfgChain.chainId, 'chainId failed')
        assert.equal(record.from.toLowerCase(), cfgChain.foundation.toLowerCase(), 'foundation failed')
        assert.equal(record.to.toLowerCase(), cfgChain.groupApprove.toLowerCase(), 'groupApprove failed')
        assert.equal(record.params[0], cfgChain.bip44ChainId, 'bip44ChainId failed')
        assert.equal(record.params[1].toLowerCase(), cfgChain.tokenManager.toLowerCase(), 'tokenManager failed')

        let httpProvider = new ethers.providers.JsonRpcProvider(cfgChain.url)
        await httpProvider.ready
        chainInfo = await httpProvider.getNetwork()
        //console.log("chainInfo:", chainInfo)
        if(execChain != 'WAN') {
            assert.equal(record.chainId, chainInfo.chainId, 'online chainId failed')
        }
        if(nonce[execChain] != undefined) {
            nonce[execChain] += 1
        } else {
            nonce[execChain] = await httpProvider.getTransactionCount(record.from)
        }
        console.log("nonce[execChain]:", nonce[execChain], record.nonce)
        assert.equal(nonce[execChain], record.nonce,    'nonce failed')

        if(execChain == 'ARB') {
            assert.equal(record.gasLimit, "2000000", 'gasLimit failed')
        } else {
            assert.equal(record.gasLimit, "1000000", 'gasLimit failed')
        }
        if(!gasPrice[execChain]) {
            gasPrice[execChain] = await httpProvider.getFeeData()
        }        
        console.log("gasPrice[execChain]:", gasPrice[execChain].gasPrice.toString(), record.gasPrice)

        if(execChain == 'WAN') {
            assert.equal(record.gasPrice, '2000000000', 'WAN gas price failed')
        }else{
            assert.ok(gasPrice[execChain].gasPrice.lte(record.gasPrice), 'gas price failed')

        }

        let inputData = ifaTm.decodeFunctionData('addTokenPair', record.params[2])
        //console.log("ifaTm inputData:", inputData)
        assert.equal(tokenPairId, inputData.id.toNumber(), 'tokenpairId failed')

        let fromChainObj = networks[fromChain+'_mainnet']
        assert.equal(fromChainObj.bip44ChainId, inputData.fromChainID.toNumber(), 'inputdata fromChainID failed')
        let toChainObj = networks[toChain+'_mainnet']
        assert.equal(toChainObj.bip44ChainId, inputData.toChainID.toNumber(), 'inputdata toChainObj failed')
    
        let fromTokenObj = fromChainObj.tokens[fromToken]
        assert.equal(fromTokenObj.Address.toLowerCase(), inputData.fromAccount.toLowerCase(), 'inputdata fromAccount failed')
        let toTokenObj = toChainObj.tokens[toToken]
        assert.equal(toTokenObj.Address.toLowerCase(), inputData.toAccount.toLowerCase(), 'inputdata toAccount failed')
    
        assert.equal(fromTokenObj.Ancestor, toTokenObj.Ancestor, 'Ancestor failed')
        let [ancestorChainName, ancestorTokenName] = fromTokenObj.Ancestor.split('_')
        ancestorChainName = ancestorChainName + '_mainnet'
        let ancestor = networks[ancestorChainName].tokens[ancestorTokenName]
        assert.equal(ancestor.Symbol, inputData.aInfo.symbol, 'ancestor symbol failed')
        assert.equal(ancestor.name, inputData.aInfo.Name, 'ancestor Name failed')
        assert.equal(ancestor.decimals, inputData.aInfo.Decimals, 'ancestor Decimals failed')
        assert.equal(ancestor.account, inputData.aInfo.Address, 'ancestor Address failed')
        assert.equal(networks[ancestorChainName].bip44ChainId, inputData.aInfo.chainID.toNumber(), 'ancestor chainID failed')
    }   

}
function findChainbyBip44ID(id) {

}
main()