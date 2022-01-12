// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


//circa 80% complete 1/11/2022
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

interface Gov {
  function getPool() external view returns (address);
  function getDIGI() external view returns (address);
  function getDigiCheckBlock() external view returns (uint);
  function getDaoGovAddress() external view returns (address);
  function getDigitradeAddress() external view returns (address);
}

interface Digi {
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function totalSupply() external view returns (uint);
    function transfer(address receiver, uint tokens) external returns (bool success);
    function transferFrom(address sender, address receiver, uint tokens) external returns (bool success);
    function getDevFund() external view returns(uint);
    function approve(address spender, uint tokens) external returns (bool success);
}

interface Reps {
    function getRep() external view returns (address);

}

contract DaoImprovementContract is SafeMath{
    address public digitrade;
    address public tokenAddress;
    address public represenative;
    address public proposer;
    address public facilitator;
    address public pool;
    address public thisContract;

    uint public proposalCost;
    uint public releaseBlock;
    uint public _totalStaked;
    uint public maximumProposerAmount;
    uint decimals;
    uint public fundingDeadline;
    uint public notificationDeadline;
    uint timeOut;
    uint profitBalance;

    bool public penalized;
    bool enable;
    bool cancelled;
    bool completed;
    bool public taskComplete;

    mapping(address => uint) stakebalance;
    mapping(address => mapping(address => uint)) allowed;
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    event FundingNeeded(uint _amount, uint _timeRemaining);
    event TaskComplete(string completionMessage, bool _completionStatus);

    constructor(
      address _proposer,
      uint _cost,
      address _facilitator,
      uint _releaseBlock,
      address _digitrade,
      address _represensative,
      address _tokenAddress,
      address _pool){
        decimals = 10*18;
        proposer = _proposer;
        facilitator = _facilitator;
        proposalCost = _cost*decimals;
        releaseBlock = _releaseBlock; //Facilitator is paid after this block
        digitrade = _digitrade;
        represenative = _represensative;
        tokenAddress = _tokenAddress;
        pool = _pool;

        thisContract = address(this);
        notificationDeadline = safeSub(_releaseBlock , div(_releaseBlock,10)); //Block where 'completionNotification' must be called.
        fundingDeadline = (block.number + 30000); // 3 days to completly fund proposal
        enable = false;
        penalized = false;
        maximumProposerAmount = (proposalCost * 85)/100; // 85% of proposal cost
        timeOut = 0;
        profitBalance = 0;
        decimals = 10*18;
    }

    modifier onlyEnabled(){
        require(enable == true, "The proposal is not enabled");
        _;}
    modifier onlyProposer(){
        require(msg.sender == proposer, "You are not the proposer");
        _;}
    modifier onlyFacilitator(){
        require(msg.sender == facilitator, "You are not the facilitator");
        _;}
    modifier onlyDIGI(){
        require(msg.sender == digitrade, "Not the Digi");
        _;}
    modifier onlyInactive(){
        require(completed == true || cancelled == true || enable == false, "Proposal term is not complete or cancelled" );
        _;}
    modifier onlyMaxContractValue(uint _amount){
        require(_amount <= (maximumProposerAmount), "Sending more than 85% of proposal cost");
        _;}
    modifier onlyBeforeCutoff{
        require(block.number < fundingDeadline, "Funding deadline has passed");
        _;}
    modifier onlyReps{
        require(msg.sender == Reps(represenative).getRep(),"You are not a rep");
        _;}
    modifier onlyAvailiableStake(uint _amount){
        require(_amount <= safeSub(proposalCost,_totalStaked), "Sending more than the availiableStake");
        _;
    }


    function contractBalance() public view returns(uint){
        return balanceOf(thisContract);
    }

    function approveDigitrade(uint _amount) public{
        Digi(tokenAddress).approve(thisContract,_amount);
    }
    function SponsorDAOIC(uint _amount) public onlyProposer onlyMaxContractValue(_amount) onlyBeforeCutoff returns (string memory message, uint _notificationDeadline){
        require(_amount > 0,"Nice try");
        Digi(tokenAddress).transferFrom(msg.sender,thisContract, (_amount*decimals));
        stakebalance[msg.sender]= safeSub(proposalCost, balanceOf(msg.sender));
        if(stakebalance[msg.sender] < maximumProposerAmount){
            uint fundsNeeded = safeAdd((proposalCost - maximumProposerAmount),(maximumProposerAmount - stakebalance[msg.sender]));
            emit FundingNeeded(fundsNeeded, notificationDeadline);
        }
        if(stakebalance[msg.sender] == maximumProposerAmount){
            uint fundsNeeded = safeSub(proposalCost , maximumProposerAmount);
            emit FundingNeeded(fundsNeeded, notificationDeadline);
        }
        message = "Completion notification due by";
        _notificationDeadline = notificationDeadline;
        enable = true;
        stakebalance[msg.sender] = safeAdd(stakebalance[msg.sender], _amount);
        return (message, _notificationDeadline);
    }
    function coSponsorDAOIC(uint _amount) public onlyBeforeCutoff onlyReps onlyAvailiableStake(_amount){
        require(_amount > 0,"Nice try");
        if(msg.sender == proposer){
        }else{
            require(stakebalance[proposer] > 0, "Proposer has not enabled contract");
            Digi(tokenAddress).transferFrom(msg.sender,thisContract, (_amount*decimals));
            stakebalance[msg.sender] = safeAdd(stakebalance[msg.sender], (_amount*10*18));

        }
    }
    function cancel(string memory reason) public onlyEnabled returns ( string memory _reason){
        if(msg.sender == digitrade || msg.sender == facilitator){
            require(block.number < releaseBlock, "block.number > release block");
            enable = false;
            cancelled = true;
            _reason = reason;
            return _reason;
            }
        if(msg.sender == proposer){
            require(block.number < releaseBlock, "block.number > release block");
            penalized = true;
            if(fundingDeadline < block.number){}else{
            timeOut = 40000; //4 days
            stakebalance[msg.sender] = mul((div(90,100)),stakebalance[msg.sender]);}
            timeOut = 30000; //3 days
            enable = false;
            cancelled = true;
            _reason = reason;
            return _reason;
            }
    }
    //function overrideCancellation() public onlyDIGI returns (string memory _reason){   //jghjghh}

    function withdrawSponsorStake() public onlyProposer onlyInactive {
        if(penalized = true){
            require(block.number > timeOut, "You must wait until block.number exceeds timeout block");
            approve(thisContract,stakebalance[msg.sender]);
            transferFrom(msg.sender,thisContract, stakebalance[msg.sender]);
        }
         else{
            approve(thisContract,stakebalance[msg.sender]);
            transferFrom(msg.sender,thisContract, stakebalance[msg.sender]); }
    }
    function withdrawCoSponsorStake() private onlyInactive{
        if (msg.sender == proposer){
        }else{
            approve(thisContract,stakebalance[msg.sender]);
            transferFrom(msg.sender,thisContract, stakebalance[msg.sender]);
        }
    }
    function completionNotification(string memory message, bool _complete) public onlyFacilitator {
      require(block.number < notificationDeadline, "The time to complete the proposal has passed");
      taskComplete = _complete;
      emit TaskComplete(message, _complete);
      if(_complete == false){
        cancel(message);
      }
        stakebalance[facilitator] = stakebalance[address(0)];

    }
    function withdrawPayment() public onlyFacilitator {
      require(taskComplete == true);
      require(releaseBlock < block.number);
        approve(thisContract,stakebalance[msg.sender]);
        transferFrom(msg.sender,thisContract, stakebalance[msg.sender]);

    }


    function totalStaked() private view returns (uint) {
        return _totalStaked - stakebalance[address(0)];
    }
    function balanceOf(address tokenOwner) private  view returns (uint balance) {
        return stakebalance[tokenOwner];
    }
    function transfer(address receiver, uint tokens) private returns (bool success) {
        stakebalance[msg.sender] = safeSub(stakebalance[msg.sender], tokens);
        stakebalance[receiver] = safeAdd(stakebalance[receiver], tokens);
        emit Transfer(msg.sender, receiver, tokens);
        return true;
    }
    function approve(address spender, uint tokens) private returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    function transferFrom(address sender, address receiver, uint tokens) private returns (bool success) {
        stakebalance[sender] = safeSub(stakebalance[sender], tokens);
        allowed[sender][msg.sender] = safeSub(allowed[sender][msg.sender], tokens);
        stakebalance[receiver] = safeAdd(stakebalance[receiver], tokens);
        emit Transfer(sender, receiver, tokens);
        return true;
    }
    function allowance(address tokenOwner, address spender) private view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }





    }
