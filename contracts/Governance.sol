// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;


contract GovernanceMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "GovernanceMath: addition overflow");
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
            require(c / a == b, "GovernanceMath: multiplication overflow");
            return c;}

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "GovernanceMath: division by zero");
        uint256 c = a / b;
        return c;    }
}

interface IToken{
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transferFrom(address sender, address receiver, uint tokens) external returns (bool success);
    function transfer(address receiver, uint tokens) external returns (bool success);
}

interface IRepresentatives{
    function isRep(address _address) external view returns (bool);
    function removeNonHodlers() external ;
}

interface IPool{
    function getProposalTokenLimit() external view returns(uint);
    function getpoolSupply() external view returns (uint);
    function fundStrength() external view returns (uint);
}

contract Governance is GovernanceMath{
    address public tokenAddress;
    address public consul;
    address thisContract;
    address public pool;
    address public reps;
    uint public minimumVotingPeriod;
    address [] public proposalContracts;
    event proposalResult(uint _proposal, bool passed);
    uint resignBlock; 
    uint public proposalIntializationThreshold; //Required amount of voting power to allow full voting on a proposal
    uint proposalContractID = 1;
    address public currentStakePool;
    address public oldStakePool; 

    struct Proposal {
        address proposer;
        string basic_description;
        uint yesVotes;
        uint noVotes;
        uint endVoteBlock;
        uint proposalCost;
        bool voteEnded;
        bool votePass;
        bool enacted;
        uint initializationPoints;
        bool initialized;
        mapping(address => bool) voters;
        mapping(address => bool) initializers;
        bool active;
    }

    mapping(uint => Proposal) public proposals;


    //TESTING CONSTUCTOR
     constructor(address _tokenAddress, address _pool, address _reps){
        minimumVotingPeriod = 10; //(Around 5 minutes) voting is allowed on proposal
        proposalIntializationThreshold = 1000000000000000000000000; //1000000 3DAO 1% of total supply
        consul = msg.sender;
        tokenAddress = _tokenAddress; //Address of 3DAO token
        pool = _pool; //Address of proposal pool
        reps = _reps; //Address of Represenatives
        thisContract = address(this); //Governance Contract
        resignBlock = add(block.number,60); //(10 minutes from launch)consul loses all special rights and system becomes truly decentralized.
    }


/*  REAL CONSTRUCTOR
    constructor(address _tokenAddress, address _pool, address _reps){
        minimumVotingPeriod = 60480; //(Around 7 days) voting is allowed on proposal
        proposalIntializationThreshold = 1000000000000000000000000; //1000000 3DAO 1% of total supply
        consul = msg.sender;
        tokenAddress = _tokenAddress; //Address of 3DAO token
        pool = _pool; //Address of proposal pool
        reps = _reps; //Address of Represenatives
        thisContract = address(this); //Governance Contract
        resignBlock = add(block.number,1800000); //(180Days*24Hours*60minutes*60seconds)/Blocktime  = (6 months from launch) new consul vote.
    }
*/

    modifier onlyConsul(){
        require(msg.sender == consul);
        _;
    }
    modifier consulCheck{
        require(block.number < resignBlock, "counsel no longer has any priviledges");
        _;

    }
    modifier onlyNoConsul{
        require(resignBlock < block.number , "counsel no longer has any priviledges");
        _;

    }
    modifier onlyReps(address _address){
       require(IToken(tokenAddress).balanceOf(msg.sender) > 10000000000000000000000, "Not enough 3dao tokens");
       require(IRepresentatives(reps).isRep(_address));
      _;
    }
    modifier onlyInitializedProposal(uint _proposal){
      require(proposals[_proposal].initialized == true,"Proposal is not initialized");
      _;
    }
    modifier onlyProposalSponsor(uint _proposal){
       require(msg.sender == proposals[_proposal].proposer, "Only the proposal creator can call this function");
      _;
    }
    modifier onlyNonEnactedProposals(uint _proposal){
      require(proposals[_proposal].enacted == false, "Proposal is already enacted");
      _;
    }
    modifier onlyEndedProposals(uint _proposal){
      require(block.number > proposals[_proposal].endVoteBlock ,"Voting period has not ended");
      _;
    }

    function getMaxAvailiableTokens() public view returns (uint){
        return IPool(pool).getProposalTokenLimit();
    }

    function getCounselResignBlock() public view returns(uint){
        return resignBlock;
    }

    function getTokenAddress() public view returns(address){
        return tokenAddress;
    }

    function getGovernanceAddress() public view returns(address) {
        return thisContract;
    }

    function isRep(address _address) public view returns(bool){
        return IRepresentatives(reps).isRep(_address);
    }

    function kickDegenerateGamblers()public {
        IRepresentatives(reps).removeNonHodlers();
    }

    function propose(string memory detailedDescription, uint256 _cost, uint _votePeriod) public onlyReps(msg.sender) returns (string memory,uint) {
        require((_cost) < getMaxAvailiableTokens(), "Proposal cost exceeds 2% of avaliable tokens");
        require(_votePeriod > minimumVotingPeriod, "Not enough time for potential voters to become aware of proposal");
        uint iPoints = IToken(tokenAddress).balanceOf(msg.sender);
        kickDegenerateGamblers();
        Proposal storage p = proposals[proposalContractID];
            p.proposer = msg.sender;
            p.basic_description = detailedDescription;
            p.yesVotes = 0;
            p.noVotes = 0;
            p.endVoteBlock = add(_votePeriod,block.number);
            p.proposalCost =  _cost;
            p.voteEnded = false;
            p.votePass = false;
            p.enacted = false;
            p.initializationPoints = iPoints;
            if(iPoints > proposalIntializationThreshold){
            p.initialized = true;
            }else{
            p.initialized = false;}
            p.initializers[msg.sender] = true;
            p.active = false;

            proposalContractID = proposalContractID + 1;

            return("Proposal ID",proposalContractID);
    }

    function initializeProposal(uint _proposal) public onlyReps(msg.sender) returns (string memory message, uint points){
      require(proposals[_proposal].initialized == false, "Proposal already initialized");
      require(proposals[_proposal].proposer != 0x0000000000000000000000000000000000000000,"Proposal does not exist");
      require(!proposals[_proposal].initializers[msg.sender], "Only one vote per address"); 
      uint previousPoints = proposals[_proposal].initializationPoints;
      uint addedPoints = IToken(tokenAddress).balanceOf(msg.sender);
      uint currentPoints = add(previousPoints, addedPoints);
      proposals[_proposal].initializationPoints = currentPoints;
      proposals[_proposal].initializers[msg.sender] = true;
      
      if(currentPoints >= proposalIntializationThreshold){
      proposals[_proposal].initialized = true;
      string memory _message = "Proposal is initalized";
      message = _message;
      return (message, proposals[_proposal].initializationPoints);
        }
        else{
      return ("1000000000000000000000000 required to initialize, Current initialization points: ", proposals[_proposal].initializationPoints);
        }
    }

    function vote(uint _proposal, bool yes, bool no) public onlyReps(msg.sender) onlyInitializedProposal(_proposal) returns (string memory message){
       Proposal storage p = proposals[_proposal];
       require(!p.voters[msg.sender], "Only one vote per address");
       require(proposals[_proposal].endVoteBlock > block.number, "Voting has ended");
       if(yes == true){
           require(no == false);
           proposals[_proposal].yesVotes += 1;
           p.voters[msg.sender] = true;
           return "You voted yes!";}
       if(no == true){
           require(yes == false);
           proposals[_proposal].noVotes += 1;
           p.voters[msg.sender] = true;
           return "You voted no!";}
    }

    function tallyProposal(uint _proposal) public onlyEndedProposals(_proposal)  returns (bool _result) {
        if(proposals[_proposal].yesVotes > proposals[_proposal].noVotes){
        proposals[_proposal].voteEnded = true;
        proposals[_proposal].votePass = true;
        emit proposalResult(_proposal, true);
        return true;
        }
        if(proposals[_proposal].yesVotes < proposals[_proposal].noVotes){
        proposals[_proposal].voteEnded = true;
        proposals[_proposal].votePass = false;
        emit proposalResult(_proposal, false);
        return false;
        }
    }

    function override_vote(uint _proposal) public onlyConsul consulCheck(){
        uint yesVotes = proposals[_proposal].yesVotes;
        uint noVotes  = proposals[_proposal].noVotes;
        require(yesVotes < mul((div(2,3)),(add(yesVotes,noVotes)))," 66% majority overides Consul authority");
        require(noVotes  < mul((div(2,3)),(add(yesVotes,noVotes)))," 66% majority overides Consul authority");
        proposals[_proposal].votePass = false;
        proposals[_proposal].enacted = false;
        proposals[_proposal].voteEnded = true;
        emit proposalResult(_proposal, false);
    }

    function calculateReleaseBlock(uint _weeks) public view returns (uint _releaseBlock){
        _releaseBlock = block.number + (_weeks * 1);  //block.number + (_weeks * 60480);
        return _releaseBlock;
    }

    function enactProposal(uint _proposal,uint _weeks,address _facilitator) public
        onlyProposalSponsor(_proposal)
        onlyNonEnactedProposals(_proposal) returns (address) {
        require(_weeks > 0," Proprosal needs at least 1 week to be completed");
        require(proposals[_proposal].votePass = true, "The vote did not pass");
        uint proposerBalance = IToken(tokenAddress).balanceOf(msg.sender);
        require(proposerBalance >= proposals[_proposal].proposalCost,"Your balance is < than the amount needed to enact proposal");
        uint _releaseBlock = calculateReleaseBlock(_weeks);
        address newContractAddress;

        ProposalContract newContract = new ProposalContract(
            _proposal,
            msg.sender,
            proposals[_proposal].proposalCost,
            _facilitator,
            _releaseBlock,
            consul,
            reps,
            tokenAddress,
            thisContract,
            pool);
        newContractAddress = address(newContract);
        proposalContracts.push(address(newContract));
        proposals[_proposal].enacted == true;

        stakeContract();
        return (newContractAddress);
    }

    function verfifyProposalContract(uint id, address contractAddress) public view returns (bool){
        require(proposalContracts[id-1] == contractAddress, "This contract can not be verified");
        return true;
    }

    function stakeContract() public onlyReps(msg.sender) returns(address){
        uint supply = IPool(pool).getpoolSupply();
        if(supply > 65){
        oldStakePool = currentStakePool;
        StakeContract stakingPool = new StakeContract(
            consul,
            reps,
            tokenAddress,
            thisContract,
            pool,
            oldStakePool);
            return address(stakingPool);}
            else{
            return 0x0000000000000000000000000000000000000000;    
            }
    }

    function setCurrentStakeContract(address currentPoolAddress) external returns(address){
        currentStakePool = currentPoolAddress;
        return currentStakePool;
    }

}


interface IGovernance {
  function verfifyProposalContract(uint id, address contractAddress) external view returns (bool);
  function setCurrentStakeContract(address currentPoolAddress) external returns(address);
}

contract ProposalContract is GovernanceMath{
    address public thisContract;

    uint public id;
    address public proposer;
    uint public proposalCost;
    address public facilitator;
    uint public releaseBlock;
    address consul;
    address public reps;
    address public tokenContract;
    address public governanceContract;
    address public poolContract;

    uint public maximumProposerAmount;
    uint public fundingDeadline;
    bool public enabled;

    uint public notificationDeadline;
    bool public taskComplete;

    uint public currentStake;
    uint timeOut;
    bool public penalized;
    bool public cancelled;



    event FundingNeeded(uint _amount, uint _timeRemaining);
    event TaskComplete(string completionMessage, bool _completionStatus);

    struct Sponsor{
        address sponsorAddress;
        uint balance;
        bool isSponsor;
        bool stakebonus;
        bool paid;
    }

    mapping(address => Sponsor )  public sponsors;
    Sponsor [] sponsorArray;

    constructor(
      uint _id,
      address _proposer,
      uint _cost,
      address _facilitator,
      uint _releaseBlock,
      address _consul,
      address _represensative,
      address _tokenContract,
      address _governanceContract,
      address _poolContract
      ){
        id = _id;
        proposer = _proposer;
        facilitator = _facilitator;
        proposalCost = _cost;
        releaseBlock = _releaseBlock;//Facilitator is paid after this block
        consul = _consul;
        reps = _represensative;
        tokenContract = _tokenContract;
        governanceContract = _governanceContract;
        poolContract = _poolContract;

        thisContract = address(this);
        notificationDeadline = (_releaseBlock+100);//safeSub(_releaseBlock , (div(_releaseBlock,10))); //Block where 'completionNotification' must be called.
        fundingDeadline = (block.number + 300);//0000); // 3 days to completly fund proposal
        enabled = false;
        penalized = false;
        maximumProposerAmount = (proposalCost * 85)/100; // 85% of proposal cost
        timeOut = 0;
        taskComplete = false;
        currentStake = 0;
    }

    modifier onlyEnabled(){
        require(enabled == true, "The proposal is not enabled");
        _;}
    modifier onlyProposer(){
        require(msg.sender == proposer, "You are not the proposer");
        _;}
    modifier onlyFacilitator(){
        require(msg.sender == facilitator, "You are not the facilitator");
        _;}
    modifier onlyConsul(){
        require(msg.sender == consul, "Not the Digi");
        _;}
    modifier onlyMaxContractValue(uint _amount){
        require(_amount <= maximumProposerAmount, "Sending more than 85% of proposal cost");
        _;}
    modifier onlyBeforeCutoff{
        require(block.number < fundingDeadline, "Funding deadline has passed");
        _;}
    modifier onlyReps(address _address){
        require(IRepresentatives(reps).isRep(_address),"You are not a rep");
        _;}
    modifier onlyAvailiableStake(uint _amount){
        require(_amount <= safeSub(proposalCost,currentStake), "Sending more than the availiableStake");
        _;
        }
    modifier onlyVerifiedProposals(uint _id, address _proposal){
        require(IGovernance(governanceContract).verfifyProposalContract(_id, _proposal), "This contract can not be verified");
        _;}
    modifier onlyPoolContract {
        require(msg.sender == poolContract);
        _;
    }

    function contractBalance() public view returns(uint){
        return IToken(tokenContract).balanceOf(thisContract);
    }

    function SponsorProposalContract(uint _amount) public
        onlyVerifiedProposals(id, thisContract)
        onlyReps(msg.sender)
        onlyBeforeCutoff
        onlyAvailiableStake(_amount)
        onlyMaxContractValue(_amount)

        returns (string memory message)
        {

        require(_amount > 0,"Can't sponsor proposal with a 0 value");
        require(sponsors[msg.sender].balance == 0, "You have already sponsored this proposal");
        bool proposerBonus = false;
        if(_amount == maximumProposerAmount){proposerBonus = true;}
        Sponsor storage s = sponsors[msg.sender];

        if(msg.sender == proposer){
            s.sponsorAddress = msg.sender;
            s.balance = _amount;
            s.isSponsor = true;
            s.stakebonus = proposerBonus;
            s.paid = false;

        }else{
            s.sponsorAddress = msg.sender;
            s.balance = _amount;
            s.isSponsor = false;
            s.stakebonus = false;
            s.paid = false;
        }

        sponsorArray.push(s);

        currentStake = contractBalance() + _amount;
        uint fundsNeeded = safeSub(proposalCost*10**18 , currentStake);
        emit FundingNeeded(fundsNeeded, notificationDeadline);
        enabled = true;

        IToken(tokenContract).transferFrom(msg.sender,thisContract, _amount);

        message = "Completion notification due by";

        return message;

    }

    function cancel( string memory reason) public onlyVerifiedProposals(id, thisContract) onlyEnabled returns (string memory _reason){
        if(msg.sender == consul|| msg.sender == facilitator){
            require(block.number < releaseBlock, "block.number > release block");
            enabled = false;
            cancelled = true;
            _reason = reason;
            return _reason;
            }
        if(msg.sender == proposer){
            require(block.number < releaseBlock, "block.number > release block");
            penalized = true;
            if(fundingDeadline < block.number){}else{
            timeOut = 40;//000; //4 days
            }
            timeOut = 30;//000; //3 days
            enabled = false;
            cancelled = true;
            _reason = reason;
            return _reason;
            }
    }

    function completionNotification(uint _id, string memory message, bool _complete) public onlyVerifiedProposals(_id, thisContract) onlyEnabled onlyFacilitator {
      require(block.number < notificationDeadline, "The time to complete the proposal has passed");
      taskComplete = _complete;
      emit TaskComplete(message, _complete);
      if(_complete == false){
        cancel(message);
      }
    }

    function payFacilitator() public onlyEnabled onlyFacilitator {
        require(block.number > releaseBlock, "Block number is less than release block");
        IToken(tokenContract).transfer(facilitator,IToken(tokenContract).balanceOf(thisContract));
    }

    function getSponsorBalance(address _sponsor) public view returns(uint){
        return (sponsors[_sponsor].balance);
    }

    function getSponsorPaymentStatus(address _sponsor) public view returns(bool){
        return (sponsors[_sponsor].paid);
    }

    function setSponsorBalance(address _sponsor) external onlyPoolContract{
        //require(msg.sender == _sponsor, "You are not a sponsor");
        sponsors[_sponsor].balance = 0;
        sponsors[_sponsor].paid = true;
    }

    function getProposalStatus() public view returns(bool){
        return taskComplete;
    }

    function getProposer() public view returns(address){
        return proposer;
    }

    function getProposerBonus() public view returns (bool){
        return sponsors[proposer].stakebonus;
    }

    function getReleaseBlock() public view returns(uint){
        return releaseBlock;
    }
    function getCurrentBlock() public view returns(uint){
        return block.number;
    }

}

contract StakeContract is GovernanceMath{
    address thisContract;
    address consul;
    uint totalStaked;
    bool isCurrentContract;

    address public reps;
    address public tokenContract;
    address public governanceContract;
    address public poolContract;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    //struct Staker{
    //    address stakerAddress;
     //   uint balance;
    //   mapping(address => bool) stakers;
    //}

    constructor(address _consul, address _reps, address _tokenContract, address _governanceContract, address _poolContract, address _oldStakePool) {
        thisContract = address(this);
        consul = _consul;
        reps = _reps;
        tokenContract = _tokenContract;
        governanceContract = _governanceContract;
        poolContract = _poolContract;
        isCurrentContract = true;
        IGovernance(governanceContract).setCurrentStakeContract(thisContract);
        //releaseStake(_oldStakePool);
    }

    //mapping(address => Staker )  public stakers;
    //Staker [] stakerArray;

    modifier onlyReps(address _address){
        require(IRepresentatives(reps).isRep(_address),"You are not a rep");
        _;} 


    function addStake(uint _amount) public onlyReps(msg.sender)returns (string memory message){
        require(_amount > 0,"Can't stake a 0 value");
        //uint previousBalance = stakers[msg.sender].balance;
        //Staker storage s = stakers[msg.sender];
        //s.stakerAddress = msg.sender;
        //s.balance = previousBalance + _amount;
        //stakerArray.push(s);
        IToken(tokenContract).transferFrom(msg.sender,poolContract, _amount);
        message = "You have staked!";
        return (message);
    }

    //function releaseStake(address oldStakePool) public onlyConsul() returns (string memory message){
    //    require
    //}

    function getTotalStaked() public view returns (uint) {
        return totalStaked - balances[address(0)];
    }
    function balanceOf(address tokenOwner) public  view returns (uint balance) {
        return balances[tokenOwner];
    }
    function transfer(address receiver, uint tokens) public returns (bool success) {
        require(isCurrentContract == false,"Staking period has not ended");
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[receiver] = safeAdd(balances[receiver], tokens);
        emit Transfer(msg.sender, receiver, tokens);
        return true;
    }
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    function transferFrom(address sender, address receiver, uint tokens) public returns (bool success) {
        balances[sender] = safeSub(balances[sender], tokens);
        allowed[sender][msg.sender] = safeSub(allowed[sender][msg.sender], tokens);
        balances[receiver] = safeAdd(balances[receiver], tokens);
        emit Transfer(sender, receiver, tokens);
        return true;
    }
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

}


