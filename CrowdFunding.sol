//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract crowdFunding{
    mapping(address => uint) public contributors;
    address public manager;
    uint public minimumAmount;
    uint public deadline;
    uint public target;
    uint public totalContributors;
    uint public raisedAmount;

    struct Request{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfvoters;
        mapping(address=>bool) voters;
    }
    mapping(uint => Request) public request;
    uint public numRequest;


    constructor(uint _target,uint _deadline){
        target = _target;
        deadline = block.timestamp+_deadline;//10sec + 3600sec
        minimumAmount = 100 wei;
        manager = msg.sender;
    }

    function sendEth() public payable {
        require(block.timestamp < deadline,"Deadline has passed");
        require(msg.value >= minimumAmount,"Minimum Amount is not met");

        if(contributors[msg.sender] == 0){
            totalContributors++;
        }
        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;
    }

    function getContractBalance()  public view returns(uint){
        return address(this).balance;
    }

    function refund() public{
        require(block.timestamp > deadline && target < raisedAmount,"You are not eligible for refund");
        require(contributors[msg.sender] > 0,"You are not eligible");
        address payable user = payable(msg.sender);
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender]=0;
    }

    modifier onlyManeger(){
        require(msg.sender == manager,"Only manager can call this function");
        _;
    }
    function createRequest(string memory _description,address payable _recipient,uint _value) public onlyManeger{
        Request storage newRequests = request[numRequest];
        numRequest++;
        newRequests.description = _description;
        newRequests.recipient= _recipient;
        newRequests.value = _value;
        newRequests.completed = false;
        newRequests.noOfvoters = 0;
    }
    function voteRequest(uint _requestNo) public{
        require(contributors[msg.sender] > 0,"You must be a contributor");
        Request storage thisRequest = request[_requestNo];
        require(thisRequest.voters[msg.sender] == false,"You have already voted");
        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfvoters++;
    }
    function makePayment(uint _requestNo) public onlyManeger{
        require(raisedAmount >= target);
        Request storage thisRequest = request[_requestNo];
        require(thisRequest.completed == false,"The request has been done");
        require(thisRequest.noOfvoters > totalContributors/2,"Majority does not support");
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true;
    }
}