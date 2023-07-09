// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;


interface IToken {
    function balanceOf(address tokenOwner) external view returns (uint balance);

}

contract Representatives {
    address public tokenAddress;
    uint public representativeMin;
    uint public repMaturation;
    mapping(address => Representative )  public registeredReps;
    address public consul;
    Representative [] public reps;

    struct Representative{
        address _rep;
        uint _startBlock;
        uint _unlockBlock;
    }

    //Testing constructor
    constructor(address _tokenAddress) {
        repMaturation = 6;  //About 1 minute
        representativeMin = 10_000e18; // 10000 Digitrade
        tokenAddress = _tokenAddress;
        consul = msg.sender;
        registerRep();
    }

    /*Real Constructor
    constructor(address _tokenAddress) {
        repMaturation = 60480;  //About 7 days
        representativeMin = 10_000e18; // 10000 Digitrade
        tokenAddress = _tokenAddress;
        consul = msg.sender;
        registerRep();
    }
    */
    modifier onlyConsul(){
        require(msg.sender == consul);
        _;
    }

    function getUnlockBlock(address _address) public view returns (uint){
        return registeredReps[_address]._unlockBlock;
    }

    function isRep(address _address) public view returns (bool){
        require(getUnlockBlock(_address) > 0, "Not registered");
        require(block.number > getUnlockBlock(_address), "Registered but not a rep yet");
        return true;
    }

    function removeNonHodlers() external{
       for(uint256 i=0; i < reps.length; i++){
        if(IToken(tokenAddress).balanceOf(reps[i]._rep) < representativeMin){
        delete registeredReps[reps[i]._rep];
        delete reps[i];
        reps.pop();
        }
       }
    }

   

    function registerRep() public {
      require(IToken(tokenAddress).balanceOf(msg.sender) > representativeMin, "Balance under 10K DGT");
      for(uint256 i=0; i < reps.length; i++){
      require(msg.sender != reps[i]._rep, "Already a rep");}
      uint _unlockBlock = block.number + repMaturation;  //unlocks after 7 days or so
      Representative memory newRep = Representative(msg.sender,block.number, _unlockBlock);
      registeredReps[msg.sender] = newRep;
      reps.push(newRep);
    }

    function getRegisteredRepsSize() public view returns (uint) {
        uint active;
        for(uint256 i=0; i < reps.length; i++){
                if(reps[i]._rep != 0x0000000000000000000000000000000000000000){
                    active++;
                }else{}
        }
        return active;
    }

}
