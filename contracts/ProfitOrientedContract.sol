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

contract ProfitOrientedContract is SafeMath{
    address public digitrade;
    address public tokenAddress;
    address public governance;
    address public represenative;
    address public proposer;

    uint public proposalCost;
    uint public fundingGoal;
    uint public fundingDeadline;
    uint public proposerStake;
    uint public otherStakers;
    uint public startBlock;

    uint id;
    uint timeOut;

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

    event FundingNeeded(uint contractNumber, uint _amount, uint _timeRemaining);

    event TaskComplete(string completionMessage, bool _completionStatus);

    event Transfer(address indexed from, address indexed to, uint tokens);

    //TEAM STAKING
    constructor(
      uint _id,
      address _proposer,
      uint _cost,
      address _digitrade,
      address _governance,
      address _tokenAddress){
        id = _id;
        proposer = _proposer;
        proposalCost = _cost;
        digitrade = _digitrade;
        governance = _governance;
        tokenAddress = _tokenAddress;
        enable = false;
        penalized = false;
        fundingGoal = 100;
    }

    modifier DIGIcheck{
        require(block.number < InterfaceDaoGov(governance).getDigiCheckBlock(), "digitrade no longer has any priviledges");
        _;

    }
    modifier onlyEnabled(){
        require(enable == true);
        _;
    }
    modifier onlyProposer(){
        require(msg.sender == proposer);
        _;
    }
    modifier onlyDIGI(){
        require(msg.sender == digitrade);
        _;
    }
    modifier onlyFinished(){
        require(completed ==true || cancelled ==true, "Proposal term is not complete or cancelled" );

        _;
    }



    //General contract functions
    function totalBalance() public view returns(uint){
        return InterfaceDigi(tokenAddress).balanceOf(address(this));
    }
    function sponsorBalance(address _sponsor) public view returns (uint balance) {
        return sponsors[_sponsor].balance;
    }

    //Fund Contract
    function SponsorPOC(uint _amount) public onlyProposer returns (string memory message, uint _completionBlock){
        require(_amount < proposalCost, "One address can not fund 100 % of proposal");
        InterfaceDigi(tokenAddress).transferFrom(msg.sender, address(this) , _amount);
        proposerStake= safeSub(proposalCost,_amount);
        if(proposerStake < _amount){
            uint fundsNeeded = safeSub(_amount, proposerStake);
            emit FundingNeeded(id, fundsNeeded, startBlock);
        }
        message = "Completion notification due by";
        return (message, _completionBlock);
    }

    function coSponsorPOC() public {
    }


    function cancel(string memory reason) public onlyEnabled returns ( string memory _reason){
        if(msg.sender == digitrade){
            enable = false;
            cancelled = true;
            _reason = reason;
            return _reason;
            }
        if(msg.sender == proposer){
            penalized = true;
            proposerStake = mul((div(90,100)),proposerStake);
            enable = false;
            cancelled = true;
            _reason = reason;
            return _reason;
            }
    }

    function withdrawStake() public onlyProposer onlyFinished {
        if(penalized = true){
            require(block.number > timeOut, "You must wait until block.number exceeds timeout block");
            InterfaceDigi(tokenAddress).transfer(proposer,proposerStake);
        }
         else{
            InterfaceDigi(tokenAddress).transfer(proposer,proposerStake);
        }
    }

    function withdrawCoSponsorStake() public onlyFinished{
        if (msg.sender == proposer){
        }else{
          InterfaceDigi(tokenAddress).transfer(sponsors[msg.sender].sponsor,sponsors[msg.sender].balance);
        }
    }

    //POC functions
    function releaseProfit() public {
          uint _profit = mul(sponsors[msg.sender].percentage,sponsors[msg.sender].profit);
          InterfaceDigi(tokenAddress).transfer(sponsors[msg.sender].sponsor,_profit);
          sponsors[msg.sender].profit = 0;
    }




    }
