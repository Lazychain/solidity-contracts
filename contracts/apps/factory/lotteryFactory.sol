// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { NFTLottery } from "../lottery.sol";
import { ERC721Handler, ERC1155Handler } from "./lotteryTokens.sol";
import { INFTLotteryFactory } from "./lotteryinterface.sol";
import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "hardhat/console.sol";

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
        uint256 fee,
        address fairyringContract,
        address decrypter
    ) external override returns (NFTLottery) {
        console.log("createLottery");
        bool isERC721 = _supportsInterface(nftContract, type(IERC721).interfaceId);
        bool isERC1155 = _supportsInterface(nftContract, type(IERC1155).interfaceId);

        address nftHandler;
        NFTStandards standard;

        if (isERC721) {
            console.log("ERC721");
            nftHandler = address(new ERC721Handler(nftContract));
            standard = NFTStandards.ERC721;
        } else if (isERC1155) {
            console.log("ERC1155");
            // Example

            uint256[] memory ids = new uint256[](12);
            ids[0] = 1;
            uint256[] memory amounts = new uint256[](12);
            amounts[0] = 1000;

            nftHandler = address(new ERC1155Handler(nftContract, ids, amounts));
            standard = NFTStandards.ERC1155;
        } else {
            revert NFTLotteryFactory__UnsupportedNFTStandards();
        }

        NFTLottery lottery = _deployLottery(nftHandler, fee, fairyringContract, decrypter);

        lotteryTypes[address(lottery)] = standard;
        emit LotteryCreated(address(lottery), standard);

        return lottery;
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
        address fairyringContract,
        address decrypter
    ) internal returns (NFTLottery) {
        NFTLotteryProxy lotteryProxy = new NFTLotteryProxy(nftHandler, fee, fairyringContract, decrypter);
        return lotteryProxy.getLottery();
    }
}

contract NFTLotteryProxy {
    address private immutable nftHandler;
    address private immutable implementation;

    NFTLottery private _lottery;

    constructor(address _nftHandler, uint256 _fee, address _fairyringContract, address _decrypter) {
        nftHandler = _nftHandler;

        // Deploy implementation contract
        _lottery = new NFTLottery(_nftHandler, _fee, _fairyringContract, _decrypter);
        implementation = address(_lottery);
    }

    function getLottery() external view returns (NFTLottery) {
        return _lottery;
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
