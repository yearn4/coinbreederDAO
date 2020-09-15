// "SPDX-License-Identifier: UNLICENSED "
pragma solidity ^0.5.0;
// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

//Token: 0xa5ad38e743cc7be1ba8d4ee4c8dd0eed8c11cffe
// COVEX: 0xfb0745d393d4d72ccf319314e55aeb0a9661aa41
//ICO: 0x2a84956e86cc2aabfbe8e572496fad888791d7e1