import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const tokenAddress = "0x669eEe68Ef39E12D1b38d1f274BFc9aC46D771CB";
const merkleRoot = "0x29c08bc8bf7d3a0ed4b1dd16063389608cf9dec220f1584e32d317c2041e1fa4";
//redeploy

const MerkleAirdropModule = buildModule("MerkleAirdropModule", (m) => {

  const airdrop = m.contract("MerkleAirdrop",[tokenAddress, merkleRoot]);

  return { airdrop };
});

export default MerkleAirdropModule;
