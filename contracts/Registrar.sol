pragma solidity ^0.4.24;

import "@ensdomains/ENS/contracts/ENS.sol";
import "@ensdomains/dnssec-oracle/contracts/DNSSEC.sol";
import "@ensdomains/dnssec-oracle/contracts/BytesUtils.sol";
import "@ensdomains/dnssec-oracle/contracts/RRUtils.sol";

contract Registrar {

    using BytesUtils for bytes;
    using RRUtils for *;
    using Buffer for Buffer.buffer;

    struct Record {
        address submitter;
        address addr;
        bytes proof;
        bytes name;
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

    event Submitted(bytes32 indexed node, address indexed owner, bytes dnsname);
    event Claim(bytes32 indexed node, address indexed owner, bytes dnsname);

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
        (label, node) = getLabels(name);

        records[keccak256(node, label)] = Record({
            submitter: msg.sender,
            addr: addr,
            proof: proof,
            name: name,
            label: label,
            node: node,
            submitted: now
        });

        emit Submitted(keccak256(abi.encodePacked(node, label)), addr, name);
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

        emit Claim(keccak256(abi.encodePacked(rootNode, label)), addr, record.name);
    }

    /// @notice This function allows a user to challenge the validity of a DNSSEC proof submitted.
    function challenge(bytes32 node) external {
        Record storage record = records[node];

        require(record.submitted + cooldown > now);

        require(record.addr != getOwnerAddress(record.name, record.proof));

        delete records[node];
    }

    function getLabels(bytes memory name) internal view returns (bytes32, bytes32) {
        uint len = name.readUint8(0);
        uint second = name.readUint8(len + 1);

        require(name.readUint8(len + second + 2) == 0);

        return (name.keccak(1, len), keccak256(bytes32(0), name.keccak(2 + len, second)));
    }

    function getOwnerAddress(bytes memory name, bytes memory proof) internal view returns (address) {
        // Add "_ens." to the front of the name.
        Buffer.buffer memory buf;
        buf.init(name.length + 5);
        buf.append("\x04_ens");
        buf.append(name);
        bytes20 hash;
        uint64 inserted;
        // Check the provided TXT record has been validated by the oracle
        (, inserted, hash) = oracle.rrdata(TYPE_TXT, buf.buf);
        if (hash == bytes20(0) && proof.length == 0) return 0;

        require(hash == bytes20(keccak256(proof)));

        for (RRUtils.RRIterator memory iter = proof.iterateRRs(0); !iter.done(); iter.next()) {
            require(inserted + iter.ttl >= now, "DNS record is stale; refresh or delete it before proceeding.");

            address addr = parseRR(proof, iter.rdataOffset);
            if (addr != 0) {
                return addr;
            }
        }

        return 0;
    }

    function parseRR(bytes memory rdata, uint idx) internal pure returns (address) {
        while (idx < rdata.length) {
            uint len = rdata.readUint8(idx); idx += 1;
            address addr = parseString(rdata, idx, len);
            if (addr != 0) return addr;
            idx += len;
        }

        return 0;
    }

    function parseString(bytes memory str, uint idx, uint len) internal pure returns (address) {
        // TODO: More robust parsing that handles whitespace and multiple key/value pairs
        if (str.readUint32(idx) != 0x613d3078) return 0; // 0x613d3078 == 'a=0x'
        if (len < 44) return 0;
        return hexToAddress(str, idx + 4);
    }

    function hexToAddress(bytes memory str, uint idx) internal pure returns (address) {
        if (str.length - idx < 40) return 0;
        uint ret = 0;
        for (uint i = idx; i < idx + 40; i++) {
            ret <<= 4;
            uint x = str.readUint8(i);
            if (x >= 48 && x < 58) {
                ret |= x - 48;
            } else if (x >= 65 && x < 71) {
                ret |= x - 55;
            } else if (x >= 97 && x < 103) {
                ret |= x - 87;
            } else {
                return 0;
            }
        }
        return address(ret);
    }
}
