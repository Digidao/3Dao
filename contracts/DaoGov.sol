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

interface IDigi{
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transferFrom(address sender, address receiver, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transfer(address receiver, uint tokens) external returns (bool success);
    }

interface IRep{
    function getRep(address _address) external view returns (bool);
    }

interface IProposalPool{
    function getProposalTokenLimit() external view returns(uint);
}

contract DaoGov is SafeMath{
    address public tokenAddress; // Address of digitoken
    address digi; //Address of digitoken creator
    address governance; //This address
    address pool; //Address of pool
    address public reps;  //Address where represenative information is stored
    uint public minimumVotingPeriod; //Minimum time allotted for voting on a proposal
    address [] public proposalContracts; //An Array of enacted proposal contracts
    event proposalResult(uint _proposal, bool passed);
    uint resignBlock; //block digi loses all special rights and system becomes truly decentralized.
    uint proposalIntializationThreshold; //Required amount of voting power to allow full voting on a proposal
    uint proposalContractID; //The ID of each proposal contract

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
        address [] initializers;
        bool active;
    }

    mapping (uint => Proposal) public proposals;


    constructor(){
        minimumVotingPeriod = 10; //(Change to 70000)minimum blocks(Around 7 days) voting is allowed on proposal
        proposalIntializationThreshold = 1000000000000000000000000; //1000000 DGT 1% of total supply
        digi = msg.sender;
        tokenAddress = 0x56a2777e796eF23399e9E1d791E1A0410a75E31b; //Address of DGT token
        pool = 0xb5465ED8EcD4F79dD4BE10A7C8e7a50664e5eeEB;
        reps = 0xF27374C91BF602603AC5C9DaCC19BE431E3501cb; //Address of Represenatives
        governance = address(this); //Governance Contract
        resignBlock = add(block.number,1726272); //(6 months from launch)block digi loses all special rights and system becomes truly decentralized.
    }


    modifier onlyDIGI(){
        require(msg.sender == digi);
        _;
    }
    modifier DIGIcheck{
        require(block.number < resignBlock, "DIGI no longer has any priviledges");
        _;

    }
    modifier onlyReps(address _address){
       require(IDigi(tokenAddress).balanceOf(msg.sender) > 10000000000000000000000, "Not enough digitrade tokens");
       require(IRep(reps).getRep(_address));
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
        return IProposalPool(pool).getProposalTokenLimit();
    }

    function getDigiCheckBlock() public view returns(uint){
        return resignBlock;
    }
    function getDigitradeAddress() public view returns(address){
        return tokenAddress;
    }
    function getDaoGovAddress() public view returns(address) {
        return governance;
    }

    function isRep(address _address) public view returns(bool){
        return IRep(reps).getRep(_address);
    }

    function getBlock() public view returns (uint) {
        return block.number;
    }

    function propose(string memory detailedDescription, uint256 _dgtCost, uint _votePeriod) public onlyReps(msg.sender) returns (string memory,uint) {
        require((_dgtCost) < getMaxAvailiableTokens(), "Proposal cost exceeds 2% of avaliable tokens");
        require(_votePeriod > minimumVotingPeriod, "Not enough time for potential voters to become aware of proposal");
        address[] memory iVoted;
        proposalContractID = proposalContractID + 1;
        Proposal storage p = proposals[proposalContractID];
            p.proposer = msg.sender;
            p.basic_description = detailedDescription;
            p.yesVotes = 0;
            p.noVotes = 0;
            p.endVoteBlock = add(_votePeriod,block.number);
            p.proposalCost =  _dgtCost;
            p.voteEnded = false;
            p.votePass = false;
            p.enacted = false;
            p.initializationPoints = 0;
            p.initialized = false;
            p.initializers = iVoted;
            p.active = false;



            return("Proposal ID",proposalContractID);
    }

    function initializeProposal(uint _proposal) public onlyReps(msg.sender) returns (string memory message, uint points){
      require(proposals[_proposal].initializationPoints < proposalIntializationThreshold, "Proposal Already initialized");
      uint previousPoints = proposals[_proposal].initializationPoints;
      uint addedPoints = IDigi(tokenAddress).balanceOf(msg.sender);
      uint currentPoints = add(previousPoints, addedPoints);
      proposals[_proposal].initializationPoints = currentPoints;
      if(currentPoints >= proposalIntializationThreshold){
        for (uint i=0; i<proposals[_proposal].initializers.length; i++){
            require(proposals[_proposal].initializers[i] != msg.sender, "Only one vote per address");
        }
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


    function veto(uint _proposal) public onlyDIGI DIGIcheck(){
        uint yesVotes = proposals[_proposal].yesVotes;
        uint noVotes  = proposals[_proposal].noVotes;
        require((div(yesVotes,noVotes)) < mul((div(2,3)),(add(yesVotes,noVotes)))," 66% majority overides DIGI authority");
        proposals[_proposal].votePass = false;
        proposals[_proposal].enacted = false;
        proposals[_proposal].voteEnded = true;
        emit proposalResult(_proposal, false);
    }

    function calculateReleaseBlock(uint _weeks) public view returns (uint _releaseBlock){
        _releaseBlock = block.number + (_weeks * 70000);
        return _releaseBlock;
    }
    function enactProposal(uint _proposal,uint _weeks,address _facilitator)
        public  onlyProposalSponsor(_proposal) returns (address) {
        require(_weeks > 0," Proprosal needs at least 1 week to be completed");
        require(proposals[_proposal].votePass = true, "The vote did not pass");
        uint proposerBalance = IDigi(tokenAddress).balanceOf(msg.sender);
        require(proposerBalance >= proposals[_proposal].proposalCost,"Your DGT balance is < than the amount needed to enact proposal");
        uint _releaseBlock = calculateReleaseBlock(_weeks);
        address newContractAddress;

        Daoic newContract = new Daoic(
            _proposal,
            msg.sender,
            proposals[_proposal].proposalCost,
            _facilitator,
            _releaseBlock,
            digi,
            reps,
            tokenAddress,
            governance);
        newContractAddress = address(newContract);
        proposalContracts.push(address(newContract));



        return (newContractAddress);
    }


    function verfifyProposalContract(uint id, address contractAddress) public view returns (bool){
        require(proposalContracts[id-1] == contractAddress, "This contract can not be verified");
        return true;
    }
}


interface IGov {
  function verfifyProposalContract(uint id, address contractAddress) external view returns (bool);
}

contract Daoic is SafeMath{
    address public thisContract;

    uint public id;
    address public proposer;
    uint public proposalCost;
    address public facilitator;
    uint public releaseBlock;
    address digi;
    address public reps;
    address public tokenContract;
    address public governanceContract;


    uint public maximumProposerAmount;
    uint public fundingDeadline;
    bool enabled;

    uint public notificationDeadline;
    bool public taskComplete;

    uint public currentStake;
    uint timeOut;
    bool public penalized;
    bool cancelled;


    mapping(address => uint) stakebalance;

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

    constructor(
      uint _id,
      address _proposer,
      uint _cost,
      address _facilitator,
      uint _releaseBlock,
      address _digi,
      address _represensative,
      address _tokenContract,
      address _governanceContract
      ){
        id = _id;
        proposer = _proposer;
        facilitator = _facilitator;
        proposalCost = _cost;
        releaseBlock = 50;// _releaseBlock; //Facilitator is paid after this block
        digi = _digi;
        reps = _represensative;
        tokenContract = _tokenContract;
        governanceContract = _governanceContract;

        thisContract = address(this);
        notificationDeadline = safeSub(_releaseBlock , (div(_releaseBlock,10))); //Block where 'completionNotification' must be called.
        fundingDeadline = (block.number + 30000); // 3 days to completly fund proposal
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
    modifier onlyDIGI(){
        require(msg.sender == digi, "Not the Digi");
        _;}
    modifier onlyMaxContractValue(uint _amount){
        require(_amount <= maximumProposerAmount, "Sending more than 85% of proposal cost");
        _;}
    modifier onlyBeforeCutoff{
        require(block.number < fundingDeadline, "Funding deadline has passed");
        _;}
    modifier onlyReps(address _address){
        require(IRep(reps).getRep(_address),"You are not a rep");
        _;}
    modifier onlyAvailiableStake(uint _amount){
        require(_amount <= safeSub(proposalCost,currentStake), "Sending more than the availiableStake");
        _;
        }
    modifier onlyVerifiedProposals(uint _id, address _proposal){
        require(IGov(governanceContract).verfifyProposalContract(_id, _proposal), "This contract can not be verified");
        _;
    }



    function contractBalance() public view returns(uint){
        return IDigi(tokenContract).balanceOf(thisContract);
    }

    function SponsorDAOIC(uint _amount) public payable
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

        currentStake = contractBalance() + _amount;
        uint fundsNeeded = safeSub(proposalCost*10**18 , currentStake);
        emit FundingNeeded(fundsNeeded, notificationDeadline);
        enabled = true;

        IDigi(tokenContract).transferFrom(msg.sender,thisContract, _amount);

        message = "Completion notification due by";

        return (message);

    }

    function cancel( string memory reason) public onlyVerifiedProposals(id, thisContract) onlyEnabled returns (string memory _reason){
        if(msg.sender == digi|| msg.sender == facilitator){
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
            stakebalance[msg.sender] = (mul(90,(stakebalance[msg.sender]))/100);}
            timeOut = 30;//000; //3 days
            enabled = false;
            cancelled = true;
            _reason = reason;
            return _reason;
            }
    }

    function completionNotification(uint _id, string memory message, bool _complete) public onlyVerifiedProposals(_id, thisContract) onlyFacilitator {
      require(block.number < notificationDeadline, "The time to complete the proposal has passed");
      taskComplete = _complete;
      emit TaskComplete(message, _complete);
      if(_complete == false){
        cancel(message);
      }
    }

    function giveFacilitatorCustody() public {
        require(block.number > releaseBlock, "Wait until release blockblock");
        stakebalance[facilitator] = stakebalance[address(0)];
    }

    function payFacilitator() public {
        IDigi(tokenContract).approve(facilitator,stakebalance[facilitator]);
        bool success = IDigi(tokenContract).transferFrom(thisContract,facilitator,stakebalance[facilitator]);
        require(success, "This transaction did not succeed");
    }

    function getSponsorBalance(address _sponsor) public view returns(uint){
        return (sponsors[_sponsor].balance);
    }

    function getSponsorPaymentStatus(address _sponsor) public view returns(bool){
        return (sponsors[_sponsor].paid);
    }

    function setSponsorBalance(address _sponsor) external{
        require(msg.sender == _sponsor, "You are not a sponsor");
        sponsors[_sponsor].balance = 0;
        sponsors[_sponsor].paid = true;
    }

    function getProposalStatus() public view returns(bool){
        return taskComplete;
    }

    function getProposer() public view returns(address){
        return proposer;
    }

    function getProposerBonus(address _sponsor) public view returns (bool){
        return sponsors[_sponsor].stakebonus;
    }









}
