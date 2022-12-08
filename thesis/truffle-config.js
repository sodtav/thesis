const HDWalletProvider = require('@truffle/hdwallet-provider');

module.exports = {
  plugins: ['truffle-plugin-verify'],
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*"
    },
    goerli: {
      provider: () => 
        new HDWalletProvider({
          //Metamask mnemonic phrase
          mnemonic: {
            phrase: "XXXX XXXX XXXX XXXX XXXX XXXX XXXX XXXX XXXX XXXX XXXX XXXX"
          },
          //Infura project address for accessing the smart contract
          providerOrUrl: 'https://goerli.infura.io/v3/XXXXXXXXXXXXXX'
        }),
      network_id: 5,
      gas: 3000000,
    }
  },
  api_keys: {
    //Etherscan API key for validating the smart contract
    etherscan:"XXXXXXXXXXXXXXXXXXXXXXXX"
  },
  compilers: {
    solc: {
      version: "0.8.14"
    }
  }
};
