// import { HardhatUserConfig } from "hardhat/config";
// import "@nomicfoundation/hardhat-toolbox";
// import "@nomicfoundation/hardhat-ignition-ethers";
// // import "solidity-docgen"
// // import "@nomicfoundation/hardhat-toolbox"
// // import "@nomicfoundation/hardhat-ignition-ethers"
// // import "@nomiclabs/hardhat-ethers"
// // import "@typechain/hardhat"
// // import "hardhat-gas-reporter"
// // import "solidity-coverage"
// // 
// // import "@nomicfoundation/hardhat-toolbox"

// // import "hardhat-deploy"
// // import "@nomiclabs/hardhat-solhint"
// // import "hardhat-deploy"
// // import "solidity-coverage"

// // import "dotenv/config"

// import "./tasks/utils/accounts"
// import "./tasks/utils/balance"
// import "./tasks/utils/block-number"

// const config: HardhatUserConfig = {
// 	defaultNetwork: "hardhat",
// 	solidity: {
// 		version: "0.8.24",
// 		settings: {
// 			outputSelection: {
// 				"*": {
// 					"*": ["storageLayout"],
// 				},
// 			},
// 			optimizer: {
// 				enabled: true,
// 				runs: 200,
// 			},
// 		},
// 	},
// 	paths: {
// 		sources: "./contracts",
// 		artifacts: "./build",
// 	},
// 	gasReporter: {
// 		currency: "USD",
// 	},
// 	typechain: {
// 		outDir: "./typechain-types",
// 		target: "ethers-v5",
// 		alwaysGenerateOverloads: true,
// 		node16Modules: true,
// 	},
// 	mocha: {
// 		bail: true,
// 	},
// 	// docgen: {
// 	// 	pages: "files",
// 	// 	outputDir: "docs/gen",
// 	// 	templates: "docs/templates",
// 	// },
// 	ignition: {
// 		blockPollingInterval: 1_000,
// 		timeBeforeBumpingFees: 3 * 60 * 1_000,
// 		maxFeeBumps: 4,
// 		requiredConfirmations: 5,
// 		disableFeeBumping: false,
// 	},
// 	networks: {
// 		hardhat: {
// 			chainId: 1337,
// 		},
// 		lazy: {
// 			url: "http://127.0.0.1:8545",
// 		},
// 	},
// }

// export default config

import { HardhatUserConfig } from "hardhat/config"
import "@nomicfoundation/hardhat-toolbox"
import "@nomicfoundation/hardhat-ignition-ethers"

const config: HardhatUserConfig = {
	solidity: {
		version: "0.8.27",
		settings: {
			optimizer: {
				enabled: true,
				runs: 100,
			},
			viaIR: true,
		},
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

export default config
