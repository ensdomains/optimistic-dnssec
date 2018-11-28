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

        // @todo event
    }

    function submit(bytes name, bytes proof, address addr) external payable {
        Balance storage balance = balances[msg.sender];

        require(balance.staked - balance.locked >= stake);
        balance.locked = balance.locked + stake;

        AbstractRegistrar._submit(name, proof, addr);
    }

    function commit(bytes32 node) external {
        AbstractRegistrar._commit(node);

        Balance storage balance = balances[records[node].submitter];
        balance.locked = balance.locked - stake;
    }

    function challenge(bytes32 node, bytes proof, bytes name) external {
        AbstractRegistrar._challenge(node, proof, name);

        Balance storage balance = balances[records[node].submitter];
        balance.locked = balance.locked - stake;
        balance.staked = balance.staked - stake;
    }
}
