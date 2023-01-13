require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-etherscan");
require("hardhat-deploy");
require("hardhat-gas-reporter");
require("dotenv").config();

const GOERLI_RPC_URL = process.env.GOERLI_RPC_URL;
const GOERLI_CHAIN_ID = parseInt(process.env.GOERLI_CHAIN_ID);
const GOERLI_PRIVATE_KEY = process.env.GOERLI_PRIVATE_KEY;
const ETHERS_API_KEY = process.env.ETHERS_API_KEY;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
  gasReporter: {
    enabled: true,
    noColors: true,
    outputFile: "gas-report.txt",
  },
  networks: {
    goerli: {
      url: GOERLI_RPC_URL,
      chainId: GOERLI_CHAIN_ID,
      accounts: [GOERLI_PRIVATE_KEY],
    },
    hhlocalhost: {
      url: "http://127.0.0.1:8545/",
      chainId: 31337,
    },
  },
  etherscan: {
    apiKey: ETHERS_API_KEY,
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
  },
};
