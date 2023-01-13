require("dotenv").config();

const GOERLI_CHAIN_ID = parseInt(process.env.GOERLI_CHAIN_ID);

networksByChainId = {
  [GOERLI_CHAIN_ID]: {
    name: "goerli",
  },
};

const developmentChains = {"hh-localhost"};
