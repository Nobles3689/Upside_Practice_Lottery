// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Lottery{

    uint16 public winningNumber;//당첨번호
    address[] public contestants;//참가자목록
    address[] public winners;//당첨자목룍
    uint16[] public num;//참가자가 구매한 번호
    uint public balance;//누적 상금
    uint public deadline;//기한
    uint public remain_winner;//상금 수령 안한 당첨자 수

    constructor() {
        deadline = block.timestamp + 24 hours;//구매 기한은 로또 생성후 24시간
        winningNumber = type(uint16).max;
        //testRollover에서 winningNumber에 1을 더해 당첨 실패를 테스트 하는데
        //이때, winningNumber가 type(uint16).max가 나오면 오버플로우 발생할 수 있어서
        //type(uint16).max는 초기값 - 추첨 전이라는 의미를 갖도록 설정하고 추첨에서는 나오지 않게 설정
    }

    function buy(uint16 _num) payable external{
        if(winningNumber != type(uint16).max){
            init();
            //번호가 추첨 전이 아니라면 초기화
        }
        //기한 확인
        require(deadline > block.timestamp, "The deadline is over.");
        //구매 금액 제한
        require(msg.value == 0.1 ether, "The wrong amount of money");
        //중복구매 막기
        for(uint i = 0; i<contestants.length; i++){
            if(contestants[i] == msg.sender){
                revert("You've already bought it.");
            }
        }
        //참가자 추가
        contestants.push(msg.sender);
        //번호 저장
        num.push(_num);
        //누적 금액 추가
        balance += msg.value;
    }

    function draw() external{
        //기한 확인
        require(deadline <= block.timestamp, "Not yet.");
        //당첨번호 초기화 확인(중복 추첨 막기)
        require(winningNumber == type(uint16).max);
        //번호 추첨
        winningNumber = random();
        //당첨자 확인
        for(uint i = 0; i<contestants.length; i++){
            if(num[i] == winningNumber){
                winners.push(contestants[i]);
            }
        }
        //당첨자 수 초기화
        remain_winner = winners.length;
    }

    function claim() payable external{
        //기한 확인
        require(deadline <= block.timestamp, "Not yet.");
        //추첨 여부 확인
        require(winningNumber != type(uint16).max);
        //호출한 주소가 받을 상금 초기화
        uint prize = 0;
        //당첨자 목록에 있다면
        for(uint i = 0; i<winners.length; i++){
            if(msg.sender == winners[i]){
                //중복 수령 방지
                winners[i] = address(0);
                //수령 금액 계산
                prize = balance / remain_winner;
                //누적금액에서 차감
                balance -= prize;
                //수령안한 당첨자 감소
                remain_winner--;
                break;
            }
        }
        //당첨금 지금 & 지급 확인
        (bool success, ) = payable(msg.sender).call{value: prize}("");
        require(success, "claim error");
    }

    function init() public{
        //리스트들 초기화
        for(uint i = 0; i<winners.length; i++){
            winners.pop();
        }
        for(uint i = 0; i<contestants.length; i++){
            contestants.pop();
            num.pop();
        }
        //마감 기한도 초기화
        deadline = block.timestamp + 24 hours;
        //당첨 번호 초기화
        winningNumber = type(uint16).max;
    }

    //블록 프로퍼티를 사용해 단순한 난수 생성
    function random() private view returns (uint16) {
        return uint16(uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender)))) % type(uint16).max;
    }

}