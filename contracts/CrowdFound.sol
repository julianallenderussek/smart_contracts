//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract CrowdFound {
  address public owner;
  address payable public fundRecepient;
  uint public minimumToRaise;
  string campaginURL;
  //Structures
  enum State { Fundraising, ExpiredRefund, Successful}
  
  struct Contribution {
    uint amount;
    address payable contributor;
  }

  State public state = State.Fundraising;
  uint public totalRaised;
  uint public raiseBy;
  uint public completeAt;
  Contribution[] contributions;

  //Events
    event LogFundingReceived(address addr,uint amount, uint currentTotal);
    event LogRecipientPaid(address recipientAddr);
  
  //Modifiers
  modifier inState(State _state) {
    require (state == _state);
    _;
  }

  modifier isOwner() {
    require (msg.sender == owner);
    _;
  }

  modifier atEndOfLifeCycle() {
    require (((state == State.ExpiredRefund || state == State.Successful) && completeAt + 4 weeks < block.timestamp));
    _;
  }

  function crowdFund(uint timeInHoursForFundingRaising, string memory _campaignURL, address payable _fundRecipient, uint _minimumToRaise) public {
    owner = msg.sender;
    fundRecepient= _fundRecipient;
    campaginURL = _campaignURL;
    minimumToRaise = _minimumToRaise;
    raiseBy = block.timestamp + (timeInHoursForFundingRaising * 1 hours);
  }
  
  function contribute(uint _amt) public payable inState(State.Fundraising) returns(uint id){
    contributions.push(Contribution({amount:_amt, contributor: payable (msg.sender)}));
    totalRaised+= _amt;
    emit LogFundingReceived(msg.sender, _amt, totalRaised);
    checkIfFundingCompleteOrExpired();
    return contributions.length -1;
  }

  function checkIfFundingCompleteOrExpired() public {
    if (totalRaised>minimumToRaise) {
      state = State.Successful;
      payOut();
    }
    else if(block.timestamp > raiseBy) {
      state = State.ExpiredRefund;
    }
    completeAt = block.timestamp;
  }

  function payOut() public inState(State.Successful) {
    fundRecepient.transfer(address(this).balance);
    emit LogRecipientPaid(fundRecepient);
  }

  function getRefund(uint id) inState(State.ExpiredRefund) public returns(bool) {
    require(contributions[id].amount != 0);
    uint amountToRefund = contributions[id].amount;

    //Zero the amount BEFORE the transfer!
    contributions[id].amount = 0;
    contributions[id].contributor.transfer(amountToRefund);
    return true;
  }

  //Contract owner receives any ETHER remaining in the contract
  //Removes all bytecode from the contract address
  function removeContract() public isOwner() atEndOfLifeCycle() {
    selfdestruct(payable(msg.sender));
  }
  
  
}