// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IBribeFactory {
    function createInternalBribe(address[] memory) external returns (address);
    function createExternalBribe(address[] memory) external returns (address);
    function createBribe(address _owner, address _token0, address _token1) external returns (address);
}
