// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { ICementableTokenMetadata } from "../../interfaces/metadata/ICementableTokenMetadata.sol";
import { UpdatableTokenMetadataUpgradeable } from "./UpdatableTokenMetadataUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract CementableTokenMetadataUpgradeable is
    Initializable,
    UpdatableTokenMetadataUpgradeable,
    ICementableTokenMetadata
{
    struct CementableTokenMetadataStorage {
        mapping(uint256 => bool) _cemented;
    }

    bytes32 private constant _CEMENTABLE_TOKEN_METADATA_STORAGE_LOCATION =
        0x935e9bcbc0809e5814f39d3828d0a7f7b9174743a7e081e81a47c083b0f4a400;

    // solhint-disable no-inline-assembly
    function _getCementableTokenMetadataStorage() private pure returns (CementableTokenMetadataStorage storage s) {
        // TODO: Is this neccesary?
        assembly {
            s.slot := _CEMENTABLE_TOKEN_METADATA_STORAGE_LOCATION
        }
    }

    // solhint-disable func-name-mixedcase
    // solhint-disable no-empty-blocks
    function __CementableTokenMetadata_init() internal onlyInitializing {}

    // solhint-disable no-empty-blocks
    function __CementableTokenMetadata_init_unchained() internal onlyInitializing {}

    // solhint-enable func-name-mixedcase
    modifier tokenMetadataEditable(uint256 _tokenId) {
        if (_tokenURICemented(_tokenId)) {
            revert ICementableTokenMetadata.TokenMetadataCemented(_tokenId);
        }
        _;
    }

    function tokenURICemented(uint256 _tokenId) external view virtual returns (bool) {
        return _tokenURICemented(_tokenId);
    }

    function cementTokenMetadata(uint256 _tokenId) external virtual onlyTokenMetadataEditor(_tokenId) {
        _cementTokenMetadata(_tokenId);
    }

    function _tokenURICemented(uint256 _tokenId) internal view virtual returns (bool) {
        CementableTokenMetadataStorage storage s = _getCementableTokenMetadataStorage();
        return s._cemented[_tokenId];
    }

    function _cementTokenMetadata(uint256 _tokenId) internal virtual {
        CementableTokenMetadataStorage storage s = _getCementableTokenMetadataStorage();
        s._cemented[_tokenId] = true;
        emit MetadataCemented(_tokenId);
    }

    function _setTokenMetadata(
        uint256 _tokenId,
        string memory _metadata
    ) internal virtual override tokenMetadataEditable(_tokenId) {
        super._setTokenMetadata(_tokenId, _metadata);
    }
}
