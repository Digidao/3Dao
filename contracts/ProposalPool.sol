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
interface InterfaceDigi {
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function totalSupply() external view returns (uint);
    function transfer(address receiver, uint tokens) external returns (bool success);
    function transferFrom(address sender, address receiver, uint tokens) external returns (bool success);
    function getDevFund() external view returns(uint);
}

interface InterfaceDaoGov {
  function getDaoGovAddress() external view returns (address);
  function getDigitradeAddress() external view returns (address);
}

 contract ProposalPool is SafeMath{

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    address digitrade;
    address governance;
    address pool;
    uint proposalCost;

    uint _poolSupply;
    uint treasury;

    constructor(
        address _digitrade,
        address _governance

    ){
     digitrade = _digitrade;
     governance = _governance;
     pool = address(this);
    }

    function collectProfit(address _proposer, uint tokens) external {
        //require(msg.sender == InterfaceDaoGov(governance));
        balances[_proposer] = safeSub(balances[_proposer], tokens);
    }

    function poolSupply() public view returns (uint) {
        return _poolSupply - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public  view returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint tokens) public returns (bool success) {
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

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function getMaxAvailiableTokens() external view returns(uint){
        uint availiableTokens = (div(1,50)) * (balanceOf(pool) * balanceOf(pool)) / treasury;
        return availiableTokens;
    }

    function releaseProposal(address _contractAddress) external {

    }

    function transferToProposer(address proposer, uint tokens) public returns (bool success) {
        require(msg.sender == proposer);
        uint transferableAmount;
        balances[proposer] = safeAdd(balances [proposer], tokens);
        _poolSupply = _poolSupply - transferableAmount;
        emit Transfer(msg.sender, proposer, tokens);
        return true;
    }


}
