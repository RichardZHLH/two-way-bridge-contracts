


const networks = {
  WAN_mainnet:{
    url:"https://gwan-ssl.wandevs.org:56891",
    chainId :1,
    tokenManager:'0x9fdf94dff979dbecc2c1a16904bdfb41d305053a',
    groupApprove:'0xff72713c834a96f3c2f28145b4f05e5faf39e572',
    bip44ChainId:2153201998,
    foundation: '0x0F4f833F031fFF7e76AA783212f786432a14FB90',
    tokens:{
      wanETH:{
        Ancestor:"ETH_ETH",
        Symbol: 'wanETH',
        Name: 'wanETH@wanchain',
        Decimals: 18,
        Address:"0xe3ae74d1518a76715ab4c7bedf1af73893cd435a",
      },
    }
  },
  ETH_mainnet:{
    url:"https://eth-mainnet.g.alchemy.com/v2/5eYUB5F1KeJes9KG3-CiTNBYoQvNmtG6",
    chainId :1,
    tokenManager:'0xbab93311de250b5b422c705129b3617b3cb6e9e1',
    groupApprove:'0xa1223a59a55eaad135bce9f513181c388072cc71',
    bip44ChainId:2147483708,
    foundation: '0x4cEd9c0EA79Ee6181600777D5B6badE7F3D301bF',
    tokens:{
      ETH:{
        Ancestor:"ETH_ETH",
        Symbol: 'ETH',
        Name: 'ethereum',
        Decimals: 18,
        Address:"0x0000000000000000000000000000000000000000",
      },
    }
  },
  BASE_mainnet:{
    url:"https://base.publicnode.com",
    chainId :8453,
    tokenManager:'0x09cDfc56439643d151585B77899d0dC0f982BcD2',
    groupApprove:'0xd97de67b982d79ED9f7EB2b1A13abC704b2cA082',
    bip44ChainId:1073741841,
    foundation: '0x4cEd9c0EA79Ee6181600777D5B6badE7F3D301bF',
    tokens:{
      ETH:{
        Ancestor:"ETH_ETH",
        Symbol: 'ETH',
        Name: 'ethereum',
        Decimals: 18,
        Address:"0x0000000000000000000000000000000000000000",
      },
    }
  },
  MATICETH_mainnet:{
    url:"https://zkevm-rpc.com",
    chainId :1101,
    tokenManager:'0x2eA7211507851074bC640dF83058c9B3c9B5DF55',
    groupApprove:'0xD825d018eE04092997F090adac8DcecA59B13c80',
    bip44ChainId:1073741838,
    foundation: '0x4cEd9c0EA79Ee6181600777D5B6badE7F3D301bF',
    tokens:{
      ETH:{
        Ancestor:"ETH_ETH",
        Symbol: 'ETH',
        Name: 'ethereum',
        Decimals: 18,
        Address:"0x0000000000000000000000000000000000000000",
      },
    }
  },
  LINEA_mainnet:{
    url: "https://1rpc.io/linea",
    chainId :59144,
    tokenManager:'0x97E0883493e8bB7A119A1E36E53ee9E7A2D3CA7b',
    groupApprove:'0x3cc97934F6770b649ef27682c6b9369b073c1058',
    bip44ChainId:1073741842,
    foundation: '0x4cEd9c0EA79Ee6181600777D5B6badE7F3D301bF',
    tokens:{
      ETH:{
        Ancestor:"ETH_ETH",
        Symbol: 'ETH',
        Name: 'ethereum',
        Decimals: 18,
        Address:"0x0000000000000000000000000000000000000000",
      },
    }
  },
  MATIC_mainnet:{
    url: "https://polygon-rpc.com/",
    chainId :137,
    tokenManager:'0xc928c8e48647c8b0ce550c2352087b1cf5c6111e',
    groupApprove:'0x329f162550e3d5d9898a0aae05e21bfcd5f1cf83',
    bip44ChainId:2147484614,
    foundation: '0x4cEd9c0EA79Ee6181600777D5B6badE7F3D301bF',
    tokens:{
      ETH:{
        Ancestor:"ETH_ETH",
        Symbol: 'ETH',
        Name: 'ethereum',
        Decimals: 18,
        Address:"0x7ceb23fd6bc0add59e62ac25578270cff1b9f619",
      },
    }
  },
  ZKETH_mainnet:{
    url: "https://zksync-era.blockpi.network/v1/rpc/public",
    chainId :324,
    tokenManager:'0x6a1b7d7d4b9b9f3e9ce585db35bf68038267aef2',
    groupApprove:'0x58b18FDE33F8FEd285c9c538a894Ca2d1a21DF81',
    bip44ChainId:1073741837,
    foundation: '0x4cEd9c0EA79Ee6181600777D5B6badE7F3D301bF',
    tokens:{
      ETH:{
        Ancestor:"ETH_ETH",
        Symbol: 'ETH',
        Name: 'ethereum',
        Decimals: 18,
        Address:"0x0000000000000000000000000000000000000000",
      },
    }
  },
  ARB_mainnet:{
    url: "https://arb1.arbitrum.io/rpc",
    chainId :42161,
    tokenManager:'0xc928c8e48647c8b0ce550c2352087b1cf5c6111e',
    groupApprove:'0x8d42d317b2bd6b60183461ed41bd00f17c3f3fe8',
    bip44ChainId:1073741826,
    foundation: '0x4cEd9c0EA79Ee6181600777D5B6badE7F3D301bF',
    tokens:{
      ETH:{
        Ancestor:"ETH_ETH",
        Symbol: 'ETH',
        Name: 'ethereum',
        Decimals: 18,
        Address:"0x0000000000000000000000000000000000000000",
      },
    }
  },
  BSC_mainnet:{
    url: "https://bsc-dataseed1.defibit.io",
    chainId :56,
    tokenManager:'0x39af91cba3aed00e9b356ecc3675c7ef309017dd',
    groupApprove:'0x5a809f774a2f9fb2587aeca7e380e3d67522e15f',
    bip44ChainId:2147484362,
    foundation: '0x4cEd9c0EA79Ee6181600777D5B6badE7F3D301bF',
    tokens:{
      ETH:{
        Ancestor:"ETH_ETH",
        Symbol: 'ETH',
        Name: 'ethereum',
        Decimals: 18,
        Address:"0x2170ed0880ac9a755fd29b2688956bd959f933f8",
      },
    }
  },
  OPT_mainnet:{
    url: "https://mainnet.optimism.io/",
    chainId :10,
    tokenManager:'0x1ed3538383bbfdb80343b18f85d6c5a5fb232fb6',
    groupApprove:'0x329f162550e3d5d9898a0aae05e21bfcd5f1cf83',
    bip44ChainId:2147484262,
    foundation: '0x4cEd9c0EA79Ee6181600777D5B6badE7F3D301bF',
    tokens:{
      ETH:{
        Ancestor:"ETH_ETH",
        Symbol: 'ETH',
        Name: 'ethereum',
        Decimals: 18,
        Address:"0x0000000000000000000000000000000000000000",
      },
    }
  },
}

module.exports = networks

// topic:   number_Chain_tokenf_tokent

