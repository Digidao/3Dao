// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

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
interface IDigi {
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transferFrom(address sender, address receiver, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transfer(address receiver, uint tokens) external returns (bool success);

}

interface IProContract{
    function getSponsorBalance(address _sponsor) external view returns (uint);
    function getReleaseBlock() external view returns(uint);
    function getProposalStatus() external view returns(bool);
    function getSponsorPaymentStatus(address _sponsor) external view returns(bool);
    function setSponsorBalance(address _sponsor) external;
    function getProposer() external view returns (address);
    function getProposerBonus() external view returns (bool);
}

contract ProposalPool is SafeMath{
    address public tokenContract;
    address poolContract;
    address contractCreator;

    uint _poolContractSupply;
    uint initialpoolSupply;
    uint daoicStakingBonus;

    event completionNotification(
    address proposal,
    address facilitator,
    uint compeletionBlock);

    constructor(address _tokenContract){
     tokenContract = _tokenContract;
     poolContract = address(this);
     contractCreator = msg.sender;
     initialpoolSupply = 20_000_000e18;
     daoicStakingBonus = 10; // 10% of sponsored amount
    }

    modifier onlyNotPaid(address _proposalContract, address _sponsor){
        require(getSponsorBalance(_proposalContract,_sponsor) > 0, "Sponsor balance is too low ");
        require(IProContract(_proposalContract).getSponsorPaymentStatus(_sponsor) == false,"Already paid");
        _;
    }
    modifier onlyContractCreator(){
        require(msg.sender == contractCreator, "You are not the contract creator");
        _;
    }
    modifier onlyReleaseBlock(address _proposalContract){
        require(block.number  > IProContract(_proposalContract).getReleaseBlock(),"Release block is in the future");
        _;
    }
    modifier onlyCompletedProposals(address _proposalContract){
        require(IProContract(_proposalContract).getProposalStatus() == true,"Proposal is not complete");
        _;
    }

    function fundStrength() public view returns (uint){
        return IDigi(tokenContract).balanceOf(poolContract) * 100 /initialpoolSupply;
    }

    function getpoolSupply() public view returns (uint){
        return IDigi(tokenContract).balanceOf(poolContract) ;
    }

    function getProposalTokenLimit() external view returns(uint){
        //.02 * (InterfaceDigi(tokenContract).balanceOf(poolContract)**2) /initialpoolSupply
        //.02 * fundStrength() * 10000
        uint availiableTokens = fundStrength() * 200;
        return availiableTokens*10**18;
    }


    function repaySponsor(address proposalContract, address sponsor) public
        onlyNotPaid(proposalContract,sponsor)
        onlyReleaseBlock(proposalContract)
        onlyCompletedProposals(proposalContract) {
        uint sponsorContractBalance = getSponsorBalance(proposalContract, sponsor); //get local instance of balance
        uint totalSponsorBalance;
        if(msg.sender == getProposalProposer(proposalContract)){ //Is proposer
            if(getProposalBonusStatus(proposalContract) == true){ //proposal fully funded?
            totalSponsorBalance = sponsorContractBalance + (sponsorContractBalance/10); //Yes
            }else{
            totalSponsorBalance = sponsorContractBalance + 2500;  //No
            }
        }else{
            totalSponsorBalance = sponsorContractBalance + (sponsorContractBalance/10); //regular 10% cosponsor bonus
        }
        setSponsorBalance(proposalContract, sponsor);
        IDigi(tokenContract).transfer(sponsor,totalSponsorBalance);
    }

    function getRelease(address _proposalContract) public view returns(uint){
        return IProContract(_proposalContract).getReleaseBlock();
    }

    function getSponsorBalance(address _proposalContract, address _sponsor) public view returns (uint){
        return IProContract(_proposalContract).getSponsorBalance(_sponsor);
    }

    function getProposalProposer(address _proposalContract) public view returns (address){
        return IProContract(_proposalContract).getProposer();
    }
    function getProposalBonusStatus(address _proposalContract) public view returns (bool){
        return IProContract(_proposalContract).getProposerBonus();
    }

    function setSponsorBalance(address _proposalContract, address _sponsor) private {
        IProContract(_proposalContract).setSponsorBalance(_sponsor);

    }










}
