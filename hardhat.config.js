require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-etherscan");
require("hardhat-deploy");
require("hardhat-gas-reporter");
require("dotenv").config();

const GOERLI_RPC_URL = process.env.GOERLI_RPC_URL;
const GOERLI_CHAIN_ID = parseInt(process.env.GOERLI_CHAIN_ID);
const GOERLI_PRIVATE_KEY = process.env.GOERLI_PRIVATE_KEY;

const FTMTST_RPC_URL = process.env.FTMTST_RPC_URL;
const FTMTST_CHAIN_ID = parseInt(process.env.FTMTST_CHAIN_ID);
const FTMTST_PRIVATE_KEY = process.env.FTMTST_PRIVATE_KEY;

const AVAXTST_RPC_URL = process.env.AVAXTST_RPC_URL;
const AVAXTST_CHAIN_ID = parseInt(process.env.AVAXTST_CHAIN_ID);
const AVAXTST_PRIVATE_KEY = process.env.AVAXTST_PRIVATE_KEY;

const ETHERS_API_KEY = process.env.ETHERS_API_KEY;

console.log(AVAXTST_CHAIN_ID);
console.log(AVAXTST_RPC_URL);

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
    fantomtestnet: {
      url: FTMTST_RPC_URL,
      chainId: FTMTST_CHAIN_ID,
      accounts: [FTMTST_PRIVATE_KEY],
    },
    avaxtestnet: {
      url: AVAXTST_RPC_URL,
      chainId: AVAXTST_CHAIN_ID,
      gasPrice: 225000000000,
      accounts: [AVAXTST_PRIVATE_KEY],
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
