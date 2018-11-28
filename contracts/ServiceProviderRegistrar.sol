pragma solidity ^0.4.24;

import "./AbstractRegistrar.sol";

contract ServiceProviderRegistrar is AbstractRegistrar {

    struct Balance {
        uint256 staked;
        uint256 locked;
    }

    mapping (address => Balance) public balances;

    function () external payable {
        balances[msg.sender].staked += msg.value;
    }

    function withdraw(uint256 amount) external {
        Balance storage balance = balances[msg.sender];
        require(balance.staked - balance.locked >= amount);

        balance.staked = balance.staked - amount;
        msg.sender.transfer(amount);

        // @todo amount
    }

    function submit(bytes name, bytes proof, address addr) external payable {
        Balance storage balance = balances[msg.sender];

        require(balance.staked - balance.locked >= deposit);

        balance.locked = balance.locked + deposit;
        AbstractRegistrar._submit(name, proof, addr);
    }

    function commit(bytes32 node) external {
        AbstractRegistrar._commit(node);

        Record storage record = records[node];

        Balance storage balance = balances[record.submitter];
        balance.locked = balance.locked - deposit;
    }

    function challenge(bytes32 node, bytes proof, bytes name) external {
        AbstractRegistrar._challenge(node, proof, name);

        Record storage record = records[node];

        Balance storage balance = balances[record.submitter];
        balance.locked = balance.locked - deposit;
        balance.staked = balance.staked - deposit;
    }
}
