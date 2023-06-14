// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "hardhat/console.sol";

interface ISeedNFT {
    function tokensOfOwner(address _owner) external view returns (uint256[] memory);
    function balanceOf(address _owner) external returns(uint256 balance);
}

contract TreeNFT is ERC721Enumerable, Ownable, ReentrancyGuardUpgradeable {
    using Strings for uint256;
    string private baseUri;
    ISeedNFT private seedNFT;
    uint256 public privateMinted;

    uint256 public constant MAX_SUPPLY = 2500;         
    uint256 public constant PRIVATE_MINT = 875;
    uint256 public constant MINT_PER_USER = 10;
    uint256 public constant PRE_PRICE = 92 * 1e16;          // 0.92 bnb
    uint256 public constant PUBLIC_PRICE = 100 * 1e16;      // 1 bnb
    address public TREASURY = 0x7915Bd047f4732c759c6C5c8272A7d9aEc7E8624;

    uint256 public PRE_MINT_START = 1686528000;
    uint256 public PUB_MINT_START = PRE_MINT_START + 1 days;
    uint256 public MINT_ENDED = PUB_MINT_START + 2 days;

    mapping(address => uint256) public userMinted;

    event Minted(address minter, uint tokenId);
    event Referred(address user, address ref, address token, uint amount);
    event UpdatedBaseUri(string baseUri);
    
    constructor(string memory _baseUri, address _seedNFT) ERC721("Premium Tree of VePlus", "TreeNFT") {
        baseUri = _baseUri;
        seedNFT = ISeedNFT(_seedNFT);
    }

    function setBaseURI(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
        emit UpdatedBaseUri(_baseUri);
    }

    function mint(uint256 amount, address ref) public payable nonReentrant {
        uint round = currentRound();
        uint price = currentPrice();
        require(amount > 0 && amount + userMinted[msg.sender] <= MINT_PER_USER, "INVALID_AMOUNT");
        if(round == 1){
            require(amount + userMinted[msg.sender] <= seedNFT.balanceOf(msg.sender), "INVALID_AMOUNT");
        }
        require(msg.value >= price * amount, "INSUFFICIENT_FUNDS");

        if(ref != address(0)){
            require(msg.sender != ref, "REF_INVALID");
            uint ref_amount = msg.value * 10/100;       
            (bool result, ) =  payable(ref).call{value: ref_amount}("");
            require(result, "FAIL");
            emit Referred(msg.sender, ref, address(0), ref_amount);
        }

        userMinted[msg.sender] = userMinted[msg.sender] + amount;
        _mintTo(msg.sender, amount);
    }

    function _mintTo(address account, uint amount) internal {
        require(totalSupply() + amount <= MAX_SUPPLY, "INVALID_AMOUNT");
        for (uint256 i = 0; i < amount; i++) {
            if ( totalSupply() < MAX_SUPPLY) {
                uint _tokenId = totalSupply() + 1;
                _safeMint(account, _tokenId);
                emit Minted(msg.sender, _tokenId);
            }
        }
    }

    function baseURI() external view returns (string memory) {
        return baseUri;
    }

    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory ids = new uint256[](tokenCount);
            for (uint256 index; index < tokenCount; index++) {
                ids[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return ids;
        }
    }

    function currentRound() public view returns( uint256 ) {
        if (block.timestamp < PRE_MINT_START) return 0;     // not started
        if (block.timestamp < PUB_MINT_START) return 1;     // phase 1: Pre mint
        if (block.timestamp < MINT_ENDED) return 2;         // phase 2: Public mint
        return 3;   // minting ended
    }

    function currentPrice() public view returns(uint256){
        uint _round = currentRound();
        require(_round != 0 && _round != 3, "TIME_INVALID");
        uint price;
        if (_round == 1) {
            price = PRE_PRICE;
        } else if (_round == 2) {
            price = PUBLIC_PRICE;
        }
        return price;
    }

    /**
     * Mint NFTs to private investors
     */
    function privateMint(address[] memory _to, uint256[] memory _amount) external onlyOwner {
        require(_to.length != 0 && _to.length == _amount.length , "Invalid length.");
        require(currentRound() == 3 || totalSupply() >= MAX_SUPPLY - PRIVATE_MINT, "Mint for private can only be done after minting end or sold out" );

        for (uint i=0; i < _to.length; i++) {
            require(_to[i] != address(0), "Invalid address.");
            require(_amount[i] != 0, "Invalid amount.");
            require(privateMinted + _amount[i] <= PRIVATE_MINT, "Invalid amount.");
            
            _mintTo(msg.sender, _amount[i]);

            privateMinted = privateMinted + _amount[i];
            userMinted[_to[i]] = userMinted[_to[i]] + _amount[i];
        }
    }

    function withdraw() external onlyOwner {
        (bool result, ) = TREASURY.call{value: address(this).balance}("");
        require(result, "FAIL");
    }

    /**
    * @dev Returns an URI for a given token ID
    */
    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseUri, _tokenId.toString()));
    }

    /*
        Only Trade NFTs after Minting ends.
    */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require( (currentRound() == 4), "!TRADING_TIME");
        super._transfer(from,to,tokenId);
    }
}