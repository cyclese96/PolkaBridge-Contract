pragma solidity >=0.6.0;

import "./PolkaBridge.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract RewardPool {
    using SafeMath for uint256;
    string public name = "RewardPool Contract";
    address payable private owner;

    PolkaBridge private polkaBridge;

    constructor(PolkaBridge _polkaBridge) public {
        polkaBridge = _polkaBridge;
        owner = msg.sender;
    }

    function tokenBalance() public view returns (uint256) {
        return polkaBridge.balanceOf(address(this));
    }

    function withdrawToken(address _addres, uint256 amount) public {

        require(msg.sender == owner, "RewardPool: only owner can withdraw token");
        require(amount > 0, "RewardPool: not enough balance");

        polkaBridge.transfer(_addres, amount);
    }
}
