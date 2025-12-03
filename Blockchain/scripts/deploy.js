const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await hre.ethers.provider.getBalance(deployer.address)).toString());

  // Deploy NutriGuard contract
  const NutriGuard = await hre.ethers.getContractFactory("NutriGuard");
  const nutriGuard = await NutriGuard.deploy();

  await nutriGuard.waitForDeployment();

  console.log("NutriGuard contract deployed to:", await nutriGuard.getAddress());

  console.log("Contract with simplified roles (Merchant/Consumer) deployed successfully!");

  console.log("Deployment completed successfully!");

  // 保存合约地址到文件，供前端使用
  const fs = require('fs');
  const contractAddress = await nutriGuard.getAddress();
  const contractAddresses = {
    NutriGuard: contractAddress,
    network: hre.network.name,
    chainId: hre.network.config.chainId
  };

  fs.writeFileSync(
    '../nutri_guard/lib/config/contract_addresses.json',
    JSON.stringify(contractAddresses, null, 2)
  );

  console.log("Contract addresses saved to nutri_guard/lib/config/contract_addresses.json");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });


