import { time, loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers"
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs"
import { ethers } from "hardhat"
import FairyRingAbi from "../mocks/fairyringContract.json"
import Lottery from "../../build/contracts/apps/lottery.sol/NFTLottery.json"
import { Contract } from "ethers"
import { expect } from "chai"

function getRandomNumber(factor: number) {
	return Math.random() % factor
}

describe("Deployment", function () {
	// TODO: Do test constructor params
	// constructor(address _decrypter, uint256 _fee, uint8 _threshold, address _fairyringContract, address _nftContract)
})

describe("Lottery", async function () {
	const [owner, user1] = new MockProvider().getWallets()
	let fairyRingContract: MockContract
	let lotteryContract: Contract
	const fees: number = 200
	const factor: number = 20
	const probability: number = 100 / factor

	beforeEach(async function () {
		fairyRingContract = await deployMockContract(owner, FairyRingAbi)

		// Setting probability
		await fairyRingContract.mock.latestRandomness.returns(getRandomNumber(factor))

		lotteryContract = await deployContract(owner, Lottery, [fairyRingContract.address])
	})

	describe("Draw", function () {
		it("Player draw successful", async function () {
			// Given a player name
			await lotteryContract.connect(user1).setPlayerName("player.fun")
			// and a randomness contract that return 20 as random number
			await fairyRingContract.mock.latestRandomness.returns(20)

			// When a player draw give a 20 as random number
			await lotteryContract.connect(user1).draw(getRandomNumber(20))

			// Then since both user and random are the same
			expect(await lotteryContract.check()).to.be.equal(true)
		})

		it("Player draw fail", async function () {
			// Given a player name
			await lotteryContract.connect(user1).setPlayerName("player.fun")
			// and a randomness contract that return 20 as random number
			await fairyRingContract.mock.latestRandomness.returns(20)

			// When a player draw give a 19 as random number
			const result = await lotteryContract.connect(user1).draw(getRandomNumber(19))
			const expected = false

			// Then since both user and random are different
			expect(result).to.be.equal(expected)
		})
	})

	describe("PlayersName", function () {
		// setPlayerName(string memory name)
		it("Player Name set should be with maximun 7 chars long utf8 with . allowed", async function () {
			// Given a player name
			const playerName = "player.fun"

			// When a player set a valid nick
			let result = await lotteryContract.connect(user1).setPlayerName(playerName)

			// Then it should sucessfuly set.
			expect(result).to.be.undefined
		})
		// getPlayerName(address player)
	})
})
