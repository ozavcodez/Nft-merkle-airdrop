// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract MerkleAirdrop {
    // @dev Custom errors
    error ZeroAddressDetected();
    error HasClaimedRewardsAlready();
    error UnAuthorizedFunctionCall();
    error InvalidClaim();
    error ZeroValueDetected();
    error UnclaimedTokensStillMuch();

    // @dev events
    event AirdropClaimed(address indexed _user, uint256 indexed _amount);
    event WithdrawalSuccessful(address indexed _owner, uint256 indexed _amount);

    // @dev state variables
    address owner;
    address tokenAddress;
    bytes32 merkleRoot;
    uint256 totalAmountSpent;

    // @dev mapping to track users that have claimed
    mapping(address => bool) claimedAirdropMap;

    constructor(address _tokenAddress, bytes32 _merkleRoot) {
        tokenAddress = _tokenAddress;
        merkleRoot = _merkleRoot;
        owner = msg.sender;
    }

    // @dev prevents zero address from interacting with the contract
    function sanityCheck(address _user) private pure {
        if (_user == address(0)) {
            revert ZeroAddressDetected();
        }
    }

    function zeroValueCheck(uint256 _amount) private pure {
        if (_amount <= 0) {
            revert ZeroValueDetected();
        }
    }

    // @dev prevents users from accessing onlyOwner privileges
    function onlyOwner() private view {
        if (msg.sender != owner) {
            revert UnAuthorizedFunctionCall();
        }
    }

    // @dev returns if a user has claimed or not
    function _hasClaimedAirdrop() private view returns (bool) {
        sanityCheck(msg.sender);
        return claimedAirdropMap[msg.sender];
    }

    // @dev checks contract token balance
    function getContractBalance() public view returns (uint256) {
        onlyOwner();
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    // @user for claiming airdrop
    function claimAirdrop(
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) external {
        sanityCheck(msg.sender);
        if (_hasClaimedAirdrop()) {
            revert HasClaimedRewardsAlready();
        }
        // @dev we hash the encoded byte form of the user address and amount to create a leaf
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _amount));

        // @dev check if the merkleProof provided is valid or belongs to the merkleRoot
        if (!MerkleProof.verify(_merkleProof, merkleRoot, leaf)) {
            revert InvalidClaim();
        }

        claimedAirdropMap[msg.sender] = true;
        totalAmountSpent += _amount;

        IERC20(tokenAddress).transfer(msg.sender, _amount);

        emit AirdropClaimed(msg.sender, _amount);
    }

    // @user for the contract owner to update the Merkle root
    // @dev updates the merkle state
    function updateMerkleRoot(bytes32 _merkleRoot) external {
        onlyOwner();
        merkleRoot = _merkleRoot;
    }

    // @user get current merkle proof
    function getMerkleProof() external view returns (bytes32) {
        sanityCheck(msg.sender);
        onlyOwner();
        return merkleRoot;
    }

    // @user For owner to withdraw left over tokens

    /* @dev the withdrawal is only possible if the amount of tokens left in the contract
        is less than the total amount of tokens claimed by the users
    */
    function withdrawLeftOverToken() external {
        onlyOwner();
        uint256 contractBalance = getContractBalance();
        zeroValueCheck(contractBalance);

        if (totalAmountSpent <= contractBalance) {
            revert UnclaimedTokensStillMuch();
        }
        /* if the totalAmountSpent is greater than the contract balance
        it is safe to withdraw because at least 51% of the token would have been circulated
        */
        IERC20(tokenAddress).transfer(owner, contractBalance);
    }
}
