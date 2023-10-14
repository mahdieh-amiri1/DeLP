// const { network } = require("hardhat")
// const { verify } = require("../utils/verify")

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments
  const { deployer } = await getNamedAccounts()
  await deploy("DeLT", {
    contract: "DeLT",
    from: deployer,
    log: true,
  })

  const delt = await deployments.get("DeLT")
  const courseManagement = await deploy("CourseManagement", {
    from: deployer,
    args: [delt.address],
    log: true,
  })

  log("Contracts deployed")

  // if (network.name == "sepolia") {
  //   await verify(delt.address, [])
  //   await verify(courseManagement.address, [delt.address])
  // }
}
