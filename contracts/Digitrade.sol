// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// Salutations !

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


contract Digitrade is SafeMath {
    address development;

    string public symbol;
    string public name;

    uint developmentFund;
    uint8 public decimals;
    uint _totalSupply;
    mapping(address => uint) balances;

    mapping(address => mapping(address => uint)) allowed;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);



    constructor() {
        symbol = "DGT";
        name = "Digitrade";
        decimals = 18;
        _totalSupply = 100_000_000e18; //100 million
        developmentFund = 20_000_000e18;  //20 million
        development = 0x590630aFCB35690AFB724e5d5b8C9ceE84E2E1be;
        balances[msg.sender] = _totalSupply;
        transfer(development, developmentFund);
    }

    function getDevFund()public view returns(uint){
        return balances[development];
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply - balances[address(0)];
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
