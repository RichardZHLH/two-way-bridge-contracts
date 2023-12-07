const hre = require("hardhat");

async function main() {

    let info, tx

    //console.log("cfg: ", hre.config.networks)
    const OWNER_ADDRESS = '0xF6eB3CB4b187d3201AfBF96A38e62367325b29F9' 


    let records = require('./JSON_WAIT_SIGN_2023_12-06T07_48_26.json')
    let record = records[0]

    let networks = Object.values(hre.config.networks)
    let network2 = networks.filter(item=>item.bip44ChainId==record.params[0])
    // console.log("url:", network2)
    
    let network, httpProvider
    if(network2.length == 0) {
        console.log("can not find network, bip44ChainId:", record.params[0])
        return
    } 
    network = network2[0]
    httpProvider = new ethers.providers.JsonRpcProvider(network.url)
    await httpProvider.ready

    let chainInfo = await httpProvider.getNetwork()
    if(record.chainId != chainInfo.chainId) {
        network = network2[1]
        httpProvider = new ethers.providers.JsonRpcProvider(network.url)
        await httpProvider.ready
        chainInfo = await httpProvider.getNetwork()
        if(record.chainId != chainInfo.chainId) {
            console.log("chainId is wrong:", chainInfo.chainId)
            return
        }
    }
    
    let scFactory = await hre.ethers.getContractFactory('SignatureVerifier')
    let  iface = new ethers.utils.Interface( scFactory.interface.fragments )
    let inputData = iface.encodeFunctionData('transferOwner', [OWNER_ADDRESS])
    console.log("inputData:", inputData)
    
    let toAddr =    '0x76ab1A2e6344cEE2dEf67f8b0cfE995F006B9a86' // sc addr which need to transfer owner. for example, SignatureVerifier 
    let wallet = new ethers.Wallet(Buffer.from(process.env.PK.slice(2),'hex'), httpProvider)
    let SC = new ethers.Contract(record.to, [record.abi], httpProvider)  // groupApprove sc instance.
    SC = SC.connect(wallet)

    
    tx = await SC.proposal(record.params[0], toAddr, inputData)
    tx = await tx.wait()
    console.log("tx:", tx)

}

main()