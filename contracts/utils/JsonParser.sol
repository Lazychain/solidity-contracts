// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library JsonParser {
    enum JsonType {
        UNDEFINED,
        OBJECT,
        ARRAY,
        STRING,
        PRIMITIVE
    }

    uint8 public constant RETURN_SUCCESS = 0;
    uint8 public constant RETURN_ERROR_INVALID_JSON = 1;
    uint8 public constant RETURN_ERROR_PART = 2;
    uint8 public constant RETURN_ERROR_NO_MEM = 3;

    struct Token {
        JsonType jsonType;
        uint256 start;
        bool startSet;
        uint256 end;
        bool endSet;
        uint8 size;
    }

    struct Parser {
        uint256 pos;
        uint256 toknext;
        int256 toksuper;
    }

    function init(uint256 length) public pure returns (Parser memory, Token[] memory) {
        Parser memory p = Parser(0, 0, -1);
        Token[] memory t = new Token[](length);
        return (p, t);
    }

    function allocateToken(
        Parser memory parser,
        Token[] memory tokens
    ) public pure returns (bool, Parser memory, Token memory) {
        if (parser.toknext >= tokens.length) {
            // no more space in tokens
            return (false, parser, tokens[tokens.length - 1]);
        }
        Token memory token = Token(JsonType.UNDEFINED, 0, false, 0, false, 0);
        tokens[parser.toknext] = token;
        parser.toknext++;
        return (true, parser, token);
    }

    function fillToken(
        Token memory token,
        JsonType jsonType,
        uint256 start,
        uint256 end
    ) public pure returns (Token memory) {
        token.jsonType = jsonType;
        token.start = start;
        token.startSet = true;
        token.end = end;
        token.endSet = true;
        token.size = 0;
        return token;
    }

    function parseString(Parser memory parser, Token[] memory tokens, bytes memory s) public pure returns (uint256) {
        uint256 start = parser.pos;
        bool success;
        Token memory token;
        parser.pos++;

        for (; parser.pos < s.length; parser.pos++) {
            bytes1 c = s[parser.pos];

            // Quote -> end of string
            if (c == '"') {
                (success, , token) = allocateToken(parser, tokens);
                if (!success) {
                    parser.pos = start;
                    return RETURN_ERROR_NO_MEM;
                }
                fillToken(token, JsonType.STRING, start + 1, parser.pos);
                return RETURN_SUCCESS;
            }

            if (uint8(c) == 92 && parser.pos + 1 < s.length) {
                // handle escaped characters: skip over it
                parser.pos++;
                if (
                    s[parser.pos] == '"' ||
                    s[parser.pos] == "/" ||
                    s[parser.pos] == "\\" ||
                    s[parser.pos] == "f" ||
                    s[parser.pos] == "r" ||
                    s[parser.pos] == "n" ||
                    s[parser.pos] == "b" ||
                    s[parser.pos] == "t"
                ) {
                    continue;
                } else {
                    // all other values are INVALID
                    parser.pos = start;
                    return (RETURN_ERROR_INVALID_JSON);
                }
            }
        }
        parser.pos = start;
        return RETURN_ERROR_PART;
    }

    function parsePrimitive(Parser memory parser, Token[] memory tokens, bytes memory s) public pure returns (uint256) {
        bool found = false;
        uint256 start = parser.pos;
        bytes1 c;
        bool success;
        Token memory token;
        for (; parser.pos < s.length; parser.pos++) {
            c = s[parser.pos];
            if (c == " " || c == "\t" || c == "\n" || c == "\r" || c == "," || c == 0x7d || c == 0x5d) {
                found = true;
                break;
            }
            if (uint8(c) < 32 || uint8(c) > 127) {
                parser.pos = start;
                return RETURN_ERROR_INVALID_JSON;
            }
        }
        if (!found) {
            parser.pos = start;
            return RETURN_ERROR_PART;
        }

        // found the end
        (success, , token) = allocateToken(parser, tokens);
        if (!success) {
            parser.pos = start;
            return RETURN_ERROR_NO_MEM;
        }
        fillToken(token, JsonType.PRIMITIVE, start, parser.pos);
        parser.pos--;
        return RETURN_SUCCESS;
    }

    // NOTE: Need to test the GAS consumption of this function....
    function parse(
        string memory json,
        uint256 numberElements
    ) public pure returns (uint256, Token[] memory tokens, uint256) {
        bytes memory s = bytes(json);
        Parser memory parser;
        (parser, tokens) = init(numberElements);

        uint256 count = parser.toknext;

        for (; parser.pos < s.length; parser.pos++) {
            bytes1 c = s[parser.pos];

            if (isOpeningBracket(c)) {
                if (!processOpeningBracket(parser, tokens, count)) return (RETURN_ERROR_NO_MEM, tokens, 0);
                continue;
            }

            if (isClosingBracket(c)) {
                if (!processClosingBracket(parser, tokens, c)) return (RETURN_ERROR_INVALID_JSON, tokens, 0);
                continue;
            }

            if (c == '"') {
                if (!processString(parser, tokens, s, count)) return (RETURN_ERROR_INVALID_JSON, tokens, 0);
                continue;
            }

            if (isWhitespace(c)) continue;

            if (c == ":") {
                processColon(parser);
                continue;
            }

            if (c == ",") {
                processComma(parser, tokens);
                continue;
            }

            if (isPrimitiveChar(c)) {
                if (!processPrimitive(parser, tokens, s, count)) return (RETURN_ERROR_INVALID_JSON, tokens, 0);
                continue;
            }

            if (isPrintableChar(c)) return (RETURN_ERROR_INVALID_JSON, tokens, 0);
        }

        return (RETURN_SUCCESS, tokens, parser.toknext);
    }

    // Helper Functions

    function processOpeningBracket(
        Parser memory parser,
        Token[] memory tokens,
        uint256 count
    ) private pure returns (bool) {
        (bool success, uint256 newCount) = handleOpeningBracket(parser, tokens, count);
        if (success) count = newCount;
        return success;
    }

    function processClosingBracket(Parser memory parser, Token[] memory tokens, bytes1 c) private pure returns (bool) {
        (bool success, ) = handleClosingBracket(parser, tokens, c);
        return success;
    }

    function processString(
        Parser memory parser,
        Token[] memory tokens,
        bytes memory s,
        uint256 count
    ) private pure returns (bool) {
        uint256 r = parseString(parser, tokens, s);
        if (r != RETURN_SUCCESS) return false;
        count++;
        if (parser.toksuper != -1) tokens[uint256(parser.toksuper)].size++;
        return true;
    }

    function processColon(Parser memory parser) private pure {
        parser.toksuper = int256(parser.toknext - 1);
    }

    function processComma(Parser memory parser, Token[] memory tokens) private pure {
        handleComma(parser, tokens);
    }

    function processPrimitive(
        Parser memory parser,
        Token[] memory tokens,
        bytes memory s,
        uint256 count
    ) private pure returns (bool) {
        uint256 r = handlePrimitive(parser, tokens, s);
        if (r != RETURN_SUCCESS) return false;
        count++;
        if (parser.toksuper != -1) tokens[uint256(parser.toksuper)].size++;
        return true;
    }

    // Helper functions

    function handleString(Parser memory parser, Token[] memory tokens, bytes memory s) private pure returns (uint256) {
        uint256 r = parseString(parser, tokens, s);
        return r;
    }

    function handleColon(Parser memory parser) private pure {
        parser.toksuper = int256(parser.toknext - 1);
    }

    function isOpeningBracket(bytes1 c) private pure returns (bool) {
        return (c == 0x7b || c == 0x5b);
    }

    function isClosingBracket(bytes1 c) private pure returns (bool) {
        return (c == 0x7d || c == 0x5d);
    }

    function isWhitespace(bytes1 c) private pure returns (bool) {
        return (c == " " || c == 0x11 || c == 0x12 || c == 0x14);
    }

    function isPrimitiveChar(bytes1 c) private pure returns (bool) {
        return ((c >= "0" && c <= "9") || c == "-" || c == "f" || c == "t" || c == "n");
    }

    function isPrintableChar(bytes1 c) private pure returns (bool) {
        return (c >= 0x20 && c <= 0x7e);
    }

    function handleOpeningBracket(
        Parser memory parser,
        Token[] memory tokens,
        uint256 count
    ) private pure returns (bool success, uint256 newCount) {
        Token memory token;
        (success, , token) = allocateToken(parser, tokens);
        if (!success) return (false, count);

        if (parser.toksuper != -1) tokens[uint256(parser.toksuper)].size++;
        token.jsonType = (parser.pos == 0x7b ? JsonType.OBJECT : JsonType.ARRAY);
        token.start = parser.pos;
        token.startSet = true;
        parser.toksuper = int256(parser.toknext - 1);
        return (true, count + 1);
    }

    function handleClosingBracket(
        Parser memory parser,
        Token[] memory tokens,
        bytes1 c
    ) private pure returns (bool success, uint256 newCount) {
        JsonType tokenType = (c == 0x7d ? JsonType.OBJECT : JsonType.ARRAY);
        bool isUpdated = false;
        for (uint256 i = parser.toknext - 1; i >= 0; i--) {
            Token memory token = tokens[i];
            if (token.startSet && !token.endSet) {
                if (token.jsonType != tokenType) return (false, 0);
                parser.toksuper = -1;
                tokens[i].end = parser.pos + 1;
                tokens[i].endSet = true;
                isUpdated = true;
                break;
            }
        }
        return (isUpdated, 0);
    }

    function handleComma(Parser memory parser, Token[] memory tokens) private pure {
        for (uint256 i = parser.toknext - 1; i >= 0; i--) {
            if (tokens[i].jsonType == JsonType.ARRAY || tokens[i].jsonType == JsonType.OBJECT) {
                if (tokens[i].startSet && !tokens[i].endSet) {
                    parser.toksuper = int256(i);
                    break;
                }
            }
        }
    }

    function handlePrimitive(
        Parser memory parser,
        Token[] memory tokens,
        bytes memory s
    ) private pure returns (uint256) {
        return parsePrimitive(parser, tokens, s);
    }

    function getBytes(string memory json, uint256 start, uint256 end) public pure returns (string memory) {
        bytes memory s = bytes(json);
        bytes memory result = new bytes(end - start);
        for (uint256 i = start; i < end; i++) {
            result[i - start] = s[i];
        }
        return string(result);
    }

    // parseInt
    function parseInt(string memory _a) public pure returns (int256) {
        return parseInt(_a, 0);
    }

    // parseInt(parseFloat*10^_b)
    function parseInt(string memory _a, uint256 _b) public pure returns (int256) {
        bytes memory bresult = bytes(_a);
        int256 mint = 0;
        bool decimals = false;
        bool negative = false;
        for (uint256 i = 0; i < bresult.length; i++) {
            if ((i == 0) && (bresult[i] == "-")) {
                negative = true;
            }
            if ((uint8(bresult[i]) >= 48) && (uint8(bresult[i]) <= 57)) {
                if (decimals) {
                    if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += int256(uint256(uint8(bresult[i]))) - 48; // First convert to uint8, then to int256
            } else if (uint8(bresult[i]) == 46) {
                decimals = true;
            }
        }
        if (_b > 0) mint *= int256(10 ** _b);
        if (negative) mint *= -1;
        return mint;
    }

    function uint2str(uint256 i) public pure returns (string memory) {
        if (i == 0) return "0";
        uint256 j = i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (i != 0) {
            bstr[k--] = bytes1(uint8(48 + (i % 10)));
            i /= 10;
        }
        return string(bstr);
    }

    function parseBool(string memory _a) public pure returns (bool) {
        if (strCompare(_a, "true") == 0) {
            return true;
        } else {
            return false;
        }
    }

    function strCompare(string memory _a, string memory _b) public pure returns (int256) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint256 minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        for (uint256 i = 0; i < minLength; i++)
            if (a[i] < b[i]) return -1;
            else if (a[i] > b[i]) return 1;
        if (a.length < b.length) return -1;
        else if (a.length > b.length) return 1;
        else return 0;
    }
}
