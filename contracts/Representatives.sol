// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;


interface InterfaceDigi {
    function balanceOf(address tokenOwner) external view returns (uint balance);

}

contract Representatives {
    address public digitrade;
    address public tokenAddress;
    uint representativeMin;
    uint repMaturation;
    mapping(address => Representative )  public registeredReps;


    struct Representative{
        address _rep;
        uint _startBlock;
        uint _unlockBlock;
    }



    constructor() {
        digitrade = 0x5d22916B1BE652cD7B904b896C4EdE461A78CcC4;
        repMaturation = 10;  //for testing = 10..about 90 seconds
        representativeMin = 10000 * 10 * 18; // 10000 Digitrade
    }

    modifier onlyDigitrade(){
        require(msg.sender == digitrade);
        _;
    }

    function setTokenContractAddress(address _digitrade) public onlyDigitrade{
        tokenAddress = _digitrade;
    }

    function getUnlockBlock() public view returns (uint){
        return registeredReps[msg.sender]._unlockBlock;
    }

    function getStartBlock() public view returns (uint) {
        return registeredReps[msg.sender]._startBlock;
    }

    function getRep() public view returns (address _repAddress){
        if(msg.sender == registeredReps[msg.sender]._rep){
           _repAddress = msg.sender;
        }
        return _repAddress;

    }

    function getRepMin() public view returns (uint){
        return representativeMin;
    }

    function getMaturationTime() public view returns (uint) {
        return repMaturation;
    }

    function registerRep(address _rep) public {
      require(msg.sender == _rep);
      require(InterfaceDigi(tokenAddress).balanceOf(msg.sender) > representativeMin, "Balance under 10K DGT");
      uint _unlockBlock = block.number + repMaturation;  //unlocks after 30 days or so
      registeredReps[_rep] = Representative(_rep,block.number, _unlockBlock);
    }

}
