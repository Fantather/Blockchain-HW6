// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library ArrayLibrary {
    function indexOf(uint256[] storage arr, uint256 value) internal view returns (bool found, uint256 index) {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == value) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function sort(uint256[] storage arr) internal {
        for (uint256 i = 1; i < arr.length; i++) {
            uint256 key = arr[i];
            uint256 j = i;
            while (j > 0 && arr[j - 1] > key) {
                arr[j] = arr[j - 1];
                j--;
            }
            arr[j] = key;
        }
    }

    function removeAt(uint256[] storage arr, uint256 index) internal {
        require(index < arr.length, "index out of range");
        for (uint256 i = index; i < arr.length - 1; i++) {
            arr[i] = arr[i + 1];
        }
        arr.pop();
    }
}
