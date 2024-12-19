import { expect } from "chai"
import { ethers } from "hardhat"

import MockFairyJson from "../../artifacts/contracts/apps/mocks/fairyring.sol/MockFairyRing.json"
import { deployMockContract, MockContract } from "@clrfund/waffle-mock-contract"
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers"
import { ContractTransactionResponse } from "ethers"
import { Uint256 } from "soltypes"
import { Lazy1155, NFTLottery } from "typechain-types"

function getRandomIntModulo(max: number): Uint256 {
	// Get a large random number (e.g., using a cryptographically secure random number generator)
	const largeRandomNumber = crypto.getRandomValues(new Uint32Array(1))[0]
	const userNumber = largeRandomNumber % max

	return new Uint256(userNumber.toString())
}

describe("Lottery", async function () {
	let mockFairyRingContract: MockContract
	let lotteryContract: NFTLottery

	let owner: SignerWithAddress
	let user1: SignerWithAddress
	let hacker: SignerWithAddress
	const fees: number = 200
	const factor = 1
	const maxNftTypes = 4 // this should be the same as on lottery sol contract.
	const tokenId = 0
	const metadata = "0x" // BytesLike value

	beforeEach(async function () {
		;[owner, user1, hacker] = await ethers.getSigners()
		const nftList: Lazy1155[] = []
		const nftAddrs: string[] = []

		// const balance0ETH = await ethers.provider.getBalance(owner.address)

		mockFairyRingContract = await deployMockContract(owner, MockFairyJson.abi)

		// Test TooFewNFTs
		for (let i = 0, quantity = 1 * factor; i < maxNftTypes; i++) {
			// Init NFT
			const nftInitParams = [quantity, "ipfs://hash/{id}.json", 0]
			const nftContract = (await ethers.deployContract("Lazy1155", nftInitParams, owner)) as Lazy1155

			// Mint quantity tokens
			await nftContract.connect(owner).mint(owner, tokenId, quantity, metadata)
			const total_supply = await nftContract["totalSupply(uint256)"](tokenId)
			expect(total_supply).to.be.equal(quantity)

			nftList.push(nftContract)
			nftAddrs.push(await nftContract.getAddress())
			quantity *= 2
		}

		// Init NFTLottery
		const lotteryInitParams = [nftAddrs, fees, mockFairyRingContract.target, mockFairyRingContract.target]
		lotteryContract = (await ethers.deployContract("NFTLottery", lotteryInitParams, owner)) as NFTLottery

		for (let i = 0; i < nftList.length; i++) {
			// Give permission to nftContract to Transfer Ownership
			const nft = nftList[i]
			const result: ContractTransactionResponse = await nft
				.connect(owner)
				.setApprovalForAll(lotteryContract, true)
			await result.wait()
			const check = await nft.connect(owner).isApprovedForAll(owner, lotteryContract)
			expect(check).to.be.equal(true)
		}

		for (let i = 0, quantity = 1 * factor; i < nftList.length; i++) {
			// Transfer all
			const nftContract = nftList[i]
			// const total_supply = await nftContract["totalSupply(uint256)"](tokenId)
			await nftContract.safeTransferFrom(owner, lotteryContract, tokenId, quantity, metadata)
			quantity *= 2
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

		it("Should start campaign not open", async () => {
			const campaign = await lotteryContract.connect(owner).campaign()
			expect(campaign).to.equal(false)
		})
	})

	describe("Owner", () => {
		it("Should only allow owner withdraw()", async () => {
			await expect(await lotteryContract.connect(owner).withdraw()).to.be.not.reverted
		})

		it("Should not allow anyone withdraw()", async () => {
			await expect(lotteryContract.connect(hacker).withdraw()).to.be.reverted
		})
	})

	describe("claimNFT", () => {
		it("Should not allow anyone claimNFT() if has not enough points", async () => {
			// Start campaign
			await lotteryContract.connect(owner).setCampaign(true)
			const campaign = await lotteryContract.campaign()
			expect(campaign).to.equal(true)
			// hacker try to claimNFT
			await expect(lotteryContract.connect(hacker).claimNFT({ value: 1000 })).to.be.reverted
		})
		it("Should not allow anyone claimNFT() if not send funds", async () => {
			// Start campaign
			await lotteryContract.connect(owner).setCampaign(true)
			const campaign = await lotteryContract.campaign()
			expect(campaign).to.equal(true)
			// 100 draws always failing
			const random = new Uint256("20")
			const guessNumber = new Uint256("0") // We ensure that is not in the range of 4 abs
			await mockFairyRingContract.mock.latestRandomness.returns(random.toBytes().val, random.val)
			// draws here to get to 100 points
			for (let i = 0; i < 100; i++) {
				const result = await lotteryContract.connect(user1).draw(guessNumber.val, { value: 1000 })
				const transactionReceipt = (await result.wait())!
				expect(transactionReceipt?.status).to.equal(1)
				const resultEvents = (await lotteryContract.queryFilter(lotteryContract.filters.LotteryDrawn))[0].args
				expect(resultEvents[1]).to.be.equal(false) // Ensure that the user fail
			}
			// user claimNFT() but no funds sends
			await expect(lotteryContract.connect(user1).claimNFT()).to.be.reverted
		})
		it("Should allow anyone claimNFT() with funds and 100 points", async () => {
			// Start campaign
			await lotteryContract.connect(owner).setCampaign(true)
			const campaign = await lotteryContract.campaign()
			expect(campaign).to.equal(true)
			// 100 draws always failing
			const random = new Uint256("20")
			const guessNumber = new Uint256("0") // ensure abs < 4
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
			// the user should have failed ( 20 != 19)
			const resultEvents = (
				await lotteryContract.connect(user1).queryFilter(lotteryContract.filters.MintedNft)
			)[0].args
			expect(resultEvents[0]).to.be.equal(user1.address)
			expect(resultEvents[1]).to.be.equal(0)
			// try to claim again you cheater
			await expect(lotteryContract.connect(user1).claimNFT({ value: 1000 })).to.be.reverted
		})
	})

	describe("Draw", function () {
		it("Player draw successful First Prize", async function () {
			// Given a started campaign
			let result: ContractTransactionResponse = await lotteryContract.connect(owner).setCampaign(true)
			// and a randomness contract that return 20 as random number
			const random = new Uint256("20")
			await mockFairyRingContract.mock.latestRandomness.returns(random.toBytes().val, random.val)
			// When a player draw give a 20 as random number, distance 20-20 = 0 -> nft type 1
			const guessNumber = new Uint256("20")
			const funds = 1000
			result = await lotteryContract.connect(user1).draw(guessNumber.val, { value: funds })
			const transactionReceipt = (await result.wait())!
			const resultEvents = (await lotteryContract.queryFilter(lotteryContract.filters.LotteryDrawn))[0].args
			// Then tx should succeed
			expect(transactionReceipt?.status).to.equal(1)
			// and since both user and random are range 1, must minted
			expect(resultEvents[1]).to.be.equal(true)
			// and nftId should be Case 1
			expect(resultEvents[2]).to.be.equal(0)
			// and total draws equals 1
			expect(resultEvents[3]).to.be.equal(1)
		})
		it("Player draw successful All Prizes", async function () {
			// Given a started campaign
			let result: ContractTransactionResponse = await lotteryContract.connect(owner).setCampaign(true)
			// and a randomness contract that return 20 as random number
			const random = new Uint256("20")
			await mockFairyRingContract.mock.latestRandomness.returns(random.toBytes().val, random.val)
			let expectedTokenId = 0
			let expectedTotalDraws = 0
			let txIndex = 0
			// When a player draw give a 20 as random number
			const guessNumber = new Uint256("20")
			const funds = 1000
			result = await lotteryContract.connect(user1).draw(guessNumber.val, { value: funds })
			expectedTotalDraws++
			let transactionReceipt = (await result.wait())!
			let resultEvents = (await lotteryContract.queryFilter(lotteryContract.filters.LotteryDrawn))[txIndex].args
			// Then tx should succeed
			expect(transactionReceipt?.status).to.equal(1)
			// and since both user and random are range 1, must minted
			expect(resultEvents[1]).to.be.equal(true)
			// and nftId should be Case 1
			expect(resultEvents[2]).to.be.equal(expectedTokenId)
			// and total draws
			expect(resultEvents[3]).to.be.equal(expectedTotalDraws)
			// Now try again, we should win Case2
			expectedTokenId = 0
			for (let i = 0; i < 2; i++) {
				result = await lotteryContract.connect(user1).draw(guessNumber.val, { value: funds })
				expectedTotalDraws++
				txIndex++
				transactionReceipt = (await result.wait())!
				resultEvents = (await lotteryContract.queryFilter(lotteryContract.filters.LotteryDrawn))[txIndex].args
				// Then tx should succeed
				expect(transactionReceipt?.status).to.equal(1)
				// and since both user and random are same, but no Case 1, case 2 must minted
				expect(resultEvents[1]).to.be.equal(true)
				// and nftId should be Case 2
				expect(resultEvents[2]).to.be.equal(expectedTokenId)
				// expectedTokenId = expectedTokenId + 1
				// and total draws
				expect(resultEvents[3]).to.be.equal(expectedTotalDraws)
			}
			// Now try again, we should win Case3
			expectedTokenId = 0
			for (let i = 0; i < 4; i++) {
				result = await lotteryContract.connect(user1).draw(guessNumber.val, { value: funds })
				expectedTotalDraws++
				txIndex++
				transactionReceipt = (await result.wait())!
				resultEvents = (await lotteryContract.queryFilter(lotteryContract.filters.LotteryDrawn))[txIndex].args
				// Then tx should succeed
				expect(transactionReceipt?.status).to.equal(1)
				// and since both user and random are same, but no Case 1, case 2 must minted
				expect(resultEvents[1]).to.be.equal(true)
				// and nftId should be Case 3
				expect(resultEvents[2]).to.be.equal(expectedTokenId)
				// expectedTokenId = expectedTokenId + 1
				// and total draws
				expect(resultEvents[3]).to.be.equal(expectedTotalDraws)
			}
			// Now try again, we should win Case4
			expectedTokenId = 0
			for (let i = 0; i < 8; i++) {
				result = await lotteryContract.connect(user1).draw(guessNumber.val, { value: funds })
				expectedTotalDraws++
				txIndex++
				transactionReceipt = (await result.wait())!
				resultEvents = (await lotteryContract.queryFilter(lotteryContract.filters.LotteryDrawn))[txIndex].args
				// Then tx should succeed
				expect(transactionReceipt?.status).to.equal(1)
				// and since both user and random are same, but no Case 1, case 2 must minted
				expect(resultEvents[1]).to.be.equal(true)
				// and nftId should be Case 3
				expect(resultEvents[2]).to.be.equal(expectedTokenId)
				// expectedTokenId = expectedTokenId + 1
				// and total draws
				expect(resultEvents[3]).to.be.equal(expectedTotalDraws)
			}
			// Now we own the collection, lets try one more claim
			await expect(lotteryContract.connect(user1).draw(guessNumber.val, { value: funds })).to.be.reverted
		})
		it("Player draw successful Second Prize", async function () {
			// Given a started campaign
			let result: ContractTransactionResponse = await lotteryContract.connect(owner).setCampaign(true)
			// and a randomness contract that return 20 as random number
			const random = new Uint256("20")
			await mockFairyRingContract.mock.latestRandomness.returns(random.toBytes().val, random.val)
			// When a player draw give a 19 as random number, distance 20-19 = 1 -> nft type 2
			const guessNumber = new Uint256("19")
			const funds = 1000
			result = await lotteryContract.connect(user1).draw(guessNumber.val, { value: funds })
			const transactionReceipt = (await result.wait())!
			const resultEvents = (await lotteryContract.queryFilter(lotteryContract.filters.LotteryDrawn))[0].args
			// Then tx should succeed
			expect(transactionReceipt?.status).to.equal(1)
			// and since both user and random are range 1, must minted
			expect(resultEvents[1]).to.be.equal(true)
			// and nftId should be Case 2
			expect(resultEvents[2]).to.be.equal(0)
			// and total draws equals 1
			expect(resultEvents[3]).to.be.equal(1)
		})
		it("Player draw successful Third Prize", async function () {
			// Given a started campaign
			let result: ContractTransactionResponse = await lotteryContract.connect(owner).setCampaign(true)
			// and a randomness contract that return 20 as random number
			const random = new Uint256("20")
			await mockFairyRingContract.mock.latestRandomness.returns(random.toBytes().val, random.val)
			// When a player draw give a 18 as random number, distance 20-18 = 2 -> nft type 3
			const guessNumber = new Uint256("18")
			const funds = 1000
			result = await lotteryContract.connect(user1).draw(guessNumber.val, { value: funds })
			const transactionReceipt = (await result.wait())!
			const resultEvents = (await lotteryContract.queryFilter(lotteryContract.filters.LotteryDrawn))[0].args
			// Then tx should succeed
			expect(transactionReceipt?.status).to.equal(1)
			// and since both user and random are range 1, must minted
			expect(resultEvents[1]).to.be.equal(true)
			// and nftId should be Case 3
			expect(resultEvents[2]).to.be.equal(0)
			// and total draws equals 1
			expect(resultEvents[3]).to.be.equal(1)
		})
		it("Player draw successful Four Prize", async function () {
			// Given a started campaign
			let result: ContractTransactionResponse = await lotteryContract.connect(owner).setCampaign(true)
			// and a randomness contract that return 20 as random number
			const random = new Uint256("20")
			await mockFairyRingContract.mock.latestRandomness.returns(random.toBytes().val, random.val)
			// When a player draw give a 17 as random number, distance 20 - 17 = 3 -> nft type 4
			const guessNumber = new Uint256("17")
			const funds = 1000
			result = await lotteryContract.connect(user1).draw(guessNumber.val, { value: funds })
			const transactionReceipt = (await result.wait())!
			// Then tx should succeed
			expect(transactionReceipt?.status).to.equal(1)
			const resultEvents = (await lotteryContract.queryFilter(lotteryContract.filters.LotteryDrawn))[0].args
			// and since both user and random are range 1, must minted
			expect(resultEvents[1]).to.be.equal(true)
			// and nftId should be 0
			expect(resultEvents[2]).to.be.equal(0)
			// and total draws equals 1
			expect(resultEvents[3]).to.be.equal(1)
		})
		it("Player draw fail", async function () {
			// Given a started campaign
			let result: ContractTransactionResponse = await lotteryContract.connect(owner).setCampaign(true)
			// and a randomness contract that return 20 as random number
			const random = new Uint256("20")
			await mockFairyRingContract.mock.latestRandomness.returns(random.toBytes().val, random.val)
			// When a player draw give a 19 as random number
			const guessNumber = new Uint256("19")
			const funds = 1000
			result = await lotteryContract.connect(user1).draw(guessNumber.val, { value: funds })
			const transactionReceipt = (await result.wait())!
			// Then tx should succeed
			expect(transactionReceipt?.status).to.equal(1)
			const resultEvents = (await lotteryContract.queryFilter(lotteryContract.filters.LotteryDrawn))[0].args
			const expected = true
			// and since both user and random are the same
			expect(resultEvents[1]).to.be.equal(expected)
			// and nftId should be be 0
			expect(resultEvents[2]).to.be.equal(0)
			// and totalDrwas should be be 1
			expect(resultEvents[3]).to.be.equal(1)
		})
	})
})
