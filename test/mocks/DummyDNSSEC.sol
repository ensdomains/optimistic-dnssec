pragma solidity ^0.4.17;

import "@ensdomains/ens/contracts/ENSRegistry.sol";

contract DummyDNSSEC {

    uint16 expectedType;
    bytes expectedName;
    uint32 inception;
    uint64 inserted;
    bytes20 hash;

    function setData(uint16 _expectedType, bytes _expectedName, uint32 _inception, uint64 _inserted, bytes _proof) public {
        expectedType = _expectedType;
        expectedName = _expectedName;
        inception = _inception;
        inserted = _inserted;

        if (_proof.length != 0) {
            hash = bytes20(keccak256(_proof));
        } else {
            hash = bytes20(0);
        }
    }

    function rrdata(uint16 dnstype, bytes name) public constant returns(uint32, uint64, bytes20) {
        require(dnstype == expectedType);
        require(keccak256(name) == keccak256(expectedName));
        return (inception, inserted, hash);
    }
}
