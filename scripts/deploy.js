// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  const Bridge = await hre.ethers.getContractFactory("Bridge");
  const bridge = await Bridge.deploy(
    "0xe580074A10360404AF3ABfe2d524D5806D993ea3",
    "1000000000000000000000",
    "1",
    "100000000000000000",
    "137",
    "10000000000000000");
  await bridge.deployed();
  console.log("Bridge deployed to:", bridge.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
