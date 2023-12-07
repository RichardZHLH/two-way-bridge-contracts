const assert = require('assert')
const ethers = require('ethers')
const networks = require('./config.js')

async function main() {

    const records = require('./JSON_WAIT_SIGN.json')
    let nonce = {}
    for(let i=0; i<1; i++) {
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
        console.log("chainInfo:", chainInfo)
        if(execChain != 'WAN') {
            assert.equal(record.chainId, chainInfo.chainId, 'online chainId failed')
        }
        if(nonce[execChain]) {
            nonce[execChain] += 1
        } else {
            nonce[execChain] = await httpProvider.getTransactionCount(record.from)
            console.log("nonce[execChain]:", nonce[execChain])
        }
        assert(record.nonce, nonce[execChain], 'nonce failed')
    }
}

main()