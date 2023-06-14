// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {Base64} from "contracts/libraries/Base64.sol";
import {IVeArtProxy} from "contracts/interfaces/IVeArtProxy.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";


contract VeArtProxy is IVeArtProxy, OwnableUpgradeable, ReentrancyGuardUpgradeable {

    function initialize() public initializer {
      ///@dev as there is no constructor, we need to initialise the OwnableUpgradeable explicitly
       __Ownable_init();
    }

    function toString(uint value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint temp = value;
        uint digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function _tokenURI(uint _tokenId, uint _lock_amount, uint _locked_end, uint _vote_power) external pure returns (string memory output) {
        output = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 600 900"><style>.b{fill:#b3d9ff;}.g{fill:#D3F85A;}.f{fill:#000066;}.w{fill:#f2f2f2;}.s{font-size:37px;}</style><rect fill="#fdf2f0" width="600" height="900"/><rect class="b" x="0" y="424" width="600" height="98"/><rect class="b" x="0" y="544" width="600" height="98"/><rect class="b" x="0" y="772" width="600" height="98"/><rect class="b" x="0" y="658" width="600" height="98"/>';
        output = string(abi.encodePacked(output, '<text transform="matrix(1 0 0 1 88 463)" class="f s">Token ID:</text><text transform="matrix(1 0 0 1 88 502)" class="w s">', toString(_tokenId), '</text>'));
        output = string(abi.encodePacked(output, '<text transform="matrix(1 0 0 1 88 579)" class="f s">Locked amount:</text><text transform="matrix(1 0 0 1 88 618)" class="w s">', toString(_lock_amount / 1e18), '</text>'));
        output = string(abi.encodePacked(output, '<text transform="matrix(1 0 0 1 88 694)" class="f s">Locked end:</text><text transform="matrix(1 0 0 1 88 733)" class="w s">', toString((_locked_end) / 60 / 60 / 24), ' days</text>'));
        output = string(abi.encodePacked(output, '<text transform="matrix(1 0 0 1 88 804)" class="f s">Vote power:</text><text transform="matrix(1 0 0 1 88 843)" class="w s">', toString(_vote_power / 1e18), '</text></svg>'));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "veVEP #', toString(_tokenId), '", "description": "VePlus locks, can be used to vote on token emission, and receive bribes, fees", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));
    }
}
