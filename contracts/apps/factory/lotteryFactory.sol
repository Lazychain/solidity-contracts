// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { INFTLotteryFactory } from "./lotteryinterface.sol";
import { ERC721Handler, ERC1155Handler } from "./lotteryTokens.sol";
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
            revert NFTLotteryFactory__UnsupportedNFTStandards();
        }

        address lotteryAddress = _deployLottery(nftHandler, fee, threshold, fairyring, decrypter);

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
        address nftHandler,
        uint256 fee,
        uint8 threshold,
        address fairyringContract,
        address decrypter
    ) internal returns (address) {
        NFTLotteryProxy lottery = new NFTLotteryProxy(nftHandler, fee, threshold, fairyringContract, decrypter);
        return address(lottery);
    }
}

// Proxy contract for NFT Lottery
contract NFTLotteryProxy {
    address private immutable nftHandler;
    address private immutable implementation;

    constructor(address _nftHandler, uint256 _fee, uint8 _threshold, address _fairyringContract, address _decrypter) {
        nftHandler = _nftHandler;

        // Deploy implementation contract
        implementation = address(
            new NFTLotteryImplementation(_nftHandler, _fee, _threshold, _fairyringContract, _decrypter)
        );
    }

    fallback() external payable {
        address _implementation = implementation;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
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
