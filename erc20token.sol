//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.5;

interface ERC20Interface {
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function transfer(address to, uint256 tokens) external returns (bool success);
    
    function allowance(address tokenOwner, address spender) external view returns (uint256 remaining);
    function approve(address spender, uint256 tokens) external returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) external returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Cryptos is ERC20Interface {
    string public name = "Cryptos";
    string public symbol = "CRPT";
    uint256 public decimals = 0; //18 is very common
    uint256 public  override totalSupply;
    
    address public founder;
    mapping(address => uint) public balances;
    
    
    
    mapping(address => mapping(address => uint)) allowed;
    
     constructor(){
        totalSupply = 1000000;
        founder = msg.sender;
        balances[founder] = totalSupply;
    }
    
    function balanceOf(address tokenOwner) public override view returns (uint256 balance){
        return balances[tokenOwner];
    }
    
     function transfer(address to, uint256 tokens) public virtual override returns (bool success){
         require(balances[msg.sender] >= tokens);
         
         balances[to] += tokens;
         balances[msg.sender] -= tokens;
         emit Transfer(msg.sender, to, tokens);
         return true;
         
         
     }
     function allowance(address tokenOwner, address spender) public override view returns (uint256 remaining){
        return allowed[tokenOwner][spender];
     }
     
     function approve(address spender, uint256 tokens) public override returns (bool success){
         require(balances[msg.sender] >= tokens);
         require(tokens > 0);
         
         allowed[msg.sender][spender]= tokens;
         emit Approval(msg.sender, spender, tokens);
         return true;
         
     }
     
     function transferFrom(address from, address to, uint256 tokens) public virtual override returns (bool success){
         require(allowed[from][to] >= tokens);
         require(balances[from] >= tokens);
         
         balances[from] -= tokens;
         balances[to] += tokens;
         allowed[from][to] -= tokens;
         emit Transfer(from, to, tokens);
         return true;
         
     }
}

contract cryptosICO is Cryptos{
    address public admin;
    address payable public deposit;
    uint256 tokenPrice = 0.001 ether; // 1 eth = 1000 Cryptos
    uint256 public hardCap = 300 ether;
    uint256 public raisedAmount;
    uint256 public saleStart = block.timestamp;
    uint256 public saleEnd = block.timestamp + 604800; // ICO ends in a week 
    uint256 public tokenTradeStart = saleEnd + 604800; // toeken tranfereable one week after sale ends 
    uint256 public maxInvestment = 5 ether;
    uint256 public minInvestment = 0.1 ether;
    
    enum State {beforeStart, running, afterEnd, halted}
    State public icoState;
    
    constructor (address payable _deposit){
        deposit = _deposit;
        admin = msg.sender;
        icoState = State.beforeStart;
    }
    
    modifier onlyAdmin(){
        require (msg.sender == admin);
        _;
    }
    
    function halt() public onlyAdmin{
        icoState = State.halted;
    }
    
    function resume () public onlyAdmin {
        icoState = State.running;
    }
    
    function changeDepositAddress (address payable newDeposit) public onlyAdmin{
        deposit = newDeposit;
    }
    
    function getCurrentState() public view onlyAdmin returns(State) {
        if(icoState == State.halted){
            return State.halted;
        }else if (block.timestamp < saleStart){
            return State.beforeStart;
        } else if (block.timestamp >= saleStart && block.timestamp <= saleEnd){
            return State.running;
        } else {
            return State.afterEnd;
        }
    }
    
    event Invest (address investor, uint256 value, uint256 tokens);
    
    function invest () public payable returns(bool){
        icoState = getCurrentState();
        require(icoState == State.running);
        
        require(msg.value >= minInvestment && msg.value <= maxInvestment);
        raisedAmount += msg.value;
        require( raisedAmount <= hardCap);
        
        uint256 tokens = msg.value/tokenPrice;
        
        balances[msg.sender] += tokens;
        balances[founder] -= tokens;
        deposit.transfer(msg.value);
        
        emit Invest(msg.sender, msg.value, tokens);
        
        return true;
        
    }
    
    receive () external payable{
        invest ();
    } 
    function transfer(address to, uint256 tokens) public virtual override returns (bool success){
        require(block.timestamp > tokenTradeStart);
        Cryptos.transfer(to, tokens); // equivalent to super.transfer(to,tokens)
        return true;
    }
    
    function transferFrom(address from, address to, uint256 tokens) public override returns (bool success){
       require(block.timestamp > tokenTradeStart);
       Cryptos.transferFrom(from, to, tokens);
       return true;
    }
    function burn() public returns(bool){
        icoState = getCurrentState();
        require(icoState == State.afterEnd);
        balances[founder] = 0;
        return true;
        
    }
        
}
