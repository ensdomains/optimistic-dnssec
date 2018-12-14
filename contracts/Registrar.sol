pragma solidity ^0.4.24;

import "./AbstractRegistrar.sol";

contract Registrar is AbstractRegistrar {

    function submit(bytes name, bytes proof, address addr) external payable {
        require(msg.value == stake);
        AbstractRegistrar._submit(name, proof, addr);
    }

    function commit(bytes name) external {
        bytes32 node = AbstractRegistrar._commit(name);

        Record storage record = records[node];
        record.submitter.transfer(stake);
    }

    function challenge(bytes name, bytes proof) external {
        AbstractRegistrar._challenge(name, proof);
    }
}