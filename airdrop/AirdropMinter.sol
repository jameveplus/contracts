// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IVotingEscrow.sol";
import "../interfaces/ITreeNFT.sol";

contract AirdropClaimTreeNFT is ReentrancyGuard, Ownable {

    using SafeERC20 for IERC20;

    uint256 constant public VE_SHARE = 500;
    uint256 constant public PRECISION = 1000;
    uint256 constant public LOCK_PERIOD = 2 * 364 days;     // 2 years locked veVEP
    uint256 constant public VESTING_PERIOD = 2 * 30 days;   // 2 months vesting
    uint256 constant public rewardPerNFT = 1000 * 10**18;

    uint256 public immutable START_VESTING;
    uint256 public immutable START_CLAIM;
    address public immutable ve;
    address public immutable treeNFT;
    IERC20 public immutable token;

    bool private inited = false;
    
    mapping(address => bool) public depositors;
    mapping(address => bool) public isOnlyVeVEP;
    mapping(address => uint) public claimedVeVEP;
    mapping(address => uint) public claimedVEP;

    event Deposited(uint256 amount);
    event ClaimVeVEP(address _user, uint _amount, uint _tokenId);
    event ClaimVEP(address _user, uint _amount);

    struct UserInfo{
        uint256 totalMinted;
        uint256 veVEPTotal;
        uint256 veVEPClaimable;
        uint256 VEPTotal;
        uint256 VEPLeft;
        uint256 VEPClaimable;
        address to;
        uint startVesting;
        uint finishVesting;
    }

    constructor(address _token, address _ve, address _treeNFT) {
        token = IERC20(_token);
        treeNFT = _treeNFT;
        ve = _ve;
        START_CLAIM = 1685318400;                   // Mon May 29 2023 00:00:00 GMT+0000   (epoch 0);
        START_VESTING = START_CLAIM + 1 weeks;      // (epoch 1)
    }

    function initialize(uint256 amount) external {
        require(!inited, "INITED");
        require(depositors[msg.sender] == true || msg.sender == owner(), "PERMISSION_DENIED");
        uint _totalSupply = ITreeNFT(treeNFT).totalSupply();
        require(amount == _totalSupply * rewardPerNFT, "INVALID_AMOUNT");
        token.safeTransferFrom(msg.sender, address(this), amount);
        token.approve(ve, amount);
        inited = true;
        emit Deposited(amount);
    }

    function claimable(address _user, bool _onlyVeVEP) public view returns(UserInfo memory userInfo) {
        require(_user != address(0));

        if (claimedVeVEP[_user] != 0) {
            _onlyVeVEP = isOnlyVeVEP[_user];
        }
        userInfo.to = _user;
        uint _mints = ITreeNFT(treeNFT).userMinted(_user);
        userInfo.totalMinted =_mints;
        uint _amount = _mints * rewardPerNFT;

        uint _veVEPTotal;
        if(_onlyVeVEP) {
            _veVEPTotal = _amount;
        } else {
            _veVEPTotal = _amount / 2;      // by default 50/50
        }

        userInfo.veVEPTotal = _veVEPTotal;
        if(block.timestamp < START_CLAIM) {
            userInfo.veVEPClaimable = 0;
        } else {
            userInfo.veVEPClaimable = _veVEPTotal - claimedVeVEP[_user];
        }
        
        uint _totalVEP = _amount - _veVEPTotal;
        userInfo.VEPTotal = _totalVEP;
        userInfo.VEPLeft = _totalVEP - claimedVEP[_user];

        if( block.timestamp > START_VESTING ) {
            uint duration = block.timestamp - START_VESTING;
            if (duration > VESTING_PERIOD) duration = VESTING_PERIOD;
            userInfo.VEPClaimable = (_totalVEP * duration / VESTING_PERIOD) - claimedVEP[_user];
        } else {
            userInfo.VEPClaimable = 0;
        }

        userInfo.startVesting = START_VESTING;
        userInfo.finishVesting = START_VESTING + VESTING_PERIOD;
    }
    
    function claim(bool _onlyVeVEP) external nonReentrant{
        require(START_CLAIM <= block.timestamp, "!START");

        if (claimedVeVEP[msg.sender] == 0) {
            isOnlyVeVEP[msg.sender] = _onlyVeVEP;
        }

        UserInfo memory _userInfo = claimable(msg.sender, _onlyVeVEP);
        uint _amountOut = _userInfo.VEPClaimable + _userInfo.veVEPClaimable;
        require(token.balanceOf(address(this)) >= _amountOut, "INSUFFICIENT_FUNDS");
        uint _amount;
        if (_userInfo.veVEPClaimable > 0) {
            _amount = _userInfo.veVEPClaimable;
            uint _tokenId = IVotingEscrow(ve).create_lock_for(_amount, LOCK_PERIOD, msg.sender);
            require(_tokenId != 0);
            require(IVotingEscrow(ve).ownerOf(_tokenId) == msg.sender, 'MINT_FAIL'); 

            claimedVeVEP[msg.sender] = claimedVeVEP[msg.sender] + _amount;
            emit ClaimVeVEP(msg.sender, _amount, _tokenId);
        }

        if (_userInfo.VEPClaimable > 0) {
            _amount = _userInfo.VEPClaimable;

            token.safeTransfer(msg.sender, _amount);
            claimedVEP[msg.sender] = claimedVEP[msg.sender] +_amount;

            emit ClaimVEP(msg.sender, _amount);
        }
    }

    function setDepositor(address depositor) external onlyOwner {
        require(depositors[depositor] == false);
        depositors[depositor] = true;
    }

    function withdrawStuckERC20(address _token, address _to) external onlyOwner {
        IERC20(_token).safeTransfer(_to, IERC20(_token).balanceOf(address(this)));
    }
}