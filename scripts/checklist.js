const hre = require("hardhat");

async function main() {
    const OWNER_ADDRESS = '0xF6eB3CB4b187d3201AfBF96A38e62367325b29F9' 

    let deployer = (await hre.ethers.getSigner()).address;
    console.log("deployer:", deployer)
    const network = hre.network.name
    const scAddr = require('../deployed/'+network+'.json')

    let tokenManager = await hre.ethers.getContractAt("TokenManagerDelegateV2", scAddr.tokenManagerProxy);
    let cross = await hre.ethers.getContractAt("CrossDelegateV4", scAddr.crossProxy);
    let oracle = await hre.ethers.getContractAt("OracleDelegate", scAddr.oracleProxy);
    let signatureVerifier = await hre.ethers.getContractAt("SignatureVerifier", scAddr.signatureVerifier);
    let groupApprove = await hre.ethers.getContractAt("GroupApprove", scAddr.groupApprove);

    let info
    let curveID = 1  // default bn128


    info = await cross.currentChainID();
    console.log("Bip44ChainID:", info)
    
    info = await cross.hashType();
    console.log("hashType:", info)
    
    info = await signatureVerifier.verifierMap(0);
    console.log("verifierMap 0:", info)
    if(info != '0x0000000000000000000000000000000000000000') {
        curveID = 0
    }
    info = await signatureVerifier.verifierMap(1);
    console.log("verifierMap 1:", info)

    info = await cross.owner()
    console.log('cross owner:', info)
    info = await tokenManager.owner()
    console.log('tokenManager owner:', info)
    info = await oracle.owner()
    console.log('oracle owner:', info)
    info = await signatureVerifier.owner()
    console.log('signatureVerifier owner:', info)

    info = await cross.hashFunc('0x11')
    // 0x0552ab8dc52e1cf9328ddb97e0966b9c88de9cca97f48b0110d7800982596158
    console.log("hash:", info)

    // //  **************** bn128
    // if( curveID == 1  ) {
    //     let s = "0x0bdf42b46bb6bda406dcf2e021f5db51da648c54206c0f81c4cf2626c88c0373"
    //     let hash = '0xa7b494e72a7a38a7905b031b68821a72dd09143ac97d8d291d61abc54301bfa9'
    //     groupKeyX = '0x2ace5d04ae517160801b1130a405603cebae070913c3658b04c3c49cd01372d4'
    //     groupKeyY = '0x25420a7af1a1a808fea1a86897aca4fa146c0012dfefc70458ad58d289f5dfe9'
    //     randomPointX = '0x1108d976a84099cb3bf7bb4c55183cd7604085bb4aab499a7964f77a764d6fc5'
    //     randomPointY = '0x1405d1494a7cac4cf69f7092d743e3ea504ff05f6ea9b3e4a532e80b1fd662cb'
    //     info = await signatureVerifier.verify(curveID, s, groupKeyX,groupKeyY, randomPointX, randomPointY, hash)
    //     console.log("verify:", info)
    // } else {
    //     //  **************************ecrecover
    //     curveID = 0
    //     hash = '0x248d3d6339700ffb772cb76834da6a875e2bf045b81012bfc3cd60a530a46dea'
    //     s = '0x08e392a98e552407cf97980198a3d2bf871f0ed22e26fc7925e09d9830f7870d'
    //     randomPointX = '0x8c2150a608b22342295d15ba0303127883fea3d4241255df827de51d67bebdc4'
    //     randomPointY = '0x000000000000000000000000000000000000000000000000000000000000001c'
    //     groupKeyX = '0xcbb364e48e6c8b0880e61aa49b84838d7685ff2177b4ee02a0914ceb3747788b'
    //     groupKeyY = '0x50903d23f4f530843f3aa6d70a9fd60565be8963c85c2204870c21a01eb1e52f'
    //     info = await signatureVerifier.verify(curveID, s, groupKeyX,groupKeyY, randomPointX, randomPointY, hash)
    //     console.log("verify:", info)
    // }

    info = await groupApprove.foundation()
    console.log("groupApprove foundation:", info)

}

main()