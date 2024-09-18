// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


contract MerkleAirdrop {
    address public owner;
    IERC20 public immutable tokenAddress;
    bytes32 public merkleRoot;
    address public immutable BAYC_ADDRESS = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
    address public NFT_Holder = 0x483DcF0311b7B6Ca18284a5815Cc0F4E2F678Fa8;
    
    mapping (address => bool) public claimed;

    event ClaimSuccessful(address, uint);
    constructor(address _tokenAddress, bytes32 _merkleRoot) {
        owner = msg.sender;
        tokenAddress = IERC20(_tokenAddress);
        merkleRoot = _merkleRoot;
    }

    function claim(address user_address, uint _amount, bytes32[] memory _proof) external {
        // check that users claim by themselves
        require(msg.sender == user_address, "Cant claim for others");
        // 
        require(!claimed[user_address], "already claimed");

        require(IERC721(BAYC_ADDRESS).balanceOf(user_address) > 0, "Must own a BAYC NFT");

        // compute leaf hash for provided address and amount
        bytes32 leaf = keccak256(abi.encodePacked(user_address, _amount));

        require(MerkleProof.verify(_proof, merkleRoot, leaf), "Invalid proof");

        claimed[user_address] = true;

        // transfer amount of token to user
        tokenAddress.transfer(user_address, _amount);

        emit ClaimSuccessful(user_address, _amount);
    }

    function onlyOwner() view private {
        require(msg.sender == owner, "unauthorized");
    }

    // function to update merkle root
    function updateMerkleRoot(bytes32 _merkleRoot) external {
        onlyOwner();
        merkleRoot = _merkleRoot;
    }
}