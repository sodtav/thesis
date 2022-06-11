const Web3 = require("web3");

// Loading the contract ABI
// (the results of a previous compilation step)
const fs = require("fs");
const { abi } = JSON.parse(fs.readFileSync("mad.json"));

async function main() {
  // Configuring the connection to an Ethereum node
  const network = "ropsten";
  const web3 = new Web3(
    new Web3.providers.HttpProvider(
      `https://${network}.infura.io/v3/${"1746640bb1494ddd8de26dc2bf3f3235"}`
    )
  );
  // Creating a signing account from a private key
  const signer = web3.eth.accounts.privateKeyToAccount(
    "9010e4babc2b2be46c8779e952d4047b1d8c414a47409ab641ef0d66afbc11c9"
  );
  web3.eth.accounts.wallet.add(signer);
  // Creating a Contract instance
  const contract = new web3.eth.Contract(
      abi,
    // Replace this with the address of your deployed contract
    "0x278424F49f63A2F97b72973B706463A05AFF2CF9"
  );
  // Issuing a transaction that calls the `echo` method
  const tx = contract.methods.mint(signer.address, 500);
  const receipt = await tx
    .send({
      from: signer.address,
      gas: await tx.estimateGas(),
    })
    .once("transactionHash", (txhash) => {
      console.log(`Mining transaction ...`);
      console.log(`https://${network}.etherscan.io/tx/${txhash}`);
    });
  // The transaction is now on chain!
  console.log(`Mined in block ${receipt.blockNumber}`);
  contract.methods.returnTotalCoins().call(function (err, res) {

    if (err) {
  
      console.log("An error occured", err)
  
      return
  
    }
  
    console.log("The balance is: ", res)
  
  });
}

main();