// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Base64 } from "./Base64.sol";
import { JsonUtil } from "./JsonUtil.sol";
// import { IBase64 } from "../interfaces/precompile/IBase64.sol";
import { IJsonStore } from "../interfaces/precompile/IJsonStore.sol";

/**
 * @title JsonStore Library
 * @notice A library for storing and managing JSON data in smart contracts
 */
library JsonStore {
    // solhint-disable private-vars-leading-underscore
    IJsonStore internal constant STORE = IJsonStore(0x00000000000000000000000000000F043a000007);
    // IBase64 internal constant BASE64 = IBase64(0x00000000000000000000000000000f043a000004);

    ////////////
    // EVENTS //
    ////////////
    event JsonStored(address indexed owner, bytes32 indexed slot);
    event JsonCleared(address indexed owner, bytes32 indexed slot);
    event SlotsPrepaid(address indexed owner, uint64 numSlots);

    struct JsonData {
        string jsonBlob;
        bool exists;
        address owner;
    }

    struct Store {
        mapping(bytes32 => JsonData) jsonStorage;
        mapping(address => uint64) prepaidSlots;
    }

    ////////////
    // Errors //
    ////////////
    error JsonStore__EmptyJson();
    error JsonStore__InvalidJson();
    error JsonStore__SlotDoesNotExist();
    error JsonStore__SlotAlreadyExists();
    error JsonStore__InsufficientPrepaidSlots();

    /**
     * @notice Checks if a slot exists and is owned by the given address
     * @param self The Store struct
     * @param _key The owner's address
     * @param _slot The slot to check
     * @return bool indicating if the slot exists and is owned by the address
     */
    function exists(Store storage self, address _key, bytes32 _slot) internal view returns (bool) {
        JsonData storage data = self.jsonStorage[_slot];
        return data.exists && data.owner == _key;
    }

    /**
     * @notice Gets the JSON data URI for a slot
     * @param self The Store struct
     * @param _key The owner's address
     * @param _slot The slot to retrieve
     * @return string The JSON data URI
     */
    function uri(Store storage self, address _key, bytes32 _slot) internal view returns (string memory) {
        if (!exists(self, _key, _slot)) revert JsonStore__SlotDoesNotExist();

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(bytes(self.jsonStorage[_slot].jsonBlob))
                )
            );
    }

    /**
     * @notice Gets the raw JSON data for a slot
     * @param self The Store struct
     * @param _key The owner's address
     * @param _slot The slot to retrieve
     * @return string The raw JSON data
     */
    function get(Store storage self, address _key, bytes32 _slot) internal view returns (string memory) {
        if (!exists(self, _key, _slot)) revert JsonStore__SlotDoesNotExist();
        return self.jsonStorage[_slot].jsonBlob;
    }

    /**
     * @notice Gets the number of prepaid slots for an address
     * @param self The Store struct
     * @param _key The address to check
     * @return uint64 The number of prepaid slots
     */
    function prepaid(Store storage self, address _key) internal view returns (uint64) {
        return self.prepaidSlots[_key];
    }

    /**
     * @notice Checks if a slot exists in storage
     * @param self The Store struct
     * @param _slot The slot to check
     * @return bool indicating if the slot exists
     */
    function exists(Store storage self, bytes32 _slot) internal view returns (bool) {
        return self.jsonStorage[_slot].exists;
    }

    /**
     * @notice Gets the JSON data URI for a slot
     * @param self The Store struct
     * @param _slot The slot to retrieve
     * @return string The JSON data URI
     */
    function uri(Store storage self, bytes32 _slot) internal view returns (string memory) {
        if (!exists(self, _slot)) revert JsonStore__SlotDoesNotExist();

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(bytes(self.jsonStorage[_slot].jsonBlob))
                )
            );
    }

    /**
     * @notice Gets the raw JSON data for a slot
     * @param self The Store struct
     * @param _slot The slot to retrieve
     * @return string The raw JSON data
     */
    function get(Store storage self, bytes32 _slot) internal view returns (string memory) {
        if (!exists(self, _slot)) revert JsonStore__SlotDoesNotExist();
        return self.jsonStorage[_slot].jsonBlob;
    }

    /**
     * @notice Gets the number of prepaid slots for the caller
     * @param self The Store struct
     * @return uint64 The number of prepaid slots
     */
    function prepaid(Store storage self) internal view returns (uint64) {
        return self.prepaidSlots[msg.sender];
    }

    /**
     * @notice Sets JSON data in a slot
     * @param self The Store struct
     * @param _slot The slot to store the data
     * @param _jsonBlob The JSON data to store
     * @return bool indicating success
     */
    function set(Store storage self, bytes32 _slot, string memory _jsonBlob) internal returns (bool) {
        if (bytes(_jsonBlob).length == 0) revert JsonStore__EmptyJson();
        if (!JsonUtil.validate(_jsonBlob)) revert JsonStore__InvalidJson();
        if (self.prepaidSlots[msg.sender] == 0) revert JsonStore__InsufficientPrepaidSlots();
        if (self.jsonStorage[_slot].exists) revert JsonStore__SlotAlreadyExists();

        self.jsonStorage[_slot] = JsonData({ jsonBlob: _jsonBlob, exists: true, owner: msg.sender });

        self.prepaidSlots[msg.sender]--;
        emit JsonStored(msg.sender, _slot);
        return true;
    }

    function clear(Store storage self, bytes32 _slot) internal returns (bool) {
        if (!exists(self, msg.sender, _slot)) revert JsonStore__SlotDoesNotExist();

        delete self.jsonStorage[_slot];
        emit JsonCleared(msg.sender, _slot);
        return true;
    }

    function prepay(Store storage self, address _owner, uint64 _numSlots) internal {
        self.prepaidSlots[_owner] += _numSlots;
        emit SlotsPrepaid(_owner, _numSlots);
    }

    // /**
    //  * @notice Updates existing JSON data in a slot
    //  * @param self The Store struct
    //  * @param _slot The slot to update
    //  * @param _jsonBlob The new JSON data
    //  * @return bool indicating success
    //  */
    // function update(Store storage self, bytes32 _slot, string memory _jsonBlob) internal returns (bool) {
    //     if (!exists(self, msg.sender, _slot)) revert JsonStore__SlotDoesNotExist();
    //     if (bytes(_jsonBlob).length == 0) revert JsonStore__EmptyJson();
    //     if (!JsonUtil.validate(_jsonBlob)) revert JsonStore__InvalidJson();

    //     self.jsonStorage[_slot].jsonBlob = _jsonBlob;
    //     emit JsonStored(msg.sender, _slot);
    //     return true;
    // }

    // /**
    //  * @notice Clears a JSON slot
    //  * @param self The Store struct
    //  * @param _slot The slot to clear
    //  * @return bool indicating success
    //  */
    // function clear(Store storage self, bytes32 _slot) internal returns (bool) {
    //     if (!exists(self, msg.sender, _slot)) revert JsonStore__SlotDoesNotExist();

    //     delete self.jsonStorage[_slot];
    //     emit JsonCleared(msg.sender, _slot);
    //     return true;
    // }
}
