// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

library SafeMath {
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom( address sender, address recipient, uint256 amount ) external returns (bool);

    function decimals() external view  returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval( address indexed owner, address indexed spender, uint256 value );

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}

contract Stacking is Ownable{

    using SafeMath for uint256;
    IBEP20 ICO_token;
    uint public stackingPeriod_1;
    uint public stackingPeriod_2;
    uint public stackingPeriod_3;
    uint public stackingPeriod_4;
    uint public stackingPeriod_1APY;
    uint public stackingPeriod_2APY;
    uint public stackingPeriod_3APY;
    uint public stackingPeriod_4APY;
    uint public penalty;

    address[] public allStackingAddress;
    address ICOContractAddress;

    struct details{
        uint stackingPeriod;
        uint stackingPeriodAPY;
        uint InitialToken;
        uint maturityTime;
        uint APYToken;
        uint FinalToken;
    }
    mapping(address=>details) public stackingDetails;

    struct PenaltyDetails{
        uint maturityTime;
        uint penaltyPercent;
        uint initialToken;
        uint penaltyToken;
        uint FinalToken;
    }
    mapping(address=>PenaltyDetails) public penaltyDetails;

    constructor(uint _stackingPeriod_1,uint _stackingPeriod_1APY,uint _stackingPeriod_2,uint _stackingPeriod_2APY,uint _stackingPeriod_3,uint _stackingPeriod_3APY,uint _stackingPeriod_4,uint _stackingPeriod_4APY,uint _penalty,address _ICOContractAddress) {
        stackingPeriod_1 = _stackingPeriod_1;
        stackingPeriod_2 = _stackingPeriod_2;
        stackingPeriod_3 = _stackingPeriod_3;
        stackingPeriod_4 = _stackingPeriod_4;
        stackingPeriod_1APY = _stackingPeriod_1APY;
        stackingPeriod_2APY = _stackingPeriod_2APY;
        stackingPeriod_3APY = _stackingPeriod_3APY;
        stackingPeriod_4APY = _stackingPeriod_4APY;
        penalty = _penalty;

        ICOContractAddress = _ICOContractAddress;
        ICO_token = IBEP20(_ICOContractAddress);
    }

    function UpdateStacking(uint _stackingPeriod_1,uint _stackingPeriod_1APY,uint _stackingPeriod_2,uint _stackingPeriod_2APY,uint _stackingPeriod_3,uint _stackingPeriod_3APY,uint _stackingPeriod_4,uint _stackingPeriod_4APY) public onlyOwner returns(bool){
        stackingPeriod_1 = _stackingPeriod_1;
        stackingPeriod_2 = _stackingPeriod_2;
        stackingPeriod_3 = _stackingPeriod_3;
        stackingPeriod_4 = _stackingPeriod_4;
        stackingPeriod_1APY = _stackingPeriod_1APY;
        stackingPeriod_2APY = _stackingPeriod_2APY;
        stackingPeriod_3APY = _stackingPeriod_3APY;
        stackingPeriod_4APY = _stackingPeriod_4APY;

        return true;
    }

    function updatePenalty(uint _penalty) public onlyOwner returns(bool){
        penalty = _penalty;

        return true;
    }

    function stacking(uint _token, uint _stackingPeriod) public returns(bool){

        require( stackingDetails[msg.sender].InitialToken == 0,"You have already stacked the token");
        require(_token > 0,"Amount of token can not be zero ");

        uint totalAmount;
        uint MaturityTime;
        uint Interest;
        uint penaltytok;

        if(_stackingPeriod == stackingPeriod_1){

            Interest = (_token * stackingPeriod_1APY * stackingPeriod_1)/3155692600;
            totalAmount = _token + Interest;
            MaturityTime = block.timestamp + stackingPeriod_1 ;
            stackingDetails[msg.sender] = details(_stackingPeriod,stackingPeriod_1APY,_token,MaturityTime,Interest,totalAmount);

            ICO_token.transferFrom(msg.sender, address(this),_token);

            penaltytok = (_token * penalty )/100;
            totalAmount = _token - penaltytok;
            penaltyDetails[msg.sender] = PenaltyDetails(MaturityTime,penalty, _token, penaltytok, totalAmount);
            
        }

        else if(_stackingPeriod == stackingPeriod_2){

            Interest = (_token * stackingPeriod_2APY * stackingPeriod_2)/3155692600;
            totalAmount = _token + Interest;
            MaturityTime = block.timestamp + stackingPeriod_2 ;
            stackingDetails[msg.sender] = details(_stackingPeriod,stackingPeriod_2APY,_token,MaturityTime,Interest,totalAmount);

            ICO_token.transferFrom(msg.sender, address(this),_token);

            penaltytok = (_token * penalty )/100;
            totalAmount = _token - penaltytok;
            penaltyDetails[msg.sender] = PenaltyDetails(MaturityTime, penalty, _token, penaltytok, totalAmount);
            
        }

        else if(_stackingPeriod == stackingPeriod_3){

            Interest = (_token * stackingPeriod_3APY * stackingPeriod_3)/3155692600;
            totalAmount = _token + Interest;
            MaturityTime = block.timestamp + stackingPeriod_2 ;
            stackingDetails[msg.sender] = details(_stackingPeriod,stackingPeriod_3APY,_token,MaturityTime,Interest,totalAmount);

            ICO_token.transferFrom(msg.sender, address(this),_token);

            penaltytok = (_token * penalty )/100;
            totalAmount = _token - penaltytok;
            penaltyDetails[msg.sender] = PenaltyDetails(MaturityTime, penalty, _token, penaltytok, totalAmount);
            
        }

        else if(_stackingPeriod == stackingPeriod_4){

            Interest = (_token * stackingPeriod_4APY * stackingPeriod_4)/3155692600;
            totalAmount = _token + Interest;
            MaturityTime = block.timestamp + stackingPeriod_2 ;
            stackingDetails[msg.sender] = details(_stackingPeriod,stackingPeriod_4APY,_token,MaturityTime,Interest,totalAmount);

            ICO_token.transferFrom(msg.sender, address(this),_token);

            penaltytok = (_token * penalty )/100;
            totalAmount = _token - penaltytok;
            penaltyDetails[msg.sender] = PenaltyDetails(MaturityTime, penalty, _token, penaltytok, totalAmount);
            
        }

        else{
            require(false,"Please enter correct stacking period");
        }

        allStackingAddress.push(msg.sender);

        return true;
    }

    function Unstacking() public returns(bool){
        require(stackingDetails[msg.sender].InitialToken > 0,"You have not stacked any token");  

        ICO_token.transfer(msg.sender, penaltyDetails[msg.sender].FinalToken); 

        penaltyDetails[msg.sender] = PenaltyDetails(0, 0, 0, 0, 0);
        stackingDetails[msg.sender] = details(0,0,0,0,0,0);

        return true;  
    }

    function claimReward() public returns(bool){
        require(stackingDetails[msg.sender].InitialToken > 0,"You have not stacked any token");
        require(penaltyDetails[msg.sender].maturityTime <= block.timestamp,"Please wait for Stacking period to complete");

        ICO_token.transfer(msg.sender, stackingDetails[msg.sender].FinalToken); 

        penaltyDetails[msg.sender] = PenaltyDetails(0,0, 0, 0, 0);
        stackingDetails[msg.sender] = details(0,0,0,0,0,0);

        return true;
    }

    function retrieveStuckedERC20Token(address _tokenAddr,uint256 _amount,address _toWallet) public onlyOwner returns (bool) {
        IBEP20(_tokenAddr).transfer(_toWallet, _amount);
        return true;
    }

    function contractICOToken() public view returns(uint){
        return ICO_token.balanceOf(address(this));
    }

    function ICOtoken() public view returns(uint){
        return ICO_token.balanceOf(msg.sender);
    }
}

/*
  1 day = 86400
  15 days = 1296000
  30 days = 2592000
  45 days = 3888000
  60 days = 5184000
  90 days = 7776000
  120 days = 10368000
  360 days = 31104000

  */
