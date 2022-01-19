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
        address [] alreadyVoted;
        bool voteEnded;
        bool votePass;
        bool enacted;
        uint initializationPoints;
        bool initialized;
        address [] initializers;
        bool active;
    }

    mapping(address => Proposal )  public proposers;
    Proposal[] public proposals;

    constructor(){
        minimumVotingPeriod = 10; //(Change to 70000)minimum blocks(Around 7 days) voting is allowed on proposal
        proposalIntializationThreshold = 1000000000000000000000000; //1000000 DGT 1% of total supply
        digi = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
        tokenAddress = 0xd9145CCE52D386f254917e481eB44e9943F39138; //Address of DGT token
        pool = 0xf8e81D47203A594245E36C48e151709F0C19fBe8;
        reps = 0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8; //Address of Represenatives
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

    function propose(string memory detailedDescription, uint256 _dgtCost, uint _votePeriod) public onlyReps(msg.sender) {
        require((_dgtCost) < getMaxAvailiableTokens(), "Proposal cost exceeds 2% of avaliable tokens");
        require(_votePeriod > minimumVotingPeriod, "Not enough time for potential voters to become aware of proposal");
        address[] memory iVoted;
        proposals.push(Proposal({
                proposer: msg.sender,
                basic_description: detailedDescription,
                yesVotes: 0,
                noVotes: 0,
                endVoteBlock: add(_votePeriod,block.number),
                proposalCost: _dgtCost,
                alreadyVoted:iVoted,
                voteEnded:false,
                votePass:false,
                enacted:false,
                initializationPoints: 0,
                initialized:false,
                initializers:iVoted,
                active:false
            }));
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
      return ("1000000 required to initialize, Current initialization points: ", proposals[_proposal].initializationPoints);
        }
    }

    function vote(uint _proposal, bool yes, bool no) public onlyReps(msg.sender) onlyInitializedProposal(_proposal) returns (string memory message){
       for (uint i=0; i<proposals[_proposal].alreadyVoted.length; i++) {
       require(proposals[_proposal].alreadyVoted[i] != msg.sender, "Only one vote per address");}
       require(proposals[_proposal].endVoteBlock > block.number, "Voting has ended");
       if(yes == true){
           require(no == false);
           proposals[_proposal].yesVotes += 1;
           return "You voted yes!";}
       if(no == true){
           require(yes == false);
           proposals[_proposal].noVotes += 1;
           return "You voted no!";}
       proposals[_proposal].alreadyVoted.push(msg.sender);

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
        proposalContractID = proposalContractID ++;


        Daoic newContract = new Daoic(
            proposalContractID,
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



        return newContractAddress;
    }


    function verfifyProposalContract(uint id, address contractAddress) public view returns (bool){
        require(proposalContracts[id] == contractAddress, "This contract can not be verified");
        return true;
    }
}




interface IGov {
  function verfifyProposalContract(uint id, address contractAddress) external view returns (bool);
}

contract Daoic is SafeMath{
    uint id;
    address public tokenContract;
    address public reps;
    address public thisContract;
    address public governanceContract;

    address public digi;
    address public proposer;
    address public facilitator;

    uint public maximumProposerAmount;
    uint public fundingDeadline;
    bool enable;

    uint public notificationDeadline;
    bool public taskComplete;

    uint public proposalCost;
    uint public releaseBlock;

    uint public _currentStake;

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
    Sponsor[] sponsor;

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
        releaseBlock = _releaseBlock; //Facilitator is paid after this block
        digi = _digi;
        reps = _represensative;
        tokenContract = _tokenContract;
        governanceContract = _governanceContract;

        thisContract = address(this);
        notificationDeadline = safeSub(_releaseBlock , div(_releaseBlock,10)); //Block where 'completionNotification' must be called.
        fundingDeadline = (block.number + 30000); // 3 days to completly fund proposal
        enable = false;
        penalized = false;
        maximumProposerAmount = (proposalCost * 85)/100; // 85% of proposal cost
        timeOut = 0;
        taskComplete = false;
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
        require(msg.sender == digi, "Not the Digi");
        _;}
    modifier onlyMaxContractValue(uint _amount){
        require(_amount <= (maximumProposerAmount), "Sending more than 85% of proposal cost");
        _;}
    modifier onlyBeforeCutoff{
        require(block.number < fundingDeadline, "Funding deadline has passed");
        _;}
    modifier onlyReps(address _address){
        require(IRep(reps).getRep(_address),"You are not a rep");
        _;}
    modifier onlyAvailiableStake(uint _amount){
        require(_amount <= safeSub(proposalCost,_currentStake), "Sending more than the availiableStake");
        _;
        }
    modifier onlyVerifiedProposals(uint _id, address _proposal){
        require(IGov(governanceContract).verfifyProposalContract(_id, _proposal), "This contract can not be verified");
        _;
    }


    function contractBalance() public view returns(uint){
        return IDigi(tokenContract).balanceOf(thisContract);
    }

    function SponsorDAOIC(uint _amount) public onlyVerifiedProposals(id, thisContract) onlyReps(msg.sender) onlyBeforeCutoff onlyAvailiableStake(_amount) onlyMaxContractValue(_amount) returns (string memory message, uint _notificationDeadline){
        require(_amount > 0,"Can't sponsor proposal with a 0 value");
        require(sponsors[msg.sender].balance == 0, "You have already sponsored this proposal");
        if(msg.sender == proposer){
        sponsor.push(Sponsor({
            sponsorAddress:msg.sender,
            balance:_amount,
            isSponsor:true,
            stakebonus:false,
            paid:false
        }));
        }else{
        sponsor.push(Sponsor({
            sponsorAddress:msg.sender,
            balance:_amount,
            isSponsor:false,
            stakebonus:false,
            paid:false
        }));
        }
        _currentStake = _currentStake + _amount;
        uint fundsNeeded = safeSub(proposalCost , contractBalance());
        emit FundingNeeded(fundsNeeded, notificationDeadline);

        message = "Completion notification due by";
        _notificationDeadline = notificationDeadline;
        enable = true;
        //GET APPROVAL!!!
        bool approved = IDigi(tokenContract).approve(thisContract, _amount);
        require(approved);
        bool sent = IDigi(tokenContract).transferFrom(msg.sender,thisContract, _amount);
        require(sent);
        return (message, _notificationDeadline);

    }

    function cancel( string memory reason) public onlyVerifiedProposals(id, thisContract) onlyEnabled returns (string memory _reason){
        if(msg.sender == digi|| msg.sender == facilitator){
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

    function completionNotification(uint _id, string memory message, bool _complete) public onlyVerifiedProposals(_id, thisContract) onlyFacilitator {
      require(block.number < notificationDeadline, "The time to complete the proposal has passed");
      taskComplete = _complete;
      emit TaskComplete(message, _complete);
      if(_complete == false){
        cancel(message);
      }
        stakebalance[facilitator] = stakebalance[address(0)];

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









    }
