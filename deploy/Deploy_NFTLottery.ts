import { DeployFunction, DeployResult } from "hardhat-deploy/types"
import { HardhatRuntimeEnvironment } from "hardhat/types"

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
	const { deployer, owner } = await hre.getNamedAccounts()

	const fairyRing = "MockFairyRing"
	const lottery = "NFTLottery"

	const fairyRingContract: DeployResult = await hre.deployments.deploy(fairyRing, {
		from: deployer,
		args: [],
		log: true,
	})

	console.log(JSON.stringify(fairyRingContract.address, null, 2))

	const ERC721Contract: DeployResult = await hre.deployments.deploy("ERC721", {
		from: deployer,
		args: ["Lazy", "LZ", "ipfs://base-uri/", "ipfs://contract-uri", owner],
		log: true,
	})

	console.log(JSON.stringify(ERC721Contract.address, null, 2))

	// uint256 _fee, address _fairyringContract, address _nftContract
	const lotteryContract: DeployResult = await hre.deployments.deploy(lottery, {
		from: deployer,
		args: [fairyRingContract.address, 0.1, 20, fairyRingContract.address, ERC721Contract.address],
		log: true,
	})

	console.log(JSON.stringify(lotteryContract, null, 2))
}
export default func
func.tags = ["lottery"]
