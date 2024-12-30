// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import { Script } from "forge-std/Script.sol";
import { NFTLottery } from "../contracts/apps/lottery.sol";
import { Lazy1155 } from "../contracts/apps/lazy1155.sol";
import { IFairyringContract } from "../lib/FairyringContract/src/IFairyringContract.sol";
import { IERC1155Receiver } from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import { IERC165, ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "hardhat/console.sol";

contract Deploy is Script, ERC165, IERC1155Receiver {
    function run(
        uint256 _Lazy1155_tokensIdCap, // 5
        string calldata _Lazy1155_uri, // "ipfs://hash/{id}.json"
        uint256 _NFTLottery_fee, // 0.01 ether
        address _Fairblock_fairyring // Address
    ) external {
        uint256 deployerPrivateKey = vm.envUint("ANVIL_PK");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Start Lottery Deploy Script");
        console.log("---------------------");
        console.log("Deployer: [%s]", deployer);
        console.log("ERC1155: Token Types [%s] IPFS[%s]", _Lazy1155_tokensIdCap, _Lazy1155_uri);
        console.log("Fairblock: Fairyring[%s]", _Fairblock_fairyring);
        console.log("Lottery: fees[%s]", _NFTLottery_fee);
        console.log("---------------------");
        vm.startBroadcast(deployerPrivateKey);

        console.log("1- Deploying and init Lazy1155 Token");
        // NFT Contructors 2^tokensIdCap ERC1155
        uint256[] memory ids = new uint256[](_Lazy1155_tokensIdCap);
        uint256[] memory amounts = new uint256[](_Lazy1155_tokensIdCap);
        uint256 totalEmittion = 0;

        uint256 quantity = 1;
        for (uint256 tokenId = 0; tokenId < _Lazy1155_tokensIdCap; tokenId++) {
            ids[tokenId] = tokenId;
            amounts[tokenId] = quantity;
            totalEmittion += quantity;
            quantity *= 2;
        }
        Lazy1155 _nft1155 = new Lazy1155(totalEmittion, _Lazy1155_uri);

        console.log("2- Minting Lazy1155 Token");
        // Mint Tokens
        _nft1155.mintBatch(deployer, ids, amounts, "");

        console.log("3- Setting Fairblock Contracts");
        // Random Fairblock contracts
        IFairyringContract _fairyringContract = IFairyringContract(address(_Fairblock_fairyring));

        console.log("4- Deploying and init LazyLottery");
        // Construct Lottery
        NFTLottery _lottery = new NFTLottery(
            address(_nft1155),
            _NFTLottery_fee,
            address(_fairyringContract)
        );

        console.log("5- Transfering Lazy1155 ids  ownership to LazyLottery");
        // Set approval for all NFTs to Loterry as `Operator`
        _nft1155.setApprovalForAll(address(_lottery), true);

        // transfer ownership of all NFT tokens to lottery contract
        _nft1155.safeBatchTransferFrom(deployer, address(_lottery), ids, amounts, "");

        console.log("6- LazyLottery start campaign");
        _lottery.setCampaign(true);

        console.log("---------------------");
        console.log("ERC1155: addr[%s] owner[%s]", address(_nft1155), _nft1155.owner());
        console.log("Fairblock: Fairyring[%s]", _Fairblock_fairyring);
        console.log(
            "Lottery: addr[%s] NFTs[%s] owner[%s]",
            address(_lottery),
            _nft1155.totalSupply(),
            _lottery.owner()
        );
        console.log("---------------------");
        vm.stopBroadcast();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) public virtual override returns (bytes4) {
        console.log("Received ERC1155: ");
        console.log("Operator [%s]:", operator);
        console.log("From: [%s]", from);
        console.log("ID: [%s]", id);
        console.log("Value: [%s]", value);
        console.logBytes(data);
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) public virtual override returns (bytes4) {
        console.log("Received ERC1155 Batch:");
        console.log("Operator:", operator);
        console.log("From:", from);
        for (uint256 i = 0; i < ids.length; i++) {
            console.log("ID:", ids[i]);
            console.log("Value:", values[i]);
        }
        console.logBytes(data);
        return this.onERC1155BatchReceived.selector;
    }
}
