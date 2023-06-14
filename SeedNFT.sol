// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract SeedNFT is ERC721Enumerable, Ownable, ReentrancyGuardUpgradeable {
    using Strings for uint256;
    string public baseUri;

    uint256 public MAX_SUPPLY = 10000;               // 10000 SeedNFT
    uint256 public constant MINT_END = 1688088785;   // Fri Jun 30 2023 01:33:05 GMT+0000
    mapping(address => uint) public userMinted;
    bytes32 public merkleRoot;

    event Minted(address minter, uint tokenId);
    event UpdatedBaseUri(string baseUri);
    event UpdatedMerkleRoot(bytes32 _merkleRoot);
    event Referred(address user, address ref, address token, uint amount);

    constructor(string memory _baseUri, bytes32 _merkleRoot) ERC721("Seed NFT of VePlus", "SeedNFT") {
        baseUri = _baseUri;
        merkleRoot = _merkleRoot;
    }

    function setBaseURI(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
        emit UpdatedBaseUri(_baseUri);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
        emit UpdatedMerkleRoot(_merkleRoot);
    }

    function setMaxSupply(uint256 _max) external onlyOwner {
        MAX_SUPPLY = _max;
    }

    function baseURI() external view returns (string memory) {
        return baseUri;
    }

    function mint(address account, uint tier,  bytes32[] calldata proof, uint amount, address ref) public nonReentrant {
        require(block.timestamp <= MINT_END, "CLAIM_ENDED");
        require(msg.sender != ref, "REF_INVALID");

        uint _left = left(account, tier, proof);
        _left = 10;
        require(amount <= _left, "MINTED");
        require(totalSupply() + amount <= MAX_SUPPLY, "INVALID_AMOUNT");

        if(ref != address(0)){
            uint _tokenId = totalSupply() + 1;
            _safeMint(account, _tokenId);
            emit Minted(account, _tokenId);

            _tokenId = totalSupply() + 1;
            _safeMint(ref, _tokenId);
            emit Referred(msg.sender, ref, address(this), 1);
        }

        for (uint i = userMinted[account]; i < userMinted[account] + amount; i++) {
            uint _tokenId = totalSupply() + 1;
            _safeMint(account, _tokenId);
            emit Minted(account, _tokenId);
        }
       
        userMinted[account] += amount;
    }

    function mintBatch(address[] memory account) public onlyOwner{
        require(block.timestamp <= MINT_END, "CLAIM_ENDED");
        require(totalSupply() + account.length <= MAX_SUPPLY, "INVALID_AMOUNT");
        for (uint256 i = 0; i < account.length; i++) {
            uint _tokenId = totalSupply() + 1;
            _safeMint(account[i], _tokenId);
            emit Minted(msg.sender, _tokenId);
        }
    }

    function mintBatch(uint amount) external onlyOwner{
        require(block.timestamp <= MINT_END, "CLAIM_ENDED");
        require(totalSupply() + amount <= MAX_SUPPLY, "INVALID_AMOUNT");
        for (uint256 i = 0; i < amount; i++) {
            uint _tokenId = totalSupply() + 1;
            _safeMint(msg.sender, _tokenId);
            emit Minted(msg.sender, _tokenId);
        }
    }

    function allocated(address account, uint tier,  bytes32[] calldata proof) internal view returns(uint) {
        bytes32 leaf = keccak256(abi.encodePacked(account, tier * 1e18));
        bool isValidLeaf = MerkleProof.verify(proof, merkleRoot, leaf);

        if (!isValidLeaf){      // Not in merkle root can claim 1 NFT
            return 1;
        }
        if (tier == 1){         // Tier 1 can claim 10 NFTs
            return 10;
        }
        if (tier == 2){         // Tier 2 can claim 5 NFTs
            return 5;
        }
        return 1; 
    }

    function left(address account, uint tier,  bytes32[] calldata proof) public view returns(uint) {
        uint _allocated = allocated(account, tier, proof);
        return _allocated - userMinted[account];
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

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseUri, _tokenId.toString()));
    }
}