// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

/// ============ Imports ============

import "contracts/interfaces/IVePlus.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


/// @title MerkleClaim
/// @notice Claims VEP for members of a merkle tree
/// @author Modified from Merkle Airdrop Starter (https://github.com/Anish-Agnihotri/merkle-airdrop-starter/blob/master/contracts/src/MerkleClaimERC20.sol)
contract MerkleClaim {
    /// ============ Immutable storage ============

    /// @notice VePlus token to claim
    IVePlus public immutable VEP;
    /// @notice ERC20-claimee inclusion root
    bytes32 public immutable merkleRoot;

    uint endTime = 1696438800; // Airdrop end in 6 months

    /// ============ Mutable storage ============

    /// @notice Mapping of addresses who have claimed tokens
    mapping(address => bool) public hasClaimed;

    /// ============ Constructor ============

    /// @notice Creates a new MerkleClaim contract
    /// @param _vep address
    /// @param _merkleRoot of claimees
    constructor(address _vep, bytes32 _merkleRoot) {
        VEP = IVePlus(_vep);
        merkleRoot = _merkleRoot;
    }

    /// ============ Events ============

    /// @notice Emitted after a successful token claim
    /// @param to recipient of claim
    /// @param amount of tokens claimed
    event Claim(address indexed to, uint256 amount);

    /// ============ Functions ============

    /// @notice Allows claiming tokens if address is part of merkle tree
    /// @param to address of claimee
    /// @param amount of tokens owed to claimee
    /// @param proof merkle proof to prove address and amount are in tree
    function claim(
        address to,
        uint256 amount,
        bytes32[] calldata proof
    ) external {
        // Throw if address has already claimed tokens
        require(!hasClaimed[to], "ALREADY_CLAIMED");
        require(block.timestamp <= endTime, "CLAIM_ENDED");

        // Verify merkle proof, or revert if not in tree
        bytes32 leaf = keccak256(abi.encodePacked(to, amount));
        bool isValidLeaf = MerkleProof.verify(proof, merkleRoot, leaf);
        require(isValidLeaf, "NOT_IN_MERKLE");

        // Set address to claimed
        hasClaimed[to] = true;

        // Claim tokens for address
        // require(VEP.claim(to, amount), "CLAIM_FAILED");

        // Emit claim event
        emit Claim(to, amount);
    }
}
