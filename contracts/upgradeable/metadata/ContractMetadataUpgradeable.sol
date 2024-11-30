// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IContractMetadata } from "../../interfaces/metadata/IContractMetadata.sol";
import { ContractMetadata } from "../../metadata/ContractMetadata.sol";
import { JsonUtil } from "../../utils/JsonUtil.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract ContractMetadataUpgradeable is Initializable, ContractMetadata {
    struct ContractMetadataStorage {
        bool _cemented;
    }

    bytes32 private constant _CONTRACT_METADATA_STORAGE_LOCATION =
        0x985371f50cecfcb1a6dfdccb4c871d7a5d94b17a9d368860b42eaca20a68bf00;

    // solhint-disable no-inline-assembly
    function _getContractMetadataStorage() private pure returns (ContractMetadataStorage storage s) {
        assembly {
            s.slot := _CONTRACT_METADATA_STORAGE_LOCATION
        }
    }

    // solhint-disable func-name-mixedcase
    function __ContractMetadata_init(string memory _name) internal onlyInitializing {
        __ContractMetadata_init_unchained(_name);
    }

    function __ContractMetadata_init_unchained(string memory _name) internal onlyInitializing {
        _setContractMetadata(JsonUtil.set("{}", "name", _name));
    }
    // solhint-enable func-name-mixedcase

    modifier contractMetadataEditable() virtual override {
        ContractMetadataStorage storage s = _getContractMetadataStorage();
        if (s._cemented) {
            revert IContractMetadata.ContractMetadataCemented();
        }
        _;
    }

    function contractURICemented() public view virtual override returns (bool) {
        ContractMetadataStorage storage s = _getContractMetadataStorage();
        return s._cemented;
    }

    function cementContractMetadata() public virtual override onlyContractMetadataEditor {
        ContractMetadataStorage storage s = _getContractMetadataStorage();
        s._cemented = true;
        emit ContractURICemented();
    }
}
