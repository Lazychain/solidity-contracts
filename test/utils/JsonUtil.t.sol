// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import { JsonUtil } from "../../contracts/utils/JsonUtil.sol";
import { JsonParser } from "../../contracts/utils/JsonParser.sol";

contract JsonUtilTest is Test {
    string private constant SIMPLE_JSON = '{"name":"John","age":30,"city":"New York"}';
    string private constant NESTED_JSON =
        '{"person":{"name":"John","age":30,"address":{"city":"New York","zip":"10001"}}}';
    string private constant ARRAY_JSON = '{"numbers":[1,2,3],"names":["John","Jane"]}';
    string private constant COMPLEX_JSON =
        '{"data":{"users":[{"id":1,"name":"John","active":true},{"id":2,"name":"Jane","active":false}]}}';

    function setUp() public pure {}

    function testGet() public pure {
        string memory name = JsonUtil.get(SIMPLE_JSON, "name");
        string memory age = JsonUtil.get(SIMPLE_JSON, "age");
        string memory city = JsonUtil.get(SIMPLE_JSON, "city");

        assertEq(name, "John");
        assertEq(age, "30");
        assertEq(city, "New York");
    }

    function testGetNested() public pure {
        assertEq(JsonUtil.get(NESTED_JSON, "person.name"), "John");
        assertEq(JsonUtil.get(NESTED_JSON, "person.age"), "30");
        assertEq(JsonUtil.get(NESTED_JSON, "person.address.city"), "New York");
        assertEq(JsonUtil.get(NESTED_JSON, "person.address.zip"), "10001");
    }

    function testGetArray() public pure {
        assertEq(JsonUtil.get(ARRAY_JSON, "numbers[0]"), "1");
        assertEq(JsonUtil.get(ARRAY_JSON, "numbers[1]"), "2");
        assertEq(JsonUtil.get(ARRAY_JSON, "names[0]"), "John");
        assertEq(JsonUtil.get(ARRAY_JSON, "names[1]"), "Jane");
    }

    function testGetComplex() public pure {
        assertEq(JsonUtil.get(COMPLEX_JSON, "data.users[0].name"), "John");
        assertEq(JsonUtil.get(COMPLEX_JSON, "data.users[0].active"), "true");
    }

    function testGetInt() public pure {
        assertEq(JsonUtil.getInt(SIMPLE_JSON, "age"), 30);
        assertEq(JsonUtil.getInt(NESTED_JSON, "person.age"), 30);
    }

    function testGetUint() public pure {
        assertEq(JsonUtil.getUint(SIMPLE_JSON, "age"), 30);
        assertEq(JsonUtil.getUint(NESTED_JSON, "person.age"), 30);
    }

    function testGetBool() public pure {
        assertTrue(JsonUtil.getBool(COMPLEX_JSON, "data.users[0].active"));
    }

    // function testGetComplex1() public pure {
    //     // UNABLE TO PARSE OBJECT AT INDEX=1... only parsing 1st Object...
    //     assertEq(JsonUtil.get(COMPLEX_JSON, "data.users[1].name"), "Jane");
    //     assertEq(JsonUtil.get(COMPLEX_JSON, "data.users[1].active"), "false");
    // }

    // function testGetBool1() public pure {
    //     // UNABLE TO PARSE OBJECT AT INDEX=1... only parsing 1st Object...
    //     assertFalse(JsonUtil.getBool(COMPLEX_JSON, "data.users[1].active"));
    // }

    function testExists() public pure {
        assertTrue(JsonUtil.exists(SIMPLE_JSON, "name"));
        assertTrue(JsonUtil.exists(NESTED_JSON, "person.address.city"));
        assertFalse(JsonUtil.exists(SIMPLE_JSON, "notexist"));
        assertFalse(JsonUtil.exists(NESTED_JSON, "person.notexist"));
    }

    function testValidate() public pure {
        assertTrue(JsonUtil.validate(SIMPLE_JSON));
        assertTrue(JsonUtil.validate(NESTED_JSON));
        assertTrue(JsonUtil.validate(ARRAY_JSON));
        assertTrue(JsonUtil.validate(COMPLEX_JSON));
        assertFalse(JsonUtil.validate("{invalid json}"));
    }

    function testTokenParsing() public pure {
        (uint8 returnCode, JsonParser.Token[] memory tokens, uint256 count) = JsonParser.parse(SIMPLE_JSON, 128);
        require(returnCode == JsonParser.RETURN_SUCCESS, "Parse failed");

        for (uint i = 0; i < count; i++) {
            if (tokens[i].jsonType == JsonParser.JsonType.STRING) {
                string memory extracted = JsonParser.getBytes(SIMPLE_JSON, tokens[i].start + 1, tokens[i].end - 1);
                console.log("Token %s: %s", i, extracted);
            }
        }
    }
}
