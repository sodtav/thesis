const HDWalletProvider = require('@truffle/hdwallet-provider');

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*"
    },
    ropsten: {
      provider: () => 
        new HDWalletProvider({
          mnemonic: {
            phrase: "output ginger wish music cluster foam yard lazy snake weekend slow loud"
          },
          providerOrUrl: "https://ropsten.infura.io/v3/1746640bb1494ddd8de26dc2bf3f3235"
        }),
      network_id: 3,
      gas: 5500000
    }
  }
};