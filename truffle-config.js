//-------------Writing own in the config file-------------
const path = require('path')


const HDWalletProvider = require('@truffle/hdwallet-provider')

require('dotenv').config({ path: './.env' })


const rinkebyURL = `https://rinkeby.infura.io/v3/${process.env.INFURA_API_KEY}`


const bnbURL = 'https://data-seed-prebsc-1-s1.binance.org:8545/'

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  contracts_build_directory: path.join(__dirname, 'client/src/contracts'),
  networks: {
    development: {
      host: 'localhost',
      port: 7545,
      network_id: '*',
    },

    rinkeby_infura: {
      provider: function () {
        return new HDWalletProvider(process.env.MNEMONICS, rinkebyURL)
      },
      network_id: 4,
      skipDryRun: true,
    },

    

    bnb_testNet: {
      provider: function () {
        return new HDWalletProvider(process.env.MNEMONICS, bnbURL)
      },
      network_id: 97,
    },
  },

  compilers: {
    solc: {
      version: '0.8.4',
    },
  },
}
