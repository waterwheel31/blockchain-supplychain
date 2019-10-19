
var HDWalletProvider = require('truffle-hdwallet-provider');

var mnemonic = 'wood deal board resemble proof oblige velvet affair damage pepper alien unlock';

module.exports = {
  networks: {
    rinkeby: {
      provider: function(){
        return new HDWalletProvider(mnemonic, "http://rinkeby.infura.io/v3/acc3a7df88e14ef09cdb6aafd334f146");
      
        },
        network_id: "1" // Match any network id
    }
  }
};