/*
This file is part of the PROOF Contract.

The PROOF Contract is free software: you can redistribute it and/or
modify it under the terms of the GNU lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The PROOF Contract is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with the PROOF Contract. If not, see <http://www.gnu.org/licenses/>.
*/

pragma solidity ^0.4.0;

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    function changeOwner(address _owner) onlyOwner public {
        require(_owner != 0);
        owner = _owner;
    }
}

contract Crowdsale is owned {
    
    uint256 public totalSupply = 0;
    mapping (address => uint256) public balanceOf;

    enum State { Disabled, PreICO, CompletePreICO, Crowdsale, Enabled }
    event NewState(State state);
    State public state = State.Disabled;
    uint  public crowdsaleStartTime;
    uint  public crowdsaleFinishTime;

    modifier enabledState {
        require(state == State.Enabled);
        _;
    }

    struct Investor {
        address investor;
        uint    amount;
    }
    Investor[] public investors;
    uint       public numberOfInvestors;
    
    function () payable {
        require(state != State.Disabled);
        uint256 tokensPerEther = 0;
        if (state == State.PreICO) {
            if (msg.value >= 100 ether) {
                tokensPerEther = 2500;
            } else {
                tokensPerEther = 2000;
            }
        } else if (state == State.Crowdsale) {
            if (msg.value >= 100 ether) {
                tokensPerEther = 1750;
            } else if (now < crowdsaleStartTime + 1 days) {
                tokensPerEther = 1500;
            } else if (now < crowdsaleStartTime + 1 weeks) {
                tokensPerEther = 1250;
            } else {
                tokensPerEther = 1000;
            }
        }
        if (tokensPerEther > 0) {
            uint256 tokens = tokensPerEther * msg.value / 1000000000000000000;
            if (balanceOf[msg.sender] + tokens < balanceOf[msg.sender]) throw; // overflow
            balanceOf[msg.sender] += tokens;
            totalSupply += tokens;
            numberOfInvestors = investors.length++;
            investors[numberOfInvestors] = Investor({investor: msg.sender, amount: msg.value});
        }
        //if (state == State.Enabled) { /* it is donation */ }
    }
    
    function startTokensSale() public onlyOwner {
        require(state == State.Disabled || state == State.CompletePreICO);
        crowdsaleStartTime = now;
        if (state == State.Disabled) {
            crowdsaleFinishTime = now + 7 days;
            state = State.PreICO;
        } else {
            crowdsaleFinishTime = now + 30 days;
            state = State.Crowdsale;
        }
        NewState(state);
    }
    
    function timeToFinishTokensSale() public constant returns(uint t) {
        require(state == State.PreICO || state == State.Crowdsale);
        if (now > crowdsaleFinishTime) {
            t = 0;
        } else {
            t = crowdsaleFinishTime - now;
        }
    }
    
    function finishTokensSale() public onlyOwner {
        require(state == State.PreICO || state == State.Crowdsale);
        require(now >= crowdsaleFinishTime);
        if ((this.balance < 400 ether && state == State.PreICO) ||
            (this.balance < 1000 ether && state == State.Crowdsale)) {
            // Crowdsale failed. Need to return ether to investors
            for (uint i = 0; i <  investors.length; ++i) {
                Investor inv = investors[i];
                uint amount = inv.amount;
                address investor = inv.investor;
                delete balanceOf[inv.investor];
                if(!investor.send(amount)) throw;
            }
            if (state == State.PreICO) {
                state = State.Disabled;
            } else {
                state = State.CompletePreICO;
            }
        } else {
            if (state == State.PreICO) {
                if (!msg.sender.send(this.balance)) throw;
                state = State.CompletePreICO;
            } else {
                if (!msg.sender.send(1000 ether)) throw;
                // Emit additional tokens for owner (20% of complete totalSupply)
                balanceOf[msg.sender] = totalSupply / 4;
                totalSupply += totalSupply / 4;
                state = State.Enabled;
            }
        }
        delete investors;
        NewState(state);
    }
}

contract Token is Crowdsale {
    
    string  public standard    = 'Token 0.1';
    string  public name        = 'PROOF';
    string  public symbol      = "PF";
    uint8   public decimals    = 0;

    modifier onlyTokenHolders {
        require(balanceOf[msg.sender] != 0);
        _;
    }

    mapping (address => mapping (address => uint256)) public allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burned(address indexed owner, uint256 value);

    function Token() Crowdsale() {}

    function transfer(address _to, uint256 _value) public enabledState {
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]); // overflow
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        Transfer(msg.sender, _to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]); // overflow
        require(allowed[_from][msg.sender] >= _value);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public enabledState {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender) public constant enabledState
        returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function burn(uint256 _value) public enabledState {
        require(now >= crowdsaleFinishTime + 1 years);
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        Burned(msg.sender, _value);

        // Send ether to caller
        uint amount;
        if (totalSupply == 0) {
            amount = this.balance;
        } else {
            amount = (this.balance * _value) / totalSupply;
        }
        if (!msg.sender.send(amount)) throw;
    }
}

contract ProofBase is Token {

    function ProofBase() Token() {}

    event VotingStarted(uint weiReqFund);
    event Voted(address indexed voter, bool inSupport);
    event VotingFinished(bool inSupport);

    struct Vote {
        bool    inSupport;
        address voter;
    }

    uint   weiReqFund;
    uint   votingDeadline;
    Vote[] votes;
    mapping (address => bool) voted;
    uint   numberOfVotes;

    function startVoting(uint _weiReqFund) public enabledState onlyOwner {
        require(_weiReqFund > 0 && _weiReqFund <= this.balance);
        weiReqFund = _weiReqFund;
        votingDeadline = now + 7 days;
        VotingStarted(_weiReqFund);
    }
    
    function votingInfo() public constant enabledState 
        returns(uint _weiReqFund, uint _timeToFinish) {
        _weiReqFund = weiReqFund;
        if (votingDeadline <= now) {
            _timeToFinish = 0;
        } else {
            _timeToFinish = votingDeadline - now;
        }
    }

    function vote(bool _inSupport) public onlyTokenHolders enabledState
        returns (uint voteId) {
        require(voted[msg.sender] != true);
        require(votingDeadline > now);
        voteId = votes.length++;
        votes[voteId] = Vote({inSupport: _inSupport, voter: msg.sender});
        voted[msg.sender] = true;
        numberOfVotes = voteId + 1;
        Voted(msg.sender, _inSupport); 
        return voteId;
    }

    function finishVoting() public enabledState onlyOwner
        returns (bool _inSupport) {
        require(now >= votingDeadline && weiReqFund <= this.balance);

        uint yea = 0;
        uint nay = 0;

        for (uint i = 0; i <  votes.length; ++i) {
            Vote v = votes[i];
            voted[v.voter] = false;
            uint voteWeight = balanceOf[v.voter];
            if (v.inSupport) {
                yea += voteWeight;
            } else {
                nay += voteWeight;
            }
        }

        _inSupport = (yea > nay);

        if (_inSupport) {
            if (!owner.send(weiReqFund)) throw;
        }

        VotingFinished(_inSupport);
        weiReqFund = 0;
        votingDeadline = 0;
        delete votes;
        numberOfVotes = 0;
    }
}

contract Proof is ProofBase {

    struct Swype {
        uint16  swype;
        uint    timestampSwype;
    }
    
    struct Video {
        uint16  swype;
        uint    timestampSwype;
        uint    timestampHash;
        address owner;
    }

    mapping (address => Swype) public swypes;
    mapping (bytes32 => Video) public videos;

    uint priceWei;

    function Proof() ProofBase() {}

    function setPrice(uint _priceWei) public onlyOwner {
        priceWei = _priceWei;
    }

    function swypeCode() public returns (uint16 _swype) {
        bytes32 blockHash = block.blockhash(block.number - 1);
        bytes32 shaTemp = sha3(msg.sender, blockHash);
        _swype = uint16(uint256(shaTemp) % 65536);
        swypes[msg.sender] = Swype({swype: _swype, timestampSwype: now});
    }
    
    function setHash(uint16 _swype, bytes32 _hash) payable public  {
        uint tokensProportion = balanceOf[msg.sender] * 100 / totalSupply;
        if (tokensProportion < 10) {
            if (tokensProportion < 5) {
                require(msg.value >= priceWei);
            } else {
                require(msg.value >= (priceWei / 2));
            }
        }
        require(swypes[msg.sender].timestampSwype != 0);
        require(swypes[msg.sender].swype == _swype);
        videos[_hash] = Video({swype: _swype, timestampSwype:swypes[msg.sender].timestampSwype, 
            timestampHash: now, owner: msg.sender});
        delete swypes[msg.sender];
    }
}