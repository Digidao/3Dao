// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


interface IDigi {
    function balanceOf(address tokenOwner) external view returns (uint balance);

}

contract Representatives {
    address public tokenAddress;
    uint public representativeMin;
    uint public repMaturation;
    mapping(address => Representative )  public registeredReps;

    struct Representative{
        address _rep;
        uint _startBlock;
        uint _unlockBlock;
    }


    constructor() {
        repMaturation = 10;  //for testing = 10..about 90 seconds
        representativeMin = 10_000e18; // 10000 Digitrade
        //REAL tokenAddress = 0x0e8637266D6571a078384A6E3670A1aAA966166F;
        tokenAddress = 0xd9145CCE52D386f254917e481eB44e9943F39138;
    }

    function getBlock() public view returns (uint) {
        return block.number;
        }
    function getUnlockBlock(address _address) private view returns (uint){
        return registeredReps[_address]._unlockBlock;
        }

    function getStartBlock(address _address) private view returns (uint) {
        return registeredReps[_address]._startBlock;
    }

    function getRep(address _address) public view returns (bool isRep){
        require(getUnlockBlock(_address) > 0, "Not registered");
        require(block.number > getUnlockBlock(_address), "Registered but not a rep yet");
        return true;
    }

    function checkHodl(address _address) public view returns (bool isHodler){
        require(IDigi(tokenAddress).balanceOf(_address) > representativeMin, "Has not hodled");
        return true;
    }

    function removeNonHodlers(address _address) public{
       if(checkHodl(_address) == false){
        delete registeredReps[_address];
       }
    }

    function registerRep(address _rep) public {
      require(msg.sender == _rep);
      require(IDigi(tokenAddress).balanceOf(msg.sender) > representativeMin, "Balance under 10K DGT");
      uint _unlockBlock = block.number + repMaturation;  //unlocks after 30 days or so
      registeredReps[_rep] = Representative(_rep,block.number, _unlockBlock);
    }

}
