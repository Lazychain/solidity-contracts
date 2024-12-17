// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { INFTLotteryFactory } from "./lotteryinterface.sol";
import { ERC721Handler, ERC1155Handler } from "./lotteryTokens.sol";
import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract NFTLotteryFactory is INFTLotteryFactory {
    enum NFTStandards {
        ERC721,
        ERC1155
    }

    mapping(address => NFTStandards) public lotteryTypes;

    event LotteryCreated(address contractAddress, NFTStandards nftStandards);

    error NFTLotteryFactory__UnsupportedNFTStandards();

    function createLottery(
        address nftContract,
        address decrypter,
        uint256 fee,
        uint8 threshold,
        address fairyring
    ) public {
        bool isERC721 = _supportsInterface(nftContract, type(IERC721).interfaceId);
        bool isERC1155 = _supportsInterface(nftContract, type(IERC1155).interfaceId);

        address nftHandler;
        NFTStandards standard;

        if (isERC721) {
            nftHandler = address(new ERC721Handler(nftContract));
            standard = NFTStandards.ERC721;
        } else if (isERC1155) {
            nftHandler = address(new ERC1155Handler(nftContract, 1, 1000)); // Example....
            standard = NFTStandards.ERC1155;
        } else {
            revert("Unsupported NFT standards");
        }
    }

    function _supportsInterface(address contractAddress, bytes4 interfaceId) internal view returns (bool) {
        try IERC165(contractAddress).supportsInterface(interfaceId) returns (bool supported) {
            return supported;
        } catch {
            return false;
        }
    }
}
