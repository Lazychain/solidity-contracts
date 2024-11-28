import hre from "hardhat";
import "@nomicfoundation/hardhat-ignition-ethers";
async function main() {
  const [admin] = await hre.ethers.getSigners();

  /**
   * Deploy Lottery contract
   */
  const lotteryContract = await hre.ethers.deployContract("Lottery", [], {
    signer: admin,
  });
  const lotteryAddress = await lotteryContract.getAddress();

  console.log(`Contract Lottery deployed to: ${lotteryAddress}`);
}

main().catch(console.error);
