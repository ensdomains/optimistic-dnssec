pragma solidity ^0.4.24;

import "@ensdomains/ENS/contracts/ENS.sol";
import "@ensdomains/dnssec-oracle/contracts/DNSSEC.sol";
import "@ensdomains/dnssec-oracle/contracts/BytesUtils.sol";
import "@ensdomains/dnsregistrar/contracts/DNSClaimChecker.sol";

contract Registrar {

    using BytesUtils for bytes;

    struct Record {
        address submitter;
        address addr;
        bytes32 proof;
        bytes32 name;
        bytes32 label;
        bytes32 node;
        uint256 submitted;
    }

    uint16 constant CLASS_INET = 1;
    uint16 constant TYPE_TXT = 16;

    ENS public ens;
    DNSSEC public oracle;

    uint256 public cooldown;
    uint256 public deposit;

    /// label => record
    mapping (bytes32 => Record) public records;

    event Submitted(bytes32 indexed node, address indexed owner, bytes proof, bytes dnsname);
    event Claim(bytes32 indexed node, address indexed owner);

    constructor(ENS _ens, DNSSEC _dnssec, uint256 _cooldown, uint256 _deposit) public {
        ens = _ens;
        oracle = _dnssec;
        cooldown = _cooldown;
        deposit = _deposit;
    }

    /// @notice This function allows the user to submit a DNSSEC proof for a certain amount of ETH.
    function submit(bytes name, bytes proof, address addr) external payable {
        require(msg.value == deposit);

        bytes32 label;
        bytes32 node;
        (label, node) = DNSClaimChecker.getLabels(name);

        records[keccak256(node, label)] = Record({
            submitter: msg.sender,
            addr: addr,
            proof: keccak256(proof),
            name: keccak256(name),
            label: label,
            node: node,
            submitted: now
        });

        emit Submitted(keccak256(abi.encodePacked(node, label)), addr, proof, name);
    }

    // @notice This function commits a Record to the ENS registry.
    function commit(bytes32 node) external {
        Record storage record = records[node];

        require(record.submitted + cooldown <= now);

        bytes32 rootNode = record.node;
        bytes32 label = record.label;
        address addr = record.addr;

        require(addr != address(0x0));

        ens.setSubnodeOwner(rootNode, label, addr);
        record.submitter.transfer(deposit);

        emit Claim(keccak256(abi.encodePacked(rootNode, label)), addr);
    }

    /// @notice This function allows a user to challenge the validity of a DNSSEC proof submitted.
    function challenge(bytes32 node, bytes proof, bytes name) external {
        Record storage record = records[node];

        require(record.submitted + cooldown > now);

        require(record.proof == keccak256(proof));
        require(record.name == keccak256(name));

        require(record.addr != DNSClaimChecker.getOwnerAddress(oracle, record.name, record.proof));

        delete records[node];
    }
}
