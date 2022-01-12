interface InterfaceDaoGov {
  function getDaoGovAddress() external view returns (address);
  function getDigitradeAddress() external view returns (address);
}

 contract ProposalPool is SafeMath{

    address public digitrade;
    address pool;

    uint _poolSupply;
    uint startingSupply;

    constructor(address _digitrade){
     digitrade = _digitrade;
     pool = address(this);
     startingSupply = 20_000_000e18;
    }

    function fundStrength() public view returns (uint){
        return (InterfaceDigi(digitrade).balanceOf(pool) / startingSupply) * 100;
    }

    function getPoolSupply() public view returns (uint){
        return InterfaceDigi(digitrade).balanceOf(pool) ;
    }

    function getMaxAvailiableTokens() external view returns(uint){
        //.02 * (InterfaceDigi(digitrade).balanceOf(pool)**2) /startingSupply -> .02 * fundStrength() *10000 -> fundStrength() * 200;
        uint availiableTokens = fundStrength() * 200;
        return availiableTokens;
    }

    




}
