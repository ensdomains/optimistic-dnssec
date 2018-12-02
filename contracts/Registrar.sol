pragma solidity ^0.4.24;

import "./AbstractRegistrar.sol";

contract Registrar is AbstractRegistrar {

    function submit(bytes name, bytes proof, address addr) external payable {
        require(msg.value == stake);
        AbstractRegistrar._submit(name, proof, addr);
    }

    function commit(bytes32 node) external {
        AbstractRegistrar._commit(node);

        Record storage record = records[node];
        record.submitter.transfer(stake);
    }

    function challenge(bytes32 node, bytes proof, bytes name) external {
        AbstractRegistrar._challenge(node, proof, name);
    }
}