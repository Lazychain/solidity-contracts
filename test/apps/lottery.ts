import { expect } from "chai"
import { ethers } from "hardhat"
import { NFTLottery, LazyNFT } from "typechain-types"
import MockFairyJson from "../../artifacts/contracts/apps/mocks/fairyring.sol/MockFairyRing.json"
import { deployMockContract, MockContract } from "@clrfund/waffle-mock-contract"
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers"
import { ContractTransactionReceipt, ContractTransactionResponse, EventLog, Log } from "ethers"
import { Bytes32, Uint256, Uint32, Address } from "soltypes"
import { Buffer } from "buffer"

function getRandomIntModulo(max: number): Uint256 {
	// Get a large random number (e.g., using a cryptographically secure random number generator)
	const largeRandomNumber = crypto.getRandomValues(new Uint32Array(1))[0]
	const userNumber = largeRandomNumber % max

	return new Uint256(userNumber.toString())
}

describe("Lottery", async function () {
	let mockFairyRingContract: MockContract
	let nftContract: LazyNFT
	let lotteryContract: NFTLottery

	let owner: SignerWithAddress
	let user1: SignerWithAddress
	let user2: SignerWithAddress
	let hacker: SignerWithAddress
	const fees: number = 200
	const factor: number = 20

	beforeEach(async function () {
		;[owner, user1, user2, hacker] = await ethers.getSigners()
		// const balance0ETH = await ethers.provider.getBalance(owner.address)

		mockFairyRingContract = await deployMockContract(owner, MockFairyJson.abi)

		// Test TooFewNFTs
		const nftInitParams = [owner, "LazyNFT", "LNT"]
		nftContract = (await ethers.deployContract("LazyNFT", nftInitParams, owner)) as LazyNFT

		// mint 1 nft, but fail testing TooFewNFTs, maybe we need to move that check
		await nftContract.safeMint(owner.address)
		expect(await nftContract.ownerOf(0)).to.equal(owner.address)

		const lotteryInitParams = [
			mockFairyRingContract.target,
			fees,
			factor,
			mockFairyRingContract.target,
			nftContract.getAddress(),
		]
		lotteryContract = (await ethers.deployContract("NFTLottery", lotteryInitParams, owner)) as NFTLottery
	})

	describe("Deployment", () => {
		it("Should set the right owner", async () => {
			expect(await lotteryContract.owner()).to.equal(owner.address)
		})

		it("Should start with zero total_draws", async () => {
			expect(await lotteryContract.totaldraws()).to.equal(0)
		})

		it("Should start campaign paused", async () => {
			expect(await lotteryContract.campaign()).to.equal(true)
		})
	})

	describe("Draw", function () {
		it("Player draw successful", async function () {
			// Given a started campaign
			let result: ContractTransactionResponse = await lotteryContract.connect(owner).startCampaign()

			// and player name
			result = await lotteryContract.connect(user1).setPlayerName("pla.fun")
			let transactionReceipt: ContractTransactionReceipt = (await result.wait(1))!
			expect(transactionReceipt?.status).to.equal(1)

			// and a randomness contract that return 20 as random number
			const random = new Uint256("20")
			await mockFairyRingContract.mock.latestRandomness.returns(random.toBytes().val, random.val)

			// When a player draw give a 20 as random number
			const guessNumber = new Uint256("20")
			const funds = 1000
			result = await lotteryContract.connect(user1).draw(guessNumber.val, { value: funds })
			transactionReceipt = (await result.wait())!
			const resultEvents = (await lotteryContract.queryFilter(lotteryContract.filters.LotteryDrawn))[0].args
			const expected = true

			// Then tx should succeed
			expect(transactionReceipt?.status).to.equal(1)

			// and totalDrwas must be 1
			expect(resultEvents[2]).to.be.equal(1)

			// and since both user and random are the same
			expect(resultEvents[1]).to.be.equal(expected)
		})

		it("Player draw fail", async function () {
			// Given a started campaign
			let result: ContractTransactionResponse = await lotteryContract.connect(owner).startCampaign()

			// and player name
			result = await lotteryContract.connect(user1).setPlayerName("pla.fun")
			let transactionReceipt: ContractTransactionReceipt = (await result.wait(1))!
			expect(transactionReceipt?.status).to.equal(1)

			// and a randomness contract that return 20 as random number
			const random = new Uint256("20")
			await mockFairyRingContract.mock.latestRandomness.returns(random.toBytes().val, random.val)

			// When a player draw give a 19 as random number
			const guessNumber = new Uint256("19")
			const funds = 1000
			result = await lotteryContract.connect(user1).draw(guessNumber.val, { value: funds })
			transactionReceipt = (await result.wait())!
			const resultEvents = (await lotteryContract.queryFilter(lotteryContract.filters.LotteryDrawn))[0].args
			const expected = false

			// Then tx should succeed
			expect(transactionReceipt?.status).to.equal(1)

			// and totalDrwas must be 1
			expect(resultEvents[2]).to.be.equal(1)

			// and since both user and random are the same
			expect(resultEvents[1]).to.be.equal(expected)
		})
	})

	describe("PlayersName", function () {
		// setPlayerName(string memory name)
		it("Player Name set should be with maximun 7 chars long utf8 with . allowed", async function () {
			// Given a player name
			const playerName = "pla.fun"

			// When a player set a valid nick
			const result: ContractTransactionResponse = await lotteryContract.connect(user1).setPlayerName(playerName)

			const transactionReceipt = await result.wait(1)
			// Then it should sucessfuly set.
			expect(transactionReceipt?.status).to.equal(1)
		})
		// getPlayerName(address player)
	})
})

