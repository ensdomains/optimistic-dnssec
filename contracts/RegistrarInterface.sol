pragma solidity ^0.4.25;

interface RegistrarInterface {

    function commit(bytes name) external;
    function challenge(bytes name, bytes proof) external;
    function submit(bytes name, bytes proof, address addr) external;

}
