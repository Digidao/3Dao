// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;


interface IDigi {
    function balanceOf(address tokenOwner) external view returns (uint balance);

}

contract Representatives {
    address public tokenAddress;
    uint public representativeMin;
    uint public repMaturation;
    mapping(address => Representative )  public registeredReps;
    address digi;

    struct Representative{
        address _rep;
        uint _startBlock;
        uint _unlockBlock;
    }


    constructor() {
        repMaturation = 10;  //for testing = 10..about 90 seconds
        representativeMin = 10_000e18; // 10000 Digitrade
        //REAL tokenAddress = 0x0e8637266D6571a078384A6E3670A1aAA966166F;
        tokenAddress = 0x7b96aF9Bd211cBf6BA5b0dd53aa61Dc5806b6AcE;
        digi = msg.sender;
    }

    modifier onlyDigi(){
        require(msg.sender == digi);
        _;
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

    function removeNonHodlers(address _address) public onlyDigi{
       if(IDigi(tokenAddress).balanceOf(_address) < representativeMin){
        delete registeredReps[_address];
       }
    }

    function registerRep() public {
      require(IDigi(tokenAddress).balanceOf(msg.sender) > representativeMin, "Balance under 10K DGT");
      uint _unlockBlock = block.number + repMaturation;  //unlocks after 30 days or so
      registeredReps[msg.sender] = Representative(msg.sender,block.number, _unlockBlock);
    }

}
