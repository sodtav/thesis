const { ethers } = require("ethers");

async function main() {

    const itx = new ethers.providers.InfuraProvider(
        'ropsten',
        '1746640bb1494ddd8de26dc2bf3f3235'
    );

    const signer = new ethers.Wallet('9010e4babc2b2be46c8779e952d4047b1d8c414a47409ab641ef0d66afbc11c9', itx);
    console.log(`Signer public address: ${signer.address}`);
    
    const { balance } = await itx.send("relay_getBalance", [signer.address]);
    console.log(`Current ITX balance: ` + ethers.utils.formatEther(balance));
}

async function deposit() {
    const depositTx = await signer.sendTransaction({
        // Address of the ITX deposit contract
        to: "0x015C7C7A7D65bbdb117C573007219107BD7486f9",
        // The amount of ether you want to deposit in your ITX gas tank
        value: ethers.utils.parseUnits("0.1", "ether"),
      });
      console.log("Mining deposit transaction...");
      console.log(
        `https://ropsten.etherscan.io/tx/${depositTx.hash}`
      );
    
      // Waiting for the transaction to be mined
      const receipt = await depositTx.wait();
    
      // The transaction is now on chain!
      console.log(`Mined in block ${receipt.blockNumber}`);
}

require("dotenv").config();
main();