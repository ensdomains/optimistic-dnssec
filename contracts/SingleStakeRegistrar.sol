pragma solidity ^0.4.24;

import "./AbstractRegistrar.sol";

contract ServiceProviderRegistrar is AbstractRegistrar {

    mapping (address => uint256) public openSubmissions;
    mapping (address => bool) public staked;

    event Staked(address indexed staker, uint256 amount);
    event Unstaked(address indexed staker, uint256 amount);

    function () external payable {
        require(staked[msg.sender] = false);
        require(msg.value == stake);

        staked[msg.sender] = true;
        emit Staked(msg.sender, msg.value);
    }

    function unstake() external {
        require(openSubmissions[msg.sender] == 0);
        require(staked[msg.sender]);

        staked[msg.sender] = false;

        msg.sender.transfer(stake);

        emit Unstaked(msg.sender, stake);
    }

    function submit(bytes name, bytes proof, address addr) external payable {
        require(staked[msg.sender]);

        openSubmissions[msg.sender] += 1;

        AbstractRegistrar._submit(name, proof, addr);
    }

    function commit(bytes name) external {
        bytes32 node = AbstractRegistrar._commit(name);
        openSubmissions[msg.sender] -= 1;
    }

    function challenge(bytes name, bytes proof) external {
        bytes32 namehash = AbstractRegistrar._challenge(name, proof);
        openSubmissions[msg.sender] -= 1;
    }
}
