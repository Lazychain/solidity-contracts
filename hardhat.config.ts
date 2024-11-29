// import type { HardhatUserConfig } from "hardhat/config";
// import "@nomicfoundation/hardhat-toolbox-viem";

// const config: HardhatUserConfig = {
//   solidity: "0.8.27",
// };

// export default config;

import "@nomiclabs/hardhat-ethers"
import "@typechain/hardhat"
import "hardhat-gas-reporter"
import "solidity-coverage"
import "solidity-docgen"
import "@nomicfoundation/hardhat-toolbox"

import "hardhat-deploy"
import "@nomiclabs/hardhat-solhint"
import "hardhat-deploy"
import "solidity-coverage"

import "dotenv/config"

import "./tasks/utils/accounts"
import "./tasks/utils/balance"
import "./tasks/utils/block-number"

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
	defaultNetwork: "hardhat",
	solidity: {
		version: "0.8.24",
		settings: {
			outputSelection: {
				"*": {
					"*": ["storageLayout"],
				},
			},
			optimizer: {
				enabled: true,
				runs: 200,
			},
		},
	},
	paths: {
		sources: "./contracts",
		artifacts: "./build",
	},
	gasReporter: {
		currency: "USD",
	},
	typechain: {
		outDir: "./types",
		target: "ethers-v5",
		alwaysGenerateOverloads: true,
		node16Modules: true,
	},
	mocha: {
		bail: true,
		import: "tsx",
	},
	docgen: {
		pages: "files",
		outputDir: "docs/gen",
		templates: "docs/templates",
	},
	ignition: {
		blockPollingInterval: 1_000,
		timeBeforeBumpingFees: 3 * 60 * 1_000,
		maxFeeBumps: 4,
		requiredConfirmations: 5,
		disableFeeBumping: false,
	},
	networks: {
		hardhat: {
			chainId: 1337,
		},
		lazy: {
			url: "http://127.0.0.1:8545",
		},
	},
}
