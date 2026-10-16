// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ArrayLibrary.sol";

contract ArrayUtils {
    using ArrayLibrary for uint256[];

    uint256[] private items;

    function add(uint256 value) public {
        items.push(value);
    }

    function find(uint256 value) public view returns (bool found, uint256 index) {
        return items.indexOf(value);
    }

    function sort() public {
        items.sort();
    }

    function removeAt(uint256 index) public {
        items.removeAt(index);
    }

    function removeValue(uint256 value) public {
        (bool found, uint256 index) = items.indexOf(value);
        require(found, "value not found");
        items.removeAt(index);
    }

    function getAll() public view returns (uint256[] memory) {
        return items;
    }
}
