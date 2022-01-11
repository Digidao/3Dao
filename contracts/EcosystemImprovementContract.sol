// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;    }

    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;}
            uint256 c = a * b;
            require(c / a == b, "SafeMath: multiplication overflow");
            return c;}

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;    }
}

interface InterfaceDaoGov {
  function getStakePool() external view returns (address);
  function getDIGI() external view returns (address);
  function getDigiCheckBlock() external view returns (uint);
  function getDaoGovAddress() external view returns (address);
  function getDigitradeAddress() external view returns (address);
}

interface InterfaceDigi {
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function totalSupply() external view returns (uint);
    function transfer(address receiver, uint tokens) external returns (bool success);
    function transferFrom(address sender, address receiver, uint tokens) external returns (bool success);
    function getDevFund() external view returns(uint);
}

interface InterfaceReps {
    function getRep() external view returns (address);

}

contract EcosystemImprovementContract is SafeMath{
    address public digitrade;
    address public tokenAddress;
    address public represenative;
    address public proposer;
    address public facilitator;
    address public pool;

    uint public proposalCost;
    uint public releaseBlock;
    uint public proposerStake;
    uint public maximumProposerAmount;

    uint cutoffBlock;
    uint completionBlock;
    uint timeOut;
    uint profitBalance;

    bool public penalized;
    bool enable;
    bool cancelled;
    bool completed;
    bool public taskComplete;

    mapping(address => uint) balances;
    mapping(address => proposalSponsors )  public sponsors;
    proposalSponsors[] public sponsor;

    struct proposalSponsors{
        address sponsor;
        uint percentage;
        uint balance;
        uint profit;
    }

    event FundingNeeded(uint _amount, uint _timeRemaining);
    event TaskComplete(string completionMessage, bool _completionStatus);
    event Transfer(address indexed from, address indexed to, uint tokens);

    constructor(
      address _proposer,
      uint _cost,
      address _facilitator,
      uint _releaseBlock,
      address _digitrade,
      address _represensative,
      address _tokenAddress,
      address _pool){
        proposer = _proposer;
        facilitator = _facilitator;
        proposalCost = _cost;
        releaseBlock = _releaseBlock;
        digitrade = _digitrade;
        represenative = _represensative;
        tokenAddress = _tokenAddress;
        pool = _pool;


        completionBlock = safeSub(_releaseBlock , div(_releaseBlock,10));
        cutoffBlock = (block.number + 30000); // 3 days to completly fund proposal
        enable = false;
        penalized = false;
        maximumProposerAmount = mul((div(85,100)),proposalCost); // 85% of proposal cost
        timeOut = 0;
        profitBalance = 0;
    }

    modifier onlyEnabled(){
        require(enable == true);
        _;}
    modifier onlyProposer(){
        require(msg.sender == proposer);
        _;}
    modifier onlyFacilitator(){
        require(msg.sender == facilitator);
        _;}
    modifier onlyDIGI(){
        require(msg.sender == digitrade);
        _;}
    modifier onlyInactive(){
        require(completed == true || cancelled == true || enable == false, "Proposal term is not complete or cancelled" );
        _;}
    modifier onlyMaxContractValue(uint _amount){
        require(_amount <= maximumProposerAmount, "Sending more than agreed upon amount");
        _;}
    modifier onlyBeforeCutoff{
        require(cutoffBlock < block.number);
        _;}

    modifier onlyReps{
        require(msg.sender == InterfaceReps(represenative).getRep());
        _;
    }

    function totalBalance() public view returns(uint){
        return InterfaceDigi(tokenAddress).balanceOf(address(this));
    }
    function sponsorBalance(address _sponsor) public  view returns (uint balance) {
        return sponsors[_sponsor].balance;
    }
    function SponsorEIC(uint _amount) public onlyProposer onlyMaxContractValue(_amount) onlyBeforeCutoff returns (string memory message, uint _completionBlock){
        InterfaceDigi(tokenAddress).transferFrom(msg.sender, address(this) , _amount);
        proposerStake= safeSub(proposalCost,_amount);
        if(proposerStake < _amount){
            uint fundsNeeded = safeSub(_amount, proposerStake);
            emit FundingNeeded(fundsNeeded, completionBlock);
        }
        message = "Completion notification due by";
        _completionBlock = completionBlock;
        return (message, _completionBlock);
    }
    function coSponsorECI(uint _amount) public onlyBeforeCutoff onlyReps{
        if(msg.sender == proposer){
        }else{
            require(_amount <= (mul((div(15,100)),proposalCost)) );
            InterfaceDigi(tokenAddress).transfer(msg.sender,_amount);
        }
    }
    function cancel(string memory reason) public onlyEnabled returns ( string memory _reason){
        if(msg.sender == digitrade || msg.sender == facilitator){
            require(block.number < releaseBlock);
            enable = false;
            cancelled = true;
            _reason = reason;
            return _reason;
            }
        if(msg.sender == proposer){
            require(block.number < releaseBlock);
            penalized = true;
            if(cutoffBlock < block.number){}else{
            timeOut = 70000; //1 week
            proposerStake = mul((div(90,100)),proposerStake);}
            enable = false;
            cancelled = true;
            _reason = reason;
            return _reason;
            }
    }
    function withdrawStake() public onlyProposer onlyInactive {
        if(penalized = true){
            require(block.number > timeOut, "You must wait until block.number exceeds timeout block");
            InterfaceDigi(tokenAddress).transfer(proposer,proposerStake);
        }
         else{
            InterfaceDigi(tokenAddress).transfer(proposer,proposerStake);
        }
    }
    function withdrawCoSponsorStake() public onlyInactive{
        if (msg.sender == proposer){
        }else{
          InterfaceDigi(tokenAddress).transfer(sponsors[msg.sender].sponsor,sponsors[msg.sender].balance);
        }
    }
    function completionNotification(string memory message, bool _complete) public onlyFacilitator {
      require(block.number < releaseBlock, "The time to complete the complete the proposal has passed");
      taskComplete = _complete;
      profitBalance = profitBalance + (mul(div(3,100),proposalCost));
      //uint oldProposerBalance = InterfaceDigi(digitrade).balanceOf(proposer);
      //uint newProposerBalance = oldProposerBalance + proposalCost;
      //InterfaceDaoGov(governance).
      //emit TaskComplete(message, _complete);
      if(_complete == false){
        cancel(message);
      }
    }


    }
