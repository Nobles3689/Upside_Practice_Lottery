// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Lottery{

    uint16 public winningNumber;
    address[] public contestants;
    address[] public winners;
    uint16[] public num;
    uint public balance;
    uint public deadline;

    constructor() {
        deadline = block.timestamp + 24 hours;
        winningNumber = type(uint16).max;
    }

    function buy(uint16 _num) payable external{
        if(winningNumber != type(uint16).max){
            init();
        }

        require(deadline > block.timestamp, "The deadline is over.");
        require(msg.value == 0.1 ether, "The wrong amount of money");
        for(uint i = 0; i<contestants.length; i++){
            if(contestants[i] == msg.sender){
                revert("You've already bought it.");
            }
        }
        contestants.push(msg.sender);
        num.push(_num);
        balance += msg.value;
    }

    function draw() external{
        require(deadline <= block.timestamp, "Not yet.");
        require(winningNumber == type(uint16).max);
        winningNumber = random();
        
        for(uint i = 0; i<contestants.length; i++){
            if(num[i] == winningNumber){
                winners.push(contestants[i]);
            }
        }
    }

    function claim() payable external{
        require(deadline <= block.timestamp, "Not yet.");
        require(winningNumber != type(uint16).max);
        uint prize = 0;
        uint winners_num = winners.length;
        for(uint i = 0; i<winners.length; i++){
            if(msg.sender == winners[i]){
                prize = balance / winners_num;
                winners[i] = address(0);
                
            }
        }
        payable(msg.sender).call{value: prize}("");
    }

    function init() public{
        for(uint i = 0; i<winners.length; i++){
            winners.pop();
        }
        for(uint i = 0; i<contestants.length; i++){
            contestants.pop();
            num.pop();
        }

        deadline = block.timestamp + 24 hours;
        winningNumber = type(uint16).max;
    }

    //블록 프로퍼티를 사용해 단순한 난수 생성
    function random() private view returns (uint16) {
        return uint16(uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender)))) % type(uint16).max;
    }

}