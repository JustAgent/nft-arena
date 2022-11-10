const ethers = require("ethers");
const abi = require("./artifacts/contracts/VRFv2Consumer.sol/VRFv2Consumer.json");
require("dotenv").config();
async function main() {
  const address = "0xDD63F140F0950866694B04D1aD082Db6682E20F3";
  const provider = new ethers.providers.WebSocketProvider(
    `wss://eth-goerli.g.alchemy.com/v2/${process.env.ALCHEMY_KEY}`
  );
  const contract = new ethers.Contract(address, abi.abi, provider);
  console.log("**********************");
  contract.on("RequestFulfilled", (requestId, randomWords, event) => {
    //console.log(requestId, randomWords);
    let info = {
      id: requestId,
      words: randomWords,
      data: event,
    };
    console.log(JSON.stringify(info, null, 4));
  });
}

main();
