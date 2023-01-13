const { deployments, getNamedAccounts } = require("hardhat");

module.exports = async function (hre) {
  console.log("Deploying ChatSignalingMedium contract...");
  const namedAccs = await getNamedAccounts();
  const { deployer } = namedAccs;
  const contract = await deployments.deploy("ChatSignalingMedium", {
    from: deployer,
  });
  console.log(`Contract ChatSignalingMedium deployed at ${contract.address}`);
};

module.exports.tags = ["all", "ChatSignalingMedium"];
