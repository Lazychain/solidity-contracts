import { expect } from "chai"
import { ethers } from "hardhat"
import { NFTLottery, LazyNFT } from "typechain-types"
import MockFairyJson from "../../artifacts/contracts/apps/mocks/fairyring.sol/MockFairyRing.json"
import {deployMockContract, MockContract} from '@clrfund/waffle-mock-contract';
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { ContractTransactionResponse } from "ethers";
import { Bytes32, Uint256, Uint32, Address } from 'soltypes'

function getRandomNumber(factor: number) {
	return Math.random() % factor
}

describe("Lottery", async function () {
	let mockFairyRingContract: MockContract;
	let nftContract: LazyNFT;
	let lotteryContract: NFTLottery;

    let owner: SignerWithAddress;
    let user1: SignerWithAddress;
    let user2: SignerWithAddress;  
	let hacker: SignerWithAddress;
	const fees: number = 200
	const factor: number = 20
	const probability: number = 100 / factor

	beforeEach(async function () {
		[owner, user1, user2, hacker] = await ethers.getSigners();
		mockFairyRingContract = await deployMockContract(owner, MockFairyJson.abi);

		// Test TooFewNFTs
		const nftInitParams = [owner,"LazyNFT","LNT"];
		nftContract = (await ethers.deployContract("LazyNFT", nftInitParams, owner)) as LazyNFT;

		// mint 1 nft, but fail testing TooFewNFTs, maybe we need to move that check
		await nftContract.safeMint(owner.address);
		expect(await nftContract.ownerOf(0)).to.equal(owner.address);

		const lotteryInitParams = [mockFairyRingContract.target, fees, factor,mockFairyRingContract.target,nftContract.getAddress()];
		lotteryContract = (await ethers.deployContract("NFTLottery", lotteryInitParams, owner)) as NFTLottery;
 
	})

	describe("Deployment", () => {
		it("Should set the right owner", async () => {
		  expect(await lotteryContract.owner()).to.equal(owner.address);
		});
	
		it("Should start with zero total_draws", async () => {
		  expect(await lotteryContract.totaldraws()).to.equal(0);
		});

		it("Should start campaign paused", async () => {
			expect(await lotteryContract.campaign()).to.equal(true);
		  });
	  });

	describe("Draw", function () {
		it("Player draw successful", async function () {
			// Given a player name
			let result: ContractTransactionResponse = await lotteryContract.connect(user1).setPlayerName("pla.fun")
			let transactionReceipt = await result.wait(1);
			expect(transactionReceipt?.status).to.equal(1)

			// and a randomness contract that return 20 as random number
			mockFairyRingContract.mock.getLatestRandomness.returns(new Bytes32("0x20"));

			// When a player draw give a 20 as random number
			//result = await lotteryContract.connect(user1).draw(getRandomNumber(20))
			// transactionReceipt = await result.wait(1);
			// expect(transactionReceipt?.status).to.equal(1)
			// const expected = false

			// // Then since both user and random are the same
			// expect(await transactionReceipt).to.be.equal(expected)
		})

		// it("Player draw fail", async function () {
		// 	// Given a player name
		// 	await lotteryContract.connect(user1).setPlayerName("pla.fun")
		// 	// and a randomness contract that return 20 as random number
		// 	await mockFairyRingContract.mock.getLatestRandomness.returns(20);


		// 	// When a player draw give a 19 as random number
		// 	const result: ContractTransactionResponse = await lotteryContract.connect(user1).draw(getRandomNumber(19))
		// 	const expected = false

		// 	// Then since both user and random are different
		// 	expect(result).to.be.equal(expected)
		// })
	})

	describe("PlayersName", function () {
		// setPlayerName(string memory name)
		it("Player Name set should be with maximun 7 chars long utf8 with . allowed", async function () {
			// Given a player name
			const playerName = "pla.fun"

			// When a player set a valid nick
			let result: ContractTransactionResponse = await lotteryContract.connect(user1).setPlayerName(playerName)

			const transactionReceipt = await result.wait(1);
			// Then it should sucessfuly set.
			expect(transactionReceipt?.status).to.equal(1)
		})
		// getPlayerName(address player)
	})
})
