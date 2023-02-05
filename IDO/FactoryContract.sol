//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

contract Factory{

    struct Tokenomics {
        string name;
        string symbol;
        uint decimal;
        uint totalSupply;
        address ICOOwner;
        address ICOAddress;
        string exchangeTokenName;
    }

    mapping(address => Tokenomics) public TokenomicsData;
    Tokenomics[] TokenomicsDataSet;

    struct ICOInfo{
        address ICOAddress;
        uint softCap;
        uint hardCap;
        uint preSaleRate;
        uint startTime;
        uint endTime;
        bool isWhiteList;
        bool isVesting;
    }

    mapping(address => ICOInfo) public ICOInfoData;
    ICOInfo[] ICOInfoDataSet;

    struct AllICOAddress {
        address ICOAddress;
    }
    AllICOAddress[] AllICOAddresses;

    struct MinMax{
        address ICOAddress;
        uint minBUSD;
        uint maxBUSD;
    }
    mapping(address => MinMax) public MinMaxData;

    function collectICOTokenomics(string memory name, string memory symbol, uint decimal ,uint totalSupply, address ICOOwner, address ICOAddress) public{

        TokenomicsData[ICOAddress] = Tokenomics(name,symbol,decimal,totalSupply,ICOOwner,ICOAddress,"BUSD") ;
        
        Tokenomics memory tempTokenomics;
        tempTokenomics.name = name;
        tempTokenomics.symbol = symbol;  
        tempTokenomics.decimal = decimal;
        tempTokenomics.totalSupply = totalSupply;
        tempTokenomics.ICOOwner = ICOOwner;
        tempTokenomics.ICOAddress = ICOAddress;  
        tempTokenomics.exchangeTokenName = "BUSD";
        
        TokenomicsDataSet.push(tempTokenomics);
    }

    function collectICOInfo(address ICOAddress, uint softCap, uint hardCap ,uint preSaleRate, uint startTime, uint endTime,bool isWhiteList,bool isVesting) public{

        ICOInfoData[ICOAddress] = ICOInfo(ICOAddress,softCap,hardCap,preSaleRate,startTime,endTime,isWhiteList,isVesting) ;
        
        ICOInfo memory tempICOInfo;
        tempICOInfo.ICOAddress = ICOAddress;
        tempICOInfo.softCap = softCap;  
        tempICOInfo.hardCap = hardCap;
        tempICOInfo.preSaleRate = preSaleRate;
        tempICOInfo.startTime = startTime;
        tempICOInfo.endTime = endTime;  
        tempICOInfo.isWhiteList = isWhiteList;
        tempICOInfo.isVesting = isVesting;      
        ICOInfoDataSet.push(tempICOInfo);

        AllICOAddress memory tempAllICOAddress;
        tempAllICOAddress.ICOAddress = ICOAddress;
        AllICOAddresses.push(tempAllICOAddress);
    }

    function collectMinMaxRange(address ICOAddress,uint minBUSD,uint maxBUSD) public{
        MinMaxData[ICOAddress] = MinMax(ICOAddress,minBUSD,maxBUSD) ;
    }

    function getICOs() public view returns(AllICOAddress[] memory) {
        return(AllICOAddresses);
    }

}

