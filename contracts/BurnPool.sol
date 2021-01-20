pragma solidity >=0.6.0;

import "./PolkaBridge.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract BurnPool {
    using SafeMath for uint256;
    string public name = "BurnPool Contract";
    address payable private owner;

    PolkaBridge private polkaBridge;

    constructor(PolkaBridge _polkaBridge) public {
        polkaBridge = _polkaBridge;
        owner = msg.sender;
    }

    function tokenBalance() public view returns (uint256) {
        return polkaBridge.balanceOf(address(this));
    }

    function burnAllToken() public {
        require(msg.sender == owner, "only owner can burn");

        polkaBridge.burn(tokenBalance());
    }

    function burnToken(uint256 amount) public {
        require(msg.sender == owner, "only owner can burn");

        polkaBridge.burn(amount);
    }

    function depositETHtoContract() public payable {}

    function withdrawFund() public {
        require(msg.sender == owner, "only owner can withdraw");
        uint256 balance = address(this).balance;
        require(balance > 0, "not enough fund");
        owner.transfer(balance);
    }
}
