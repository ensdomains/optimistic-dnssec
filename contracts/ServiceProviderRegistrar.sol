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

    constructor(ENS ens, DNSSEC dnssec, uint256 cooldown, uint256 stake)
        public
        AbstractRegistrar(ens, dnssec, cooldown, stake) {}

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

    function commit(bytes name) external {
        bytes32 node = AbstractRegistrar._commit(name);

        balances[records[node].submitter].locked -= stake;
    }

    function challenge(bytes name, bytes proof) external {
        bytes32 namehash = AbstractRegistrar._challenge(name, proof);

        Balance storage balance = balances[records[namehash].submitter];
        balance.locked = balance.locked - stake;
        balance.staked = balance.staked - stake;
    }

    function withdrawable(address provider) public returns (uint) {
        Balance storage balance = balances[provider];
        return (balance.staked - balance.locked);
    }
}
