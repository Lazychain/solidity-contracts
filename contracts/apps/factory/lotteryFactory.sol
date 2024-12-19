// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { NFTLottery } from "../lottery.sol";
import { ERC721Handler, ERC1155Handler } from "./lotteryTokens.sol";
import { INFTLotteryFactory, INFTHandler } from "./lotteryinterface.sol";
import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

abstract contract NFTLotteryFactory is INFTLotteryFactory {
    enum NFTStandards {
        ERC721,
        ERC1155
    }

    mapping(address => NFTStandards) public lotteryTypes;

    event LotteryCreated(address contractAddress, NFTStandards nftStandards);

    error NFTLotteryFactory__UnsupportedNFTStandards();

    function createLottery(
        address[] memory nftContract,
        address decrypter,
        uint256 fee,
        address fairyring
    ) public returns (address) {
        // TODO: check nftContract not empty, case erc721 should be length = 1
        bool isERC721 = false;
        bool isERC1155 = false;
        for (uint256 i = 0; i < nftContract.length; i++) {
            isERC721 = _supportsInterface(nftContract[0], type(IERC721).interfaceId);
            isERC1155 = _supportsInterface(nftContract[i], type(IERC1155).interfaceId);
        }

        address[] memory nftHandler;
        NFTStandards standard;

        if (isERC721 && nftContract.length == 1) {
            nftHandler[0] = address(new ERC721Handler(nftContract[0]));
            standard = NFTStandards.ERC721;
        } else if (isERC1155) {
            // Example
            uint256[] memory ids;
            ids[0] = 1;
            // ids[1] = 2;
            // ids[2] = 3;

            uint256[] memory amounts;
            amounts[0] = 1000;
            // amounts[1] = 1000;
            // amounts[2] = 2000;
            // TODO: use `Collection` struct from Lottery
            for (uint256 i = 0; i < nftContract.length; i++) {
                nftHandler[i] = address(new ERC1155Handler(nftContract[i], ids, amounts));
            }
            standard = NFTStandards.ERC1155;
        } else {
            revert NFTLotteryFactory__UnsupportedNFTStandards();
        }

        address lotteryAddress = _deployLottery(nftHandler, fee, fairyring, decrypter);

        lotteryTypes[lotteryAddress] = standard;
        emit LotteryCreated(lotteryAddress, standard);

        return lotteryAddress;
    }

    function _supportsInterface(address contractAddress, bytes4 interfaceId) internal view returns (bool) {
        try IERC165(contractAddress).supportsInterface(interfaceId) returns (bool supported) {
            return supported;
        } catch {
            return false;
        }
    }

    function _deployLottery(
        address[] memory nftHandler,
        uint256 fee,
        address fairyringContract,
        address decrypter
    ) internal returns (address) {
        NFTLotteryProxy lottery = new NFTLotteryProxy(nftHandler, fee, fairyringContract, decrypter);
        return address(lottery);
    }
}

contract NFTLotteryProxy {
    address[] private nftHandler;
    address private immutable implementation;

    constructor(address[] memory _nftHandler, uint256 _fee, address _fairyringContract, address _decrypter) {
        nftHandler = _nftHandler;

        // Deploy implementation contract
        implementation = address(new NFTLottery(_nftHandler, _fee, _fairyringContract, _decrypter));
    }

    fallback() external payable {
        address _implementation = implementation;
        assembly {
            calldatacopy(0, 0, calldatasize()) // copy input data (calldata) -> mem pos 0

            // Parameters:
            // - gas(): all remaining gas
            // - _implementation: address to delegate to
            // - 0: start reading memory from position 0
            // - calldatasize(): amount of input data
            // - 0: start writing output to memory position 0
            // - 0: we don't know output size yet
            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize()) // copy return data to memory
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}
