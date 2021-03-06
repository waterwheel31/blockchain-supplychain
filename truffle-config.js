
var HDWalletProvider = require('truffle-hdwallet-provider');

var mnemonic = 'spirit supply whale amount human item harsh scare congress discover talent hamster';

module.exports = {
  
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*" // Match any network id
    },
    rinkeby: {
      provider: function(){
        return new HDWalletProvider(mnemonic, "https://rinkeby.infura.io/v3/acc3a7df88e14ef09cdb6aafd334f146");
      
        },
        network_id: "4" // Match any network id
    }
  }
};