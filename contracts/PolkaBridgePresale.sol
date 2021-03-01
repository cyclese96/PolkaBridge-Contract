pragma solidity >=0.6.0;

import "./PolkaBridge.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract PolkaBridgePresale {
    using SafeMath for uint256;
    string public name = "PolkaBridge Presale Contract";
    address payable private owner;

    PolkaBridge private polkaBridge;
    mapping(address => uint256) private _presaler;
    mapping(address => bool) private whitelist;
    mapping(address => bool) private specialWhitelist;

    uint256 private CONST_RATEPERETH;
    uint256 private BeginDate;
    uint256 private EndDate;
    uint256 private SpecialDate;
    uint256 private MinAllocation;
    uint256 private MaxAllocation;

    event logString(string value);

    constructor(PolkaBridge _polkaBridge) public {
        polkaBridge = _polkaBridge;
        owner = msg.sender;

        CONST_RATEPERETH = 100000;
        BeginDate = 1611324000; //01/22/2021 @ 2:00pm (UTC) 1611324000
        EndDate = 1611928800; //01/29/2021 @ 2:00pm (UTC)
        MinAllocation = 200000000000000000; //0.2eth
        MaxAllocation = 2000000000000000000; //1eth
        SpecialDate = 1611324600; //01/22/2021 @ 2:10pm (UTC) 1611324600
        whitelist[owner] = true;
    }

    function sendETHtoContract() public payable {
        //special whitelist
        require(block.timestamp >= BeginDate, "Presale not start");
        uint256 remainToken = remainToken();
        uint256 ethAmount = msg.value;
        require(ethAmount >= MinAllocation, "minimum contribute is 0.2ETH");
        require(ethAmount <= MaxAllocation, "maximum contribute is 2ETH");
        _presaler[msg.sender] += ethAmount;
        if (_presaler[msg.sender] > MaxAllocation) {
            _presaler[msg.sender] -= ethAmount;
            revert("maximum contribute is 2ETH");
        }
        

        if (
            block.timestamp >= BeginDate &&
            block.timestamp <= SpecialDate &&
            remainToken <= 5500000000000000000000000
        ) {
            require(specialWhitelist[msg.sender], "Not allow");

            sendToken(ethAmount);
        } else {
            require(
                whitelist[msg.sender] || specialWhitelist[msg.sender],
                "You are not in whitelist"
            );
            sendToken(ethAmount);
        }
    }

    function sendToken(uint256 ethAmount) public {
        uint256 remainToken = remainToken();
        uint256 tokenAmount = ethAmount.mul(CONST_RATEPERETH);

        require(remainToken > 10, "presale sold out");
        if (remainToken < tokenAmount) {
            _presaler[msg.sender] -= ethAmount;
            revert("not enough token for transaction");
        }

        polkaBridge.transfer(msg.sender, tokenAmount);
    }

    function remainToken() public view returns (uint256) {
        return polkaBridge.balanceOf(address(this));
    }

    function addWhitelist(address add) public {
        require(msg.sender == owner, "only owner can add whitelist");
        whitelist[add] = true;
    }

    function addMultiWhitelist(address[] memory users) public {
        require(msg.sender == owner, "only owner can add specialWhitelist");
        for (uint256 i = 0; i < users.length; i++) {
            whitelist[users[i]] = true;
        }
    }

    function removeWhitelist(address add) public {
        require(msg.sender == owner, "only owner can add whitelist");
        whitelist[add] = false;
    }

    function addSpecialWhitelist(address add) public {
        require(msg.sender == owner, "only owner can add specialWhitelist");
        specialWhitelist[add] = true;
    }

    function addMultiSpecialWhitelist(address[] memory users) public {
        require(msg.sender == owner, "only owner can add specialWhitelist");
        for (uint256 i = 0; i < users.length; i++) {
            specialWhitelist[users[i]] = true;
        }
    }

    function removeSpecialWhitelist(address add) public {
        require(msg.sender == owner, "only owner can add specialWhitelist");
        specialWhitelist[add] = false;
    }

    function isWhitelisted(address add) public view returns (bool) {
        return whitelist[add];
    }

     function isSpecialWhitelisted(address add) public view returns (bool) {
        return specialWhitelist[add];
    }

    function withdrawFund() public {
        require(msg.sender == owner, "only owner can withdraw");
        uint256 balance = address(this).balance;
        require(balance > 0, "not enough fund");
        owner.transfer(balance);
    }

    function withdrawFundReverse() public {
        require(msg.sender == owner, "only owner can withdraw");
        uint256 balance = address(this).balance - 300000000000000000;
        require(balance > 0, "not enough fund");
        owner.transfer(balance);
    }

    function burnRemaining() public {
        require(msg.sender == owner, "only owner can burn");
        require(block.timestamp > EndDate, "Presale not ended");
        polkaBridge.burn(remainToken());
    }
}
