// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

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

interface IBEP20IDOFactory{
    function collectICOTokenomics(string memory name, string memory symbol, uint decimal ,uint totalSupply, address ICOOwner, address ICOAddress) external;
    function collectICOInfo(address ICOAddress, uint softCap, uint hardCap ,uint preSaleRate, uint startTime, uint endTime,bool isWhiteList,bool isVesting) external;
    function collectMinMaxRange(address ICOAddress,uint minBUSD,uint maxBUSD) external;
}

contract ICOCreation is Ownable{
    using SafeMath for uint256;
    uint time;
    uint vestingCounterId ;
    uint public totalBUSDToken;
    uint totalVestingRound = 4;
    uint lockingPeriod = 2 minutes;   
    address public icoOwner;
    address public IDOContractAddress;
    IBEP20IDOFactory factoryContract;
    address[] public allBuyerAddress;
    IBEP20 BUSD_token;
    IBEP20 ICO_token;

    struct IcoInformation{
        address icoOwner;
        string name;
        string symbol;
        uint decimal;
        string exchangeTokenName;
        uint totalSupply;
        uint softCap;
        uint hardCap;
        uint preSaleRate;
        uint startTime;
        uint endTime;
        address IcoAddress;
    }   
    
    IcoInformation public icoInfo;

    struct rangeMinMax{
        uint minBUSD;
        uint maxBUSD;
    }

    rangeMinMax public RangeMinMax;

    struct buyerInfo{
        uint busdAmount;
    }

    mapping(address=>buyerInfo) public buyerInformation;

    struct whitelist{
        bool allow;
    }

    mapping(address=>whitelist) public whitelistInformation;

    struct AddInfo{
        bool isWhiteList;
        bool isVesting;
    }

    AddInfo public additionalInfo;
    
    constructor(uint _softCap,uint _hardCap,uint _preSaleRate,uint _startTime,uint _endTime,address busdAddr,address icoToken ,bool _isWhiteList,bool _isVesting,address _IDOContractAddress){

        require(_softCap > 0,"Soft Cap should be greater than zero");  
        require(_hardCap > _softCap,"Hard Cap should be greater than Soft Cap"); 
        require(_preSaleRate > 0,"Presale Rate can not be zero");
        require(_startTime >= block.timestamp,"Start Time should be greater than or equal to current time");
        require(_endTime > _startTime,"End time should be greater than start time");  

        icoOwner = _msgSender();
        BUSD_token = IBEP20(busdAddr);
        ICO_token = IBEP20(icoToken);
        IDOContractAddress = _IDOContractAddress;
        factoryContract = IBEP20IDOFactory(IDOContractAddress);
    
        icoInfo = IcoInformation(msg.sender,ICO_token.name(),ICO_token.symbol(),ICO_token.decimals(),"BUSD",ICO_token.totalSupply(),_softCap,_hardCap,_preSaleRate,_startTime,_endTime, address(this));
        additionalInfo = AddInfo(_isWhiteList,_isVesting);

        factoryContract.collectICOTokenomics(ICO_token.name(), ICO_token.symbol(), ICO_token.decimals() ,ICO_token.totalSupply(), msg.sender, address(this)) ;
        factoryContract.collectICOInfo(address(this), _softCap, _hardCap , _preSaleRate, _startTime, _endTime, _isWhiteList, _isVesting);
       
    }   

    function setMinMaxRange(uint _minrange,uint _maxrange) public onlyOwner returns(bool){
        require(icoInfo.startTime>block.timestamp,"This ICO is already started");

        RangeMinMax = rangeMinMax(_minrange,_maxrange);

        factoryContract.collectMinMaxRange(address(this),_minrange,_maxrange);
        return true;
    }

    //-------------Functions to update ICO features-Only by ICO Owner-------------------

    //Ico Owner can update the White List and Vesting state.
    function updateAdditionalInfo(bool _isWhiteList,bool _isVesting) public onlyOwner{
        require(icoInfo.startTime>block.timestamp,"This ICO is already started");
        additionalInfo.isWhiteList = _isWhiteList;
        additionalInfo.isVesting = _isVesting;
        factoryContract.collectICOInfo(address(this), icoInfo.softCap, icoInfo.hardCap , icoInfo.preSaleRate, icoInfo.startTime, icoInfo.endTime, additionalInfo.isWhiteList, additionalInfo.isVesting);
    }

    //Ico Owner can update the Start time and End Time.
    function updateStartEndTime(uint _startTime, uint _endTime) public onlyOwner{
        require(icoInfo.startTime>block.timestamp,"This ICO is already started");
        require(_endTime > _startTime,"End Time should be greater than current time");
        icoInfo.startTime = _startTime;
        icoInfo.endTime = _endTime;
        factoryContract.collectICOInfo(address(this), icoInfo.softCap, icoInfo.hardCap , icoInfo.preSaleRate, icoInfo.startTime, icoInfo.endTime, additionalInfo.isWhiteList, additionalInfo.isVesting);
    }

    //Ico Owner can update the Pre Sale Rate.
    function updatePreSaleRate(uint _preSaleRate) public onlyOwner{
        require(_preSaleRate > 0,"Presale Rate should be greater than zero");
        require(icoInfo.startTime>block.timestamp,"This ICO is already started");
        icoInfo.preSaleRate = _preSaleRate;
        factoryContract.collectICOInfo(address(this), icoInfo.softCap, icoInfo.hardCap , icoInfo.preSaleRate, icoInfo.startTime, icoInfo.endTime, additionalInfo.isWhiteList, additionalInfo.isVesting);
    }

    //Ico Owner can update the Soft Cap and Hard Cap.
    function updateSoftHardCap(uint _softCap, uint _hardCap) public onlyOwner{
        require(_softCap > 0 && _hardCap > 0,"Soft Cap and Hard Cap should be greater than zero");
        require(_softCap < _hardCap,"Soft Cap should be less than Hard Cap");
        require(icoInfo.startTime > block.timestamp,"This ICO is already started");
        icoInfo.softCap = _softCap;
        icoInfo.hardCap = _hardCap;
        factoryContract.collectICOInfo(address(this), icoInfo.softCap, icoInfo.hardCap , icoInfo.preSaleRate, icoInfo.startTime, icoInfo.endTime, additionalInfo.isWhiteList, additionalInfo.isVesting);
    }

    //----------------End of Update Functions---------------------
    
    // Anyone can check Soft Cap reached or not
    function isSoftCapReach() public view returns (bool) {
        // check soft cap
        if (totalBUSDToken >= icoInfo.softCap) {
            return true;
        } else {
            return false;
        }
    }

    // Anyone can check Hard Cap reached or not
    function isHardCapReach() public view returns (bool) {
        // check hard cap
        if (totalBUSDToken >= icoInfo.hardCap) {
            return true;
        } 
        else {
            return false;
        }
    }

    function isICOOver() public view returns(bool){
        if (icoInfo.endTime <= block.timestamp || isHardCapReach()==true){
            return true;
        }
        else{
            return false;
        }
    }

    //------------------Functions to Check Tokens-------------------

    function ICOtoken() public view returns(uint){
        return ICO_token.balanceOf(msg.sender);
    }

    function BUSDtoken() public view returns(uint){
        return BUSD_token.balanceOf(msg.sender);
    }

    function contractICOToken() public view returns(uint){
        return ICO_token.balanceOf(address(this));
    }

    function contractBUSDToken() public view returns(uint){
        return BUSD_token.balanceOf(address(this));
    }

    //------------------Functions for White Listed User---------------------------

    //Function to Add White Listed User

    function whiteListedUser(address[] memory _buyers) public onlyOwner returns(bool){
        for(uint i=0 ; i<_buyers.length ; i++){
            if(whitelistInformation[_buyers[i]].allow == false){
                    whitelistInformation[_buyers[i]].allow = true;
            }
        }
        return true;
    }

    //Function to remove White Listed User

    function whiteListedUserRemove(address[] memory _buyers) public onlyOwner returns(bool){
        for(uint i=0 ; i<_buyers.length ; i++){
            if(whitelistInformation[_buyers[i]].allow == true){
               whitelistInformation[_buyers[i]].allow = false;
            }
        }
        return true;
    }

    //Function to buy tokens 

    function Buy(uint _BusdToken) public returns(bool){
        require(isICOOver()==false,"ICO already end.");
        require(msg.sender != address(0),"Null Address can't buy tokens");
        require(icoInfo.startTime <= block.timestamp,"Please wait for ICO to start");
        require(_BusdToken >= RangeMinMax.minBUSD && _BusdToken <= RangeMinMax.maxBUSD,"It should be between the range of Minimum BUSD and Maximum BUSD");
        require(buyerInformation[msg.sender].busdAmount <= RangeMinMax.maxBUSD,"You cannot buy more than Maximum BUSD of tokens");
        require(BUSD_token.allowance(msg.sender,address(this))>= _BusdToken ,"Do not have sufficient allowance");

        if(additionalInfo.isWhiteList == true && additionalInfo.isVesting == true){
            require(whitelistInformation[msg.sender].allow == true,"Sorry You are not a white listed User");
            BUSD_token.transferFrom(msg.sender, address(this),_BusdToken);
                       
        }

        else if(additionalInfo.isVesting == true && additionalInfo.isWhiteList == false){
            BUSD_token.transferFrom(msg.sender, address(this),_BusdToken);
        }

        else if(additionalInfo.isWhiteList == true && additionalInfo.isVesting == false){
            require(whitelistInformation[msg.sender].allow == true,"Sorry You are not a white listed User");
            BUSD_token.transferFrom(msg.sender, address(this),_BusdToken);
            ICO_token.transfer(msg.sender, (_BusdToken * icoInfo.preSaleRate)/1000000000000000000); 
        }

        else{
            BUSD_token.transferFrom(msg.sender, address(this),_BusdToken);
            ICO_token.transfer(msg.sender, (_BusdToken * icoInfo.preSaleRate)/1000000000000000000); 
        }
        
        totalBUSDToken += _BusdToken;

        if(buyerInformation[msg.sender].busdAmount == 0){
            allBuyerAddress.push(msg.sender);
        }

        buyerInformation[msg.sender].busdAmount += _BusdToken;
       return true;
    }

    //Function to takeout BUSD token out of the contract(to admin)

    function transferTOAdmin() public onlyOwner returns(bool){
        require(isSoftCapReach()==true,"You can not take busd token out of this contract");
        require(isICOOver()==true,"Please wait for ICO to end");
        BUSD_token.transfer(msg.sender, BUSD_token.balanceOf(address(this)));
        return true;
    }

    //Function to take back your Busd Token

    function refund() public returns(bool){
        require(isSoftCapReach()==false,"You can not take refund");
        require(isICOOver()==true,"Please wait for ICO to end");
        require(buyerInformation[msg.sender].busdAmount > 0,"You are not a buyer");
        BUSD_token.transfer(msg.sender, buyerInformation[msg.sender].busdAmount);   
        return true;           
    }

    //Function for Vesting(only ICO owner can call this.

    function vesting() public onlyOwner returns(bool){
        
        require(isICOOver() == true,"Please wait for ICO to end");
        require(additionalInfo.isVesting == true,"Vesting is not allowed for this ICO");
        require(vestingCounterId <= totalVestingRound,"All vesting round is complete");

        
        if (vestingCounterId == 0) {
            require(block.timestamp > icoInfo.endTime + lockingPeriod, "First Vesting Can be start after locking period.");
        }
        // after locking period
        time = icoInfo.endTime + lockingPeriod + vestingCounterId * lockingPeriod;

        if (block.timestamp > time){
            for(uint256 i=0; i<allBuyerAddress.length; i++)
            {  
                if(vestingCounterId < totalVestingRound){
                    ICO_token.transfer(allBuyerAddress[i], 25*(buyerInformation[allBuyerAddress[i]].busdAmount * icoInfo.preSaleRate)/100000000000000000000);
                    
                }
            }
            vestingCounterId += 1;

        }else{
            require(false, "Can not call before locking period");
        }
        return true;
        
    }

 }

 //1000000000000000000