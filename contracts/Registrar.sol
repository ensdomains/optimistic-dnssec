pragma solidity ^0.4.24;

import "@ensdomains/dnssec-oracle/contracts/DNSSECImpl.sol";

contract Registrar {

    /// label => proof
    mapping (bytes32 => bytes) proofs;

    event Claim(bytes32 indexed node, address indexed owner, bytes dnsname);

    /// @notice This function allows the user to submit a DNSSEC proof for a certain amount of ETH.
    function commit(bytes name, bytes proof, address addr) public payable {
        require(msg.value == 1 ether);
//        address addr = getOwnerAddress(name, proof);

        bytes32 labelHash;
        bytes32 rootNode;
        (labelHash, rootNode) = getLabels(name);

        ens.setSubnodeOwner(rootNode, labelHash, addr);
        proofs[labelHash] = proof;
        emit Claim(keccak256(abi.encodePacked(rootNode, labelHash)), addr, name);
    }

    /// @notice This function allows a user to challenge the validity of a DNSSEC proof submitted.
    function challenge(bytes32 labelHash) external {

        // @todo verify

        ens.setSubnodeOwner(rootNode, labelHash, 0x0);
    }

    function getLabels(bytes memory name) internal view returns (bytes32, bytes32) {
        uint len = name.readUint8(0);
        uint second = name.readUint8(len + 1);

        require(name.readUint8(len + second + 2) == 0);

        return (name.keccak(1, len), keccak256(bytes32(0), name.keccak(2 + len, second)));
    }
}
