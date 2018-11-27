pragma solidity ^0.4.24;

import "@ensdomains/ENS/contracts/ENS.sol";
import "@ensdomains/dnssec-oracle/contracts/DNSSEC.sol";

contract Registrar {

    struct Record {
        address submitter;
        address addr;
        bytes proof;
        bytes name;
        bytes32 label;
        bytes32 node;
        uint256 submitted;
    }

    ENS public ens;
    DNSSEC public dnssec;

    uint256 public cooldown;
    uint256 public deposit;

    /// label => record
    mapping (bytes32 => Record) public records;

    event Submitted(bytes32 indexed node, address indexed owner, bytes dnsname);
    event Claim(bytes32 indexed node, address indexed owner, bytes dnsname);

    constructor(ENS _ens, DNSSEC _dnssec, uint256 _cooldown, uint256 _deposit) public {
        ens = _ens;
        dnssec = _dnssec;
        cooldown = _cooldown;
        deposit = _deposit;
    }

    /// @notice This function allows the user to submit a DNSSEC proof for a certain amount of ETH.
    function submit(bytes name, bytes proof, address addr) external payable {
        require(msg.value == deposit);

        bytes32 label;
        bytes32 node;
        (label, node) = getLabels(name);

        proofs[keccak256(node, label)] = Record({
            submitter: msg.sender,
            addr: addr,
            proof: proof,
            name: name,
            label: label,
            node: node,
            submitted: now
        });

        emit Submitted(keccak256(abi.encodePacked(rootNode, labelHash)), addr, name);
    }

    // @notice This function commits a Record to the ENS registry.
    function commit(bytes32 node) external {
        Record storage record = records[node];

        require(record.submitted + cooldown <= now);

        bytes32 node = record.node;
        bytes32 label = record.label;
        bytes32 addr = record.addr;

        require(addr != address(0x0));

        ens.setSubnodeOwner(node, label, addr);
        record.submitter.transfer(deposit);

        emit Claim(keccak256(abi.encodePacked(node, label)), addr, record.name);
    }

    /// @notice This function allows a user to challenge the validity of a DNSSEC proof submitted.
    function challenge(bytes32 node) external {
        Record storage record = records[node];

        require(record.submitted + cooldown > now);

        // @todo verify

        delete record[node];
    }

    function getLabels(bytes memory name) internal view returns (bytes32, bytes32) {
        uint len = name.readUint8(0);
        uint second = name.readUint8(len + 1);

        require(name.readUint8(len + second + 2) == 0);

        return (name.keccak(1, len), keccak256(bytes32(0), name.keccak(2 + len, second)));
    }
}
