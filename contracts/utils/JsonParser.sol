// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library JsonParser {
    // Use uint8 instead of uint256 for error codes to save gas
    uint8 public constant RETURN_SUCCESS = 0;
    uint8 public constant RETURN_ERROR_INVALID_JSON = 1;
    uint8 public constant RETURN_ERROR_PART = 2;
    uint8 public constant RETURN_ERROR_NO_MEM = 3;

    /// @notice Enum representing different JSON types.
    /// @dev Used for classifying JSON elements during parsing.
    enum JsonType {
        UNDEFINED,
        OBJECT,
        ARRAY,
        STRING,
        PRIMITIVE
    }

    /// @notice Represents a JSON token with metadata.
    /// @dev Tokens are used to store parsed JSON elements.
    /// @param jsonType The type of the JSON element.
    /// @param start The start index of the token in the JSON string.
    /// @param end The end index of the token in the JSON string.
    /// @param size The number of child tokens if the token is an object or array.
    /// @param startSet Indicates whether the start index is set.
    /// @param endSet Indicates whether the end index is set.
    struct Token {
        JsonType jsonType;
        uint256 start;
        uint256 end;
        uint8 size;
        bool startSet;
        bool endSet;
    }

    /// @notice Represents the parser's current state during JSON parsing.
    /// @dev Tracks the current position and token allocation status.
    /// @param pos The current position in the JSON string.
    /// @param toknext Index of the next token to be allocated.
    /// @param toksuper Index of the current parent token.
    struct Parser {
        uint256 pos;
        uint256 toknext;
        int256 toksuper;
    }

    /// @notice Initializes the JSON parser and allocates a specified number of tokens.
    /// @param length The number of tokens to allocate.
    /// @return parser The initialized parser state.
    /// @return tokens The array of allocated tokens.
    function init(uint256 length) internal pure returns (Parser memory parser, Token[] memory tokens) {
        parser = Parser(0, 0, -1);
        tokens = new Token[](length);
    }

    /// @notice Allocates a new token for the parser.
    /// @dev Updates the parser state to reflect the new token allocation.
    /// @param parser The current parser state.
    /// @param tokens The array of tokens.
    /// @return success Whether the token allocation was successful.
    /// @return token The allocated token.
    function allocateToken(
        Parser memory parser,
        Token[] memory tokens
    ) internal pure returns (bool success, Token memory token) {
        if (parser.toknext >= tokens.length) {
            return (false, tokens[tokens.length - 1]);
        }
        token = Token(JsonType.UNDEFINED, 0, 0, 0, false, false);
        tokens[parser.toknext] = token;
        parser.toknext++;
        return (true, token);
    }

    /// @notice Fills a token with metadata based on the parsed JSON element.
    /// @param token The token to be filled.
    /// @param jsonType The type of the JSON element.
    /// @param start The start index of the token.
    /// @param end The end index of the token.
    /// @return token The updated token with metadata.
    function fillToken(
        Token memory token,
        JsonType jsonType,
        uint256 start,
        uint256 end
    ) internal pure returns (Token memory) {
        token.jsonType = jsonType;
        token.start = start;
        token.end = end;
        token.startSet = true;
        token.endSet = true;
        token.size = 0;
        return token;
    }

    /// @notice Parses a JSON string value.
    /// @dev Handles escape characters and validates the string format.
    /// @param parser The current parser state.
    /// @param tokens The array of tokens.
    /// @param s The JSON string to parse.
    /// @return returnCode The result code indicating success or error.
    /// @return token The parsed string token.
    function parseString(
        Parser memory parser,
        Token[] memory tokens,
        bytes memory s
    ) internal pure returns (uint8 returnCode, Token memory token) {
        uint256 start = parser.pos;
        parser.pos++; // Skip opening quote

        for (; parser.pos < s.length; parser.pos++) {
            bytes1 c = s[parser.pos];

            // Found closing quote
            if (c == '"') {
                (bool success, Token memory newToken) = allocateToken(parser, tokens);
                if (!success) {
                    parser.pos = start;
                    return (RETURN_ERROR_NO_MEM, token);
                }

                // Include quotes in token bounds
                token = fillToken(
                    newToken,
                    JsonType.STRING,
                    start, // Keep quote in bounds
                    parser.pos + 1 // Include closing quote
                );
                return (RETURN_SUCCESS, token);
            }

            // Handle escapes
            if (c == "\\" && parser.pos + 1 < s.length) {
                parser.pos++; // Skip escape char
                continue;
            }
        }

        parser.pos = start;
        return (RETURN_ERROR_PART, token);
    }

    /// @notice Checks if a character is a valid escape sequence in a JSON string.
    /// @param c The character to validate.
    /// @return True if the character is a valid escape character; false otherwise.
    function isValidEscapeChar(bytes1 c) internal pure returns (bool) {
        return (c == '"' || c == "/" || c == "\\" || c == "f" || c == "r" || c == "n" || c == "b" || c == "t");
    }

    /// @notice Parses a JSON primitive value (e.g., numbers, booleans, null).
    /// @param parser The current parser state.
    /// @param tokens The array of tokens.
    /// @param s The JSON string to parse.
    /// @return returnCode The result code indicating success or error.
    /// @return token The parsed primitive token.
    function parsePrimitive(
        Parser memory parser,
        Token[] memory tokens,
        bytes memory s
    ) internal pure returns (uint8 returnCode, Token memory token) {
        uint256 start = parser.pos;
        bool found = false;
        uint256 sLength = s.length;
        for (; parser.pos < sLength; parser.pos++) {
            bytes1 c = s[parser.pos];
            if (isTerminatingChar(c)) {
                found = true;
                break;
            }
            if (!isValidPrimitiveChar(c)) {
                parser.pos = start;
                return (RETURN_ERROR_INVALID_JSON, token);
            }
        }

        if (!found) {
            parser.pos = start;
            return (RETURN_ERROR_PART, token);
        }

        (bool success, Token memory newToken) = allocateToken(parser, tokens);
        if (!success) {
            parser.pos = start;
            return (RETURN_ERROR_NO_MEM, token);
        }

        token = fillToken(newToken, JsonType.PRIMITIVE, start, parser.pos);
        parser.pos--;
        return (RETURN_SUCCESS, token);
    }

    /// @notice Main JSON parsing function.
    /// @dev Tokenizes a JSON string into an array of Token structs.
    /// @param json The JSON string to parse
    /// @param numberElements Maximum number of tokens to allocate
    /// @return returnCode Success (0) or error code (1-3)
    /// @return tokens Array of parsed tokens
    /// @return tokenCount Number of tokens parsed
    // solhint-disable code-complexity
    // solhint-disable function-max-lines
    // TODO: reduce complexity
    function parse(
        string memory json,
        uint256 numberElements
    ) public pure returns (uint8 returnCode, Token[] memory tokens, uint256 tokenCount) {
        bytes memory s = bytes(json);
        Parser memory parser;
        (parser, tokens) = init(numberElements);
        uint256 sLength = s.length;
        for (; parser.pos < sLength; parser.pos++) {
            bytes1 c = s[parser.pos];

            if (isWhitespace(c)) continue;

            if (isOpeningBracket(c)) {
                if (!processOpeningBracket(parser, tokens, s)) return (RETURN_ERROR_NO_MEM, tokens, 0);
                continue;
            }

            if (isClosingBracket(c)) {
                if (!processClosingBracket(parser, tokens, c)) return (RETURN_ERROR_INVALID_JSON, tokens, 0);
                continue;
            }

            if (c == '"') {
                (uint8 stringResult, ) = parseString(parser, tokens, s);
                if (stringResult != RETURN_SUCCESS) {
                    // Propagate the actual error code instead of always returning INVALID_JSON
                    return (stringResult, tokens, 0);
                }
                if (parser.toksuper != -1) tokens[uint256(parser.toksuper)].size++;
                continue;
            }

            if (c == ":") {
                parser.toksuper = int256(parser.toknext - 1);
                continue;
            }

            if (c == ",") {
                processComma(parser, tokens);
                continue;
            }

            if (isPrimitiveStartChar(c)) {
                (uint8 primResult, ) = parsePrimitive(parser, tokens, s);
                if (primResult != RETURN_SUCCESS) return (RETURN_ERROR_INVALID_JSON, tokens, 0);
                if (parser.toksuper != -1) tokens[uint256(parser.toksuper)].size++;
                continue;
            }

            return (RETURN_ERROR_INVALID_JSON, tokens, 0);
        }

        return (RETURN_SUCCESS, tokens, parser.toknext);
    }

    /// @notice Processes an opening bracket ('{' or '[') in the JSON string.
    /// @dev Creates a new token for objects or arrays and updates parser state.
    /// @param parser Current parser state
    /// @param tokens Array of tokens being built
    /// @param s Byte array of the JSON string
    /// @return Success status of the operation
    function processOpeningBracket(
        Parser memory parser,
        Token[] memory tokens,
        bytes memory s
    ) internal pure returns (bool) {
        // First check if we have space for the new token
        if (parser.toknext >= tokens.length) {
            return false; // This will trigger RETURN_ERROR_NO_MEM
        }

        (bool success, Token memory token) = allocateToken(parser, tokens);
        if (!success) return false;

        if (parser.toksuper != -1) tokens[uint256(parser.toksuper)].size++;

        token.jsonType = (s[parser.pos] == bytes1(0x7b)) ? JsonType.OBJECT : JsonType.ARRAY;
        token.start = parser.pos;
        token.startSet = true;
        parser.toksuper = int256(parser.toknext - 1);
        return true;
    }

    /// @notice Processes a closing bracket ('}' or ']') in the JSON string.
    /// @dev Validates matching brackets and updates token end positions.
    /// @param parser Current parser state
    /// @param tokens Array of tokens being built
    /// @param c The closing bracket character
    /// @return Success status of the operation
    function processClosingBracket(Parser memory parser, Token[] memory tokens, bytes1 c) internal pure returns (bool) {
        JsonType tokenType = (c == bytes1(0x7d)) ? JsonType.OBJECT : JsonType.ARRAY;

        for (uint256 i = parser.toknext - 1; i < parser.toknext; i--) {
            Token memory token = tokens[i];
            if (token.startSet && !token.endSet) {
                if (token.jsonType != tokenType) return false;
                parser.toksuper = -1;
                tokens[i].end = parser.pos + 1;
                tokens[i].endSet = true;
                return true;
            }
            if (i == 0) break;
        }
        return false;
    }

    /// @notice Processes a comma separator in the JSON string.
    /// @dev Updates the parser's super token pointer for nested structures.
    /// @param parser Current parser state
    /// @param tokens Array of tokens being built
    function processComma(Parser memory parser, Token[] memory tokens) internal pure {
        for (uint256 i = parser.toknext - 1; i < parser.toknext; i--) {
            if (
                (tokens[i].jsonType == JsonType.ARRAY || tokens[i].jsonType == JsonType.OBJECT) &&
                tokens[i].startSet &&
                !tokens[i].endSet
            ) {
                parser.toksuper = int256(i);
                break;
            }
            if (i == 0) break;
        }
    }

    /// @notice Checks if a character is an opening bracket.
    /// @param c Character to check
    /// @return True if character is '{' or '['
    function isOpeningBracket(bytes1 c) internal pure returns (bool) {
        return (c == bytes1(0x7b) || c == bytes1(0x5b));
    }

    /// @notice Checks if a character is a closing bracket.
    /// @param c Character to check
    /// @return True if character is '}' or ']'
    function isClosingBracket(bytes1 c) internal pure returns (bool) {
        return (c == bytes1(0x7d) || c == bytes1(0x5d));
    }

    /// @notice Checks if a character is whitespace.
    /// @param c Character to check
    /// @return True if character is space, tab, newline, or carriage return
    function isWhitespace(bytes1 c) internal pure returns (bool) {
        return (c == bytes1(0x20) || c == bytes1(0x09) || c == bytes1(0x0a) || c == bytes1(0x0d));
    }

    /// @notice Checks if a character can start a primitive value.
    /// @param c Character to check
    /// @return True if character can start a number, boolean, or null
    function isPrimitiveStartChar(bytes1 c) internal pure returns (bool) {
        return ((c >= bytes1(0x30) && c <= bytes1(0x39)) || // 0-9
            c == bytes1(0x2d) || // -
            c == bytes1(0x66) || // f
            c == bytes1(0x74) || // t
            c == bytes1(0x6e)); // n
    }

    /// @notice Checks if a character can terminate a primitive value.
    /// @param c Character to check
    /// @return True if character can end a primitive value
    function isTerminatingChar(bytes1 c) internal pure returns (bool) {
        return (c == bytes1(0x20) ||
            c == bytes1(0x09) ||
            c == bytes1(0x0a) ||
            c == bytes1(0x0d) ||
            c == bytes1(0x2c) ||
            c == bytes1(0x7d) ||
            c == bytes1(0x5d));
    }

    /// @notice Validates if a character is valid within a primitive value.
    /// @param c Character to check
    /// @return True if character is valid in a primitive
    function isValidPrimitiveChar(bytes1 c) internal pure returns (bool) {
        return (uint8(c) >= 32 && uint8(c) <= 127);
    }

    /// @notice Extracts a substring from a JSON string.
    /// @param json The source JSON string
    /// @param start Starting index
    /// @param end Ending index
    /// @return Extracted substring
    function getBytes(string memory json, uint256 start, uint256 end) public pure returns (string memory) {
        require(end > start, "Invalid indices");
        require(end <= bytes(json).length, "Index out of bounds");

        bytes memory s = bytes(json);
        bytes memory result = new bytes(end - start);
        for (uint256 i = start; i < end; i++) {
            result[i - start] = s[i];
        }
        return string(result);
    }

    /// @notice Parses a string into an integer.
    /// @param _a String to parse
    /// @return Parsed integer value
    function parseInt(string memory _a) public pure returns (int256) {
        return parseInt(_a, 0);
    }

    /// @notice Parses a string into an integer with decimal places.
    /// @param _a String to parse
    /// @param _b Number of decimal places to consider
    /// @return Parsed integer value
    function parseInt(string memory _a, uint256 _b) public pure returns (int256) {
      bytes memory bresult = bytes(_a);
      if(bresult.length == 0) revert("Empty string");

      int256 mint = 0;
      bool decimals = false;
      bool negative = false;
      uint256 divisor = 1;
      bool hasDigits = false;

      uint256 bresultLength = bresult.length;
      for (uint256 i = 0; i < bresultLength; ++i) {
          bytes1 currentByte = bresult[i];
        
          // Handle negative sign only at start
          if (i == 0 && currentByte == bytes1(0x2d)) {
              negative = true;
              continue;
          }
        
          // Handle decimal point
          if (currentByte == bytes1(0x2e)) {
              if (decimals) revert("Multiple decimal points"); // Can't have multiple decimal points
              decimals = true;
              continue;
          }
        
          // Handle digits
          if (uint8(currentByte) >= 48 && uint8(currentByte) <= 57) {
              hasDigits = true;
              if (decimals && _b > 0) {
                  if (mint > type(int256).max / 10) revert("Number too large");
                  divisor *= 10;
                  mint = mint * 10 + int256(uint256(uint8(currentByte) - 48));
                  --_b;
              } else if (!decimals) {
                  if (mint > type(int256).max / 10) revert("Number too large");
                  mint = mint * 10 + int256(uint256(uint8(currentByte) - 48));
              }
          } else {
              revert("Invalid character in number");
          }
      }

      if (!hasDigits) revert("No digits found");
      
      if (negative && mint == type(int256).min) revert("Number too small");
    
      return negative ? -mint / int256(divisor) : mint / int256(divisor);
    }

    /// @notice Converts an unsigned integer to a string.
    /// @param i Integer to convert
    /// @return String representation of the integer
    function uint2str(uint256 i) public pure returns (string memory) {
        if (i == 0) return "0";
        uint256 temp = i;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (i != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + uint256(i % 10)));
            i /= 10;
        }
        return string(buffer);
    }

    /// @notice Parses a string into a boolean.
    /// @param _a String to parse ("true" or "false")
    /// @return Parsed boolean value
    function parseBool(string memory _a) public pure returns (bool) {
        return strCompare(_a, "true") == 0;
    }

    /// @notice Compares two strings lexicographically.
    /// @param _a First string
    /// @param _b Second string
    /// @return -1 if _a < _b, 1 if _a > _b, 0 if equal
    function strCompare(string memory _a, string memory _b) public pure returns (int256) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint256 minLength = a.length < b.length ? a.length : b.length;

        for (uint256 i = 0; i < minLength; i++) {
            if (a[i] < b[i]) return -1;
            if (a[i] > b[i]) return 1;
        }

        if (a.length < b.length) return -1;
        if (a.length > b.length) return 1;
        return 0;
    }
}
