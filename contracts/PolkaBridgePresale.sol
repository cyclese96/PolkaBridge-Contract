pragma solidity >=0.6.0;

import "./PolkaBridge.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract PolkaBridgePresale {
    using SafeMath for uint256;
    string public name = "PolkaBridge Presale Contract";
    address payable private owner;
    
    PolkaBridge private polkaBridge;
    mapping(address => uint256) private _presaler;
    
    uint256 CONST_RATEPERETH;

    event logString(string value);

    constructor(PolkaBridge _polkaBridge) public {
        polkaBridge = _polkaBridge;
        owner = msg.sender;

        CONST_RATEPERETH = 100000;
    }

    function sendETHtoContract() public payable {
         require(block.timestamp >= 1611327600, "Presale not start"); //Friday, 22 January 2021 15PM UTC

        uint256 ethAmount = msg.value;
        require(
            ethAmount >= 200000000000000000,
            "minimum contribute is 0.2ETH"
        );
        require(ethAmount <= 1000000000000000000, "maximum contribute is 1ETH");
        _presaler[msg.sender] += ethAmount;

        if (_presaler[msg.sender] > 1000000000000000000) {
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
        require(block.timestamp > 1611934626, "Presale not ended"); //Friday, 29 January 2021
        polkaBridge.burn(remainToken());
    }
}
