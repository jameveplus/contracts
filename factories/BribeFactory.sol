// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "contracts/Bribes.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "hardhat/console.sol";

interface IBribe {
    function addReward(address) external;
}

contract BribeFactory is OwnableUpgradeable {
    
    uint256[50] __gap;
    
    address public last_bribe;
    address public voter;

    
    function initialize() initializer  public {
        __Ownable_init();
    }

    function createBribe(address _owner,address _token0, address _token1) external returns (address) {
        require(msg.sender == voter || msg.sender == owner(), '!VOTER');
        Bribe lastBribe = new Bribe(_owner, voter, address(this));

        lastBribe.addReward(_token0);
        lastBribe.addReward(_token1);
        last_bribe = address(lastBribe);
        return last_bribe;
    }

    function setVoter(address _Voter) external {
        require(owner() == msg.sender, '!OWNER');
        require(_Voter != address(0));
        voter = _Voter;
    }

     function addReward(address _token, address[] memory _bribes) external {
        require(owner() == msg.sender, '!OWNER');
        uint i = 0;
        for ( i ; i < _bribes.length; i++){
            IBribe(_bribes[i]).addReward(_token);
        }
    }

    function addRewards(address[][] memory _token, address[] memory _bribes) external {
        require(owner() == msg.sender, '!OWNER');
        uint i = 0;
        uint k;
        for ( i ; i < _bribes.length; i++){
            address _bribe = _bribes[i];
            for(k = 0; k < _token[i].length; k++){
                IBribe(_bribe).addReward(_token[i][k]);
            }
        }
    }

}