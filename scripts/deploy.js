const hre = require("hardhat");

async function main() {
  const delt = await hre.ethers.deployContract("DeLT")
  console.log(`DeLT deployed at ${delt.target}`)

  const courseManagement = await hre.ethers.deployContract("CourseManagement", [delt.target])
  console.log(`CourseManagement deployed at ${courseManagement.target}`)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
