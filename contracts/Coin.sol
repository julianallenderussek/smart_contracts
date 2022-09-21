//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Coin {
  address public minter;
  mapping (address => uint) public balances;

  constructor() {
    minter = msg.sender;
  }

  event Sent(address from, address to, uint amount);

  function mint(address receiver, uint amount)  public {
    require(msg.sender == minter);
    balances[receiver] += amount;
  }

  error InsufficientBalance(uint requested, uint availabe );

  function send(address receiver, uint amount) public {
    if (amount > balances[msg.sender]) {
      revert InsufficientBalance({
        requested: amount,
        availabe: balances[msg.sender]
      });
    }
    balances[msg.sender] -= amount;
    balances[receiver] += amount;
    emit Sent(msg.sender, receiver, amount);
  }

}