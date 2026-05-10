// Hardhat deploy script for RWAToken
// Usage: npx hardhat run scripts/deploy.js --network sepolia

const hre = require("hardhat");

async function main() {
  console.log("🚀 Deploying RWAToken...\n");

  // Get deployer
  const [deployer] = await hre.ethers.getSigners();
  console.log(`📡 Deploying from: ${deployer.address}`);
  
  const balance = await hre.ethers.provider.getBalance(deployer.address);
  console.log(`💰 Balance: ${hre.ethers.formatEther(balance)} ETH\n`);

  // Deploy implementation
  console.log("📄 Deploying implementation...");
  const RWAToken = await hre.ethers.getContractFactory("RWAToken");
  const implementation = await RWAToken.deploy();
  await implementation.waitForDeployment();
  console.log(`✅ Implementation: ${await implementation.getAddress()}\n`);

  // Deploy proxy
  console.log("📄 Deploying proxy...");
  const initializeData = RWAToken.interface.encodeFunctionData("initialize", [
    "US Treasury Bond Fund",           // name
    "USTB",                            // symbol
    "US Treasury Bond Fund Series 1",  // assetName
    "Treasury",                        // assetType
    deployer.address                   // issuer
  ]);

  const ERC1967Proxy = await hre.ethers.getContractFactory("ERC1967Proxy");
  const proxy = await ERC1967Proxy.deploy(
    await implementation.getAddress(),
    initializeData
  );
  await proxy.waitForDeployment();
  console.log(`✅ Proxy: ${await proxy.getAddress()}\n`);

  // Verify
  console.log("🔍 Verifying...");
  const token = await hre.ethers.getContractAt("RWAToken", await proxy.getAddress());
  
  console.log(`   Name: ${await token.name()}`);
  console.log(`   Symbol: ${await token.symbol()}`);
  console.log(`   Asset: ${await token.assetName()}`);
  console.log(`   Type: ${await token.assetType()}`);
  console.log(`   Issuer: ${await token.hasRole(await token.ISSUER_ROLE(), deployer.address)}`);

  console.log("\n✅ Deployment complete!");
  console.log(`\n📝 Save these addresses:`);
  console.log(`   IMPLEMENTATION=${await implementation.getAddress()}`);
  console.log(`   PROXY=${await proxy.getAddress()}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
