// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IToken {
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transferFrom(address sender, address receiver, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transfer(address receiver, uint tokens) external returns (bool success);

}

interface IProposalContract{
    function getSponsorBalance(address _sponsor) external view returns (uint);
    function getReleaseBlock() external view returns(uint);
    function getProposalStatus() external view returns(bool);
    function getSponsorPaymentStatus(address _sponsor) external view returns(bool);
    function setSponsorBalance(address _sponsor) external;
    function getProposer() external view returns (address);
    function getProposerBonus() external view returns (bool);
}

contract ProposalPool{
    address public tokenContract;
    address poolContract;
    address contractCreator;

    uint _poolContractSupply;
    uint initialpoolSupply;
    uint proposalBonus;

    event completionNotification(
    address proposal,
    address facilitator,
    uint compeletionBlock);

    constructor(address _tokenContract){
     tokenContract = _tokenContract;
     poolContract = address(this);
     contractCreator = msg.sender;
     initialpoolSupply = 20_000_000e18;
     proposalBonus = 10; // 10% of sponsored amount
    }

    modifier onlyNotPaid(address _proposalContract, address _sponsor){
        require(getSponsorBalance(_proposalContract,_sponsor) > 0, "Sponsor balance is too low ");
        require(IProposalContract(_proposalContract).getSponsorPaymentStatus(_sponsor) == false,"Already paid");
        _;
    }
    modifier onlyContractCreator(){
        require(msg.sender == contractCreator, "You are not the contract creator");
        _;
    }
    modifier onlyReleaseBlock(address _proposalContract){
        require(block.number  > IProposalContract(_proposalContract).getReleaseBlock(),"Release block is in the future");
        _;
    }
    modifier onlyCompletedProposals(address _proposalContract){
        require(IProposalContract(_proposalContract).getProposalStatus() == true,"Proposal is not complete");
        _;
    }

    function fundStrength() public view returns (uint){
        return IToken(tokenContract).balanceOf(poolContract) * 100 /initialpoolSupply;
    }

    function getpoolSupply() public view returns (uint){
        return IToken(tokenContract).balanceOf(poolContract) ;
    }

    function getProposalBonus() public view returns(uint){
        return (fundStrength() * proposalBonus);
    }

    function getProposalTokenLimit() external view returns(uint){
        uint availiableTokens = fundStrength() * 200;
        return availiableTokens*10**18;
    }

    function repaySponsor(address proposalContract) public
        onlyNotPaid(proposalContract, msg.sender)
        onlyReleaseBlock(proposalContract)
        onlyCompletedProposals(proposalContract) {
        uint sponsorContractBalance = getSponsorBalance(proposalContract, msg.sender); //get local instance of balance
        uint totalSponsorBalance;
        if(msg.sender == getProposalProposer(proposalContract)){ //Is proposer?
            if(getProposalBonusStatus(proposalContract) == true){ //proposal fully funded?
            totalSponsorBalance = sponsorContractBalance + (sponsorContractBalance/proposalBonus); //add bonus to balance
            }else{//propsal not fully funded by sponsor
            totalSponsorBalance = sponsorContractBalance + 2500;  //add small bonus to balance
            }
        }else{//Is a co-sponsor
            totalSponsorBalance = sponsorContractBalance + (sponsorContractBalance/proposalBonus); //regular 10% cosponsor bonus
        }
        setSponsorBalance(proposalContract, msg.sender);
        bool success = IToken(tokenContract).transfer(msg.sender,totalSponsorBalance);
        require(success, "The transaction was unsuccessful");
    }

    function getRelease(address _proposalContract) public view returns(uint){
        return IProposalContract(_proposalContract).getReleaseBlock();
    }

    function getSponsorBalance(address _proposalContract, address _sponsor) public view returns (uint){
        return IProposalContract(_proposalContract).getSponsorBalance(_sponsor);
    }

    function getProposalProposer(address _proposalContract) public view returns (address){
        return IProposalContract(_proposalContract).getProposer();
    }
    function getProposalBonusStatus(address _proposalContract) public view returns (bool){
        return IProposalContract(_proposalContract).getProposerBonus();
    }

    //Only a proposer or co-sponsor of the proposal can call and only repaySponsor function and can only set to 0
    function setSponsorBalance(address _proposalContract, address _sponsor) private {
        IProposalContract(_proposalContract).setSponsorBalance(_sponsor);
    }












}
