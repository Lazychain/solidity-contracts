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

		// mint 4 NFTs, will be used for differents probabilities chances
		for (let i = 0; i < 4; i++) {
			await nftContract.connect(owner).safeMint(owner.address)
		}
		const total_supply = await nftContract.totalSupply()
		expect(total_supply).to.be.equal(4)

		const lotteryInitParams = [
			mockFairyRingContract.target,
			fees,
			factor,
			mockFairyRingContract.target,
			nftContract,
		]
		lotteryContract = (await ethers.deployContract("NFTLottery", lotteryInitParams, owner)) as NFTLottery

		// Give permissiont to nftContract to Transfer Ownership
		const result: ContractTransactionResponse = await nftContract
			.connect(owner)
			.setApprovalForAll(lotteryContract, true)
		await result.wait()
		const check = await nftContract.connect(owner).isApprovedForAll(owner, lotteryContract)
		expect(check).to.be.equal(true)

		// Transfer all
		for (let i = 0; i < 4; i++) {
			await nftContract.transferFrom(owner, lotteryContract, i)
		}
	})

	describe("Deployment", () => {
		it("Should be the right owner", async () => {
			const lottery_owner = await lotteryContract.connect(owner).owner()
			expect(lottery_owner).to.equal(owner.address)
		})

		it("Should start with zero total_draws", async () => {
			const total_draws = await lotteryContract.connect(owner).totaldraws()
			expect(total_draws).to.equal(0)
		})

		it("Should start campaign paused", async () => {
			const campaign = await lotteryContract.connect(owner).campaign()
			expect(campaign).to.equal(true)
		})

		it("Should only allow owner claim()", async () => {
			await expect(await lotteryContract.connect(owner).claim()).to.be.not.reverted
		})

		it("Should not allow anyone claim()", async () => {
			await expect(lotteryContract.connect(hacker).claim()).to.be.reverted
		})

		it("Should not allow anyone claimNFT() if has not enough points", async () => {
			// Start campaign
			await lotteryContract.connect(owner).startCampaign()
			const campaign = await lotteryContract.campaign()
			expect(campaign).to.equal(false)

			// hacker try to claimNFT
			await expect(lotteryContract.connect(hacker).claimNFT({ value: 1000 })).to.be.reverted
		})

		it("Should not allow anyone claimNFT() if not send funds", async () => {
			// Start campaign
			await lotteryContract.connect(owner).startCampaign()
			const campaign = await lotteryContract.campaign()
			expect(campaign).to.equal(false)

			// 100 draws always failing
			const random = new Uint256("20")
			const guessNumber = new Uint256("19")
			await mockFairyRingContract.mock.latestRandomness.returns(random.toBytes().val, random.val)
			// draws here to get to 100 points
			for (let i = 0; i < 100; i++) {
				const result = await lotteryContract.connect(user1).draw(guessNumber.val, { value: 1000 })
				const transactionReceipt = (await result.wait())!
				expect(transactionReceipt?.status).to.equal(1)
			}

			// user claimNFT() but no funds sends
			await expect(lotteryContract.connect(user1).claimNFT()).to.be.reverted
		})

		it("Should allow anyone claimNFT() with funds and 100 points", async () => {
			// Start campaign
			await lotteryContract.connect(owner).startCampaign()
			const campaign = await lotteryContract.campaign()
			expect(campaign).to.equal(false)

			// 100 draws always failing
			const random = new Uint256("20")
			const guessNumber = new Uint256("19")
			await mockFairyRingContract.mock.latestRandomness.returns(random.toBytes().val, random.val)
			// draws here to get to 100 points
			for (let i = 0; i < 100; i++) {
				const result = await lotteryContract.connect(user1).draw(guessNumber.val, { value: 1000 })
				const transactionReceipt = (await result.wait())!

				// should succeed
				expect(transactionReceipt?.status).to.equal(1)

				// the user should have failed ( 20 != 19)
				const resultEvents = (
					await lotteryContract.connect(user1).queryFilter(lotteryContract.filters.LotteryDrawn)
				)[0].args
				expect(resultEvents[1]).to.be.equal(false)

				// Total Draws should be equal to i
				const total_draws = await lotteryContract.connect(user1).totaldraws()
				expect(total_draws).to.equal(i + 1)

				// User points should be equal to i
				const points = await lotteryContract.connect(user1).points()
				expect(points).to.equal(i + 1)
			}

			// user claimNFT()
			const points = await lotteryContract.connect(user1).points()
			expect(points).to.equal(100)
			await expect(lotteryContract.connect(user1).claimNFT({ value: 1000 })).to.not.be.reverted

			// try to claim again you cheater
			await expect(lotteryContract.connect(user1).claimNFT({ value: 1000 })).to.be.reverted
		})
	})

	describe("Draw", function () {
		it("Player draw successful", async function () {
			// Given a started campaign
			let result: ContractTransactionResponse = await lotteryContract.connect(owner).startCampaign()

			// and a randomness contract that return 20 as random number
			const random = new Uint256("20")
			await mockFairyRingContract.mock.latestRandomness.returns(random.toBytes().val, random.val)

			// When a player draw give a 20 as random number
			const guessNumber = new Uint256("20")
			const funds = 1000
			result = await lotteryContract.connect(user1).draw(guessNumber.val, { value: funds })
			const transactionReceipt = (await result.wait())!
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

			// and a randomness contract that return 20 as random number
			const random = new Uint256("20")
			await mockFairyRingContract.mock.latestRandomness.returns(random.toBytes().val, random.val)

			// When a player draw give a 19 as random number
			const guessNumber = new Uint256("19")
			const funds = 1000
			result = await lotteryContract.connect(user1).draw(guessNumber.val, { value: funds })
			const transactionReceipt = (await result.wait())!
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
})
