pragma solidity ^0.4.24;

import "./AbstractRegistrar.sol";

contract ServiceProviderRegistrar is AbstractRegistrar {

    struct Balance {
        uint256 staked;
        uint256 locked;
    }

    mapping (address => Balance) public balances;

    event Staked(address indexed staker, uint256 amount);
    event Unstaked(address indexed staker, uint256 amount);

    function () external payable {
        balances[msg.sender].staked += msg.value;
        emit Staked(msg.sender, msg.value);
    }

    function unstake(uint256 amount) external {
        require(withdrawable(msg.sender) >= amount);

        balances[msg.sender].staked -= amount;
        msg.sender.transfer(amount);

        emit Unstaked(msg.sender, amount);
    }

    function submit(bytes name, bytes proof, address addr) external payable {
        require(withdrawable(msg.sender) >= stake);
        balances[msg.sender].locked -= stake;

        AbstractRegistrar._submit(name, proof, addr);
    }

    function commit(bytes32 node) external {
        AbstractRegistrar._commit(node);

        balances[records[node].submitter].locked -= stake;
    }

    function challenge(bytes32 node, bytes proof, bytes name) external {
        AbstractRegistrar._challenge(node, proof, name);

        Balance storage balance = balances[records[node].submitter];
        balance.locked = balance.locked - stake;
        balance.staked = balance.staked - stake;
    }

    function withdrawable(address provider) public returns (uint) {
        Balance storage balance = balances[provider];
        return (balance.staked - balance.locked);
    }
}
