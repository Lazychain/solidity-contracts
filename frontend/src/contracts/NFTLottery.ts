// jq '.abi' ./out/lottery.sol/NFTLottery.json

import { UseAccountReturnType, useReadContract, useWriteContract, UseWriteContractReturnType } from "wagmi";
import { readContract } from '@wagmi/core'
import { AbiItem } from "./Iabi";
import { config } from "@/wagmi";

const NFTlotteryAbi: AbiItem[] = [
  {
    type: "constructor",
    inputs: [
      {
        name: "_erc1155",
        type: "address",
        internalType: "address",
      },
      {
        name: "_fee",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "_fairyringContract",
        type: "address",
        internalType: "address",
      },
    ],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "campaign",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "bool",
        internalType: "bool",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "claimNFT",
    inputs: [],
    outputs: [
      {
        name: "nftId",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "payable",
  },
  {
    type: "function",
    name: "draw",
    inputs: [
      {
        name: "userGuess",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    outputs: [
      {
        name: "nftId",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "payable",
  },
  {
    type: "function",
    name: "fee",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "isCampaignOpen",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "bool",
        internalType: "bool",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "onERC1155BatchReceived",
    inputs: [
      {
        name: "",
        type: "address",
        internalType: "address",
      },
      {
        name: "",
        type: "address",
        internalType: "address",
      },
      {
        name: "",
        type: "uint256[]",
        internalType: "uint256[]",
      },
      {
        name: "",
        type: "uint256[]",
        internalType: "uint256[]",
      },
      {
        name: "",
        type: "bytes",
        internalType: "bytes",
      },
    ],
    outputs: [
      {
        name: "",
        type: "bytes4",
        internalType: "bytes4",
      },
    ],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "onERC1155Received",
    inputs: [
      {
        name: "",
        type: "address",
        internalType: "address",
      },
      {
        name: "",
        type: "address",
        internalType: "address",
      },
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "",
        type: "bytes",
        internalType: "bytes",
      },
    ],
    outputs: [
      {
        name: "",
        type: "bytes4",
        internalType: "bytes4",
      },
    ],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "owner",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "address",
        internalType: "address",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "owner_balance",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "points",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "renounceOwnership",
    inputs: [],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "setCampaign",
    inputs: [
      {
        name: "_isCampaignOpen",
        type: "bool",
        internalType: "bool",
      },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "supportsInterface",
    inputs: [
      {
        name: "interfaceId",
        type: "bytes4",
        internalType: "bytes4",
      },
    ],
    outputs: [
      {
        name: "",
        type: "bool",
        internalType: "bool",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "test",
    inputs: [
      {
        name: "pepe",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    outputs: [
      {
        name: "",
        type: "bool",
        internalType: "bool",
      },
    ],
    stateMutability: "payable",
  },
  {
    type: "function",
    name: "totalCollectionItems",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "totalDraws",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "totaldraws",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "transferOwnership",
    inputs: [
      {
        name: "newOwner",
        type: "address",
        internalType: "address",
      },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "version",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "string",
        internalType: "string",
      },
    ],
    stateMutability: "pure",
  },
  {
    type: "function",
    name: "withdraw",
    inputs: [
      {
        name: "to",
        type: "address",
        internalType: "address",
      },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "event",
    name: "CampaignStatusChanged",
    inputs: [
      {
        name: "status",
        type: "bool",
        indexed: false,
        internalType: "bool",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "LotteryDrawn",
    inputs: [
      {
        name: "player",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "result",
        type: "bool",
        indexed: false,
        internalType: "bool",
      },
      {
        name: "nftId",
        type: "uint256",
        indexed: false,
        internalType: "uint256",
      },
      {
        name: "totalDraws",
        type: "uint256",
        indexed: false,
        internalType: "uint256",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "LotteryInitialized",
    inputs: [
      {
        name: "fairyringContract",
        type: "address",
        indexed: false,
        internalType: "address",
      },
      {
        name: "fee",
        type: "uint256",
        indexed: false,
        internalType: "uint256",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "MintedNft",
    inputs: [
      {
        name: "player",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "nftId",
        type: "uint256",
        indexed: false,
        internalType: "uint256",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "OwnershipTransferred",
    inputs: [
      {
        name: "previousOwner",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "newOwner",
        type: "address",
        indexed: true,
        internalType: "address",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "RewardWithdrawn",
    inputs: [
      {
        name: "by",
        type: "address",
        indexed: false,
        internalType: "address",
      },
      {
        name: "amount",
        type: "uint256",
        indexed: false,
        internalType: "uint256",
      },
    ],
    anonymous: false,
  },
  {
    type: "error",
    name: "AddressEmptyCode",
    inputs: [
      {
        name: "target",
        type: "address",
        internalType: "address",
      },
    ],
  },
  {
    type: "error",
    name: "NFTLottery__CampaignOver",
    inputs: [],
  },
  {
    type: "error",
    name: "NFTLottery__DoesNotSupportTotalSupply",
    inputs: [],
  },
  {
    type: "error",
    name: "NFTLottery__GuessValueOutOfRange",
    inputs: [],
  },
  {
    type: "error",
    name: "NFTLottery__InsufficientFundsSent",
    inputs: [],
  },
  {
    type: "error",
    name: "NFTLottery__InternalError",
    inputs: [
      {
        name: "message",
        type: "string",
        internalType: "string",
      },
    ],
  },
  {
    type: "error",
    name: "NFTLottery__NFTContractDoesNotSupportTotalSupply",
    inputs: [],
  },
  {
    type: "error",
    name: "NFTLottery__OnlyOwnerCanWithdraw",
    inputs: [],
  },
  {
    type: "error",
    name: "NFTLottery__TooFewNFTs",
    inputs: [
      {
        name: "message",
        type: "string",
        internalType: "string",
      },
    ],
  },
  {
    type: "error",
    name: "NFTLottery__TooFewPooPoints",
    inputs: [],
  },
  {
    type: "error",
    name: "OwnableInvalidOwner",
    inputs: [
      {
        name: "owner",
        type: "address",
        internalType: "address",
      },
    ],
  },
  {
    type: "error",
    name: "OwnableUnauthorizedAccount",
    inputs: [
      {
        name: "account",
        type: "address",
        internalType: "address",
      },
    ],
  },
] as const;

export class NFTlottery {
  address: `0x${string}`;
  abi: AbiItem[];
  account: UseAccountReturnType;
  execute: UseWriteContractReturnType;

  constructor(account: UseAccountReturnType) {
    this.abi = NFTlotteryAbi;
    this.account = account;
    switch (import.meta.env.VITE_PUBLIC_NETWORK) {
      case "forma":
        if (import.meta.env.VITE_FORMA_LOTTERY_ADDRESS === undefined)
          throw new Error(
            "VITE_FORMA_LOTTERY_ADDRESS .env property not defined."
          );
        this.address = import.meta.env
          .VITE_FORMA_LOTTERY_ADDRESS as `0x${string}`;
        break;
      case "sketchpad":
        if (import.meta.env.VITE_SKETPATCH_LOTTERY_ADDRESS === undefined)
          throw new Error(
            "VITE_SKETPATCH_LOTTERY_ADDRESS .env property not defined."
          );
        this.address = import.meta.env
          .VITE_SKETPATCH_LOTTERY_ADDRESS as `0x${string}`;
        break;
      case "anvil":
        if (import.meta.env.VITE_ANVIL_LOTTERY_ADDRESS === undefined)
          throw new Error(
            "VITE_ANVIL_LOTTERY_ADDRESS .env property not defined."
          );
        this.address = import.meta.env
          .VITE_ANVIL_LOTTERY_ADDRESS as `0x${string}`;
        break;
      default:
        throw new Error("Public Network .env property not defined.");
    }
    this.execute = useWriteContract({
      mutation: {
        onSuccess: () => {},
      },
    });
  }

  getExecuteFuntions() {
    return this.abi.filter(
      (item) => item.type === "function" && item.stateMutability === "payable"
    );
  }

  getViewFuntions() {
    return this.abi.filter(
      (item) => item.type === "function" && item.stateMutability === "view"
    );
  }

  version() {
    return useReadContract({
      address: this.address,
      abi: this.abi,
      functionName: "version",
      account: this.account.address,
      query: {
        enabled: this.account.isConnected,
      },
    });
  }

  isCampaignOpen() {
    const { data: isCampaignOpen } = useReadContract({
      address: this.address,
      abi: this.abi,
      functionName: "isCampaignOpen",
      account: this.account.address,
      args: [],
      query: {
        enabled: this.account.isConnected,
      },
    });
    return isCampaignOpen;
  }

  isFee() {
    const { data: isFee } = useReadContract({
      address: this.address,
      abi: this.abi,
      functionName: "fee",
      account: this.account.address,
      args: [],
      query: {
        enabled: this.account.isConnected,
      },
    });
    return isFee;
  }

  async isTotalDraws() {
    const data = await readContract(config, {
      abi: this.abi,
      address: this.address,
      functionName: 'totalDraws',
      account: this.account.address
    })
    return data;
  }

  async isPoints() {
    const data = await readContract(config, {
      abi: this.abi,
      address: this.address,
      functionName: 'points',
      account: this.account.address
    })
    return data;
  }

  OwnerBalance() {
    return useReadContract({
      address: this.address,
      abi: this.abi,
      functionName: "owner_balance",
      account: this.account.address,
      args: [],
      query: {
        enabled: this.account.isConnected,
      },
    });
  }

  totalSupply() {
    return useReadContract({
      address: this.address,
      abi: this.abi,
      functionName: "totalSupply",
      account: this.account.address,
      args: [],
      query: {
        enabled: this.account.isConnected,
      },
    });
  }

  execute_function(
    functionName: string,
    account: UseAccountReturnType,
    args: string[],
    value: bigint
  ) {
    this.execute.writeContract(
      {
        address: this.address,
        abi: this.abi,
        functionName,
        account: account.address,
        args,
        value,
      },
      {
        onError: (error) => {
          console.error(error.message);
        },
      }
    );
  }
}
