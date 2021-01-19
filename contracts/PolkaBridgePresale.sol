pragma solidity >=0.6.0;

import "./PolkaBridge.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract PolkaBridgePresale {
    using SafeMath for uint256;
    string public name = "PolkaBridge Presale Contract";
    address payable private owner;

    PolkaBridge private polkaBridge;
    mapping(address => uint256) private _presaler;
    mapping(address => bool) whitelist;

    uint256 CONST_RATEPERETH;
    uint256 BeginDate;
    uint256 EndDate;
    uint256 MinAllocation;
    uint256 MaxAllocation;

    event logString(string value);

    constructor(PolkaBridge _polkaBridge) public {
        polkaBridge = _polkaBridge;
        owner = msg.sender;

        CONST_RATEPERETH = 100000;
        BeginDate = 1611327600; //Friday, 22 January 2021 15PM UTC
        EndDate = 1611934626; //Friday, 29 January 2021
        MinAllocation = 200000000000000000; //0.2eth
        MaxAllocation = 1000000000000000000; //1eth

        //init whitelist
        whitelist[owner] = true;
        whitelist[0x59f5836DAe9977A5124C022C4B6F9b8d3f5d61DA] = true;
    }

    function sendETHtoContract() public payable {
        require(block.timestamp >= BeginDate, "Presale not start");
        require(isWhitelisted(msg.sender), "You are not in whitelist");

        uint256 ethAmount = msg.value;
        require(ethAmount >= MinAllocation, "minimum contribute is 0.2ETH");
        require(ethAmount <= MaxAllocation, "maximum contribute is 1ETH");
        _presaler[msg.sender] += ethAmount;

        if (_presaler[msg.sender] > MaxAllocation) {
            _presaler[msg.sender] -= ethAmount;
            revert("maximum contribute is 1ETH");
        }

        sendToken(ethAmount);
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

    function removeWhitelist(address add) public {
        require(msg.sender == owner, "only owner can add whitelist");
        whitelist[add] = false;
    }

    function isWhitelisted(address add) public view returns (bool) {
        return whitelist[add];
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
