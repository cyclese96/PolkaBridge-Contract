pragma solidity >=0.6.0;

import "./PolkaBridge.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SwapToken {
    using SafeMath for uint256;
    string public name = "PolkaBridge: Swap from PBR to POBR";
    address payable private owner;

    address oldPBRAddress;

    PolkaBridge private polkaBridge;

    constructor(PolkaBridge _polkaBridge) public {
        polkaBridge = _polkaBridge;
        owner = msg.sender;
    }

   

    function swapPBRToPOBR(uint256 amount) public {
        require(amount > 0, "amount must to > 0");
        require(amount <= tokenContractBalance(), "exceeds amount limit");
        require(
            amount <= oldTokenBalance(msg.sender),
            "not enough balance"
        );

        
        ERC20Burnable(oldPBRAddress).burnFrom(msg.sender,amount);
        //send new POBR token
        polkaBridge.transfer(msg.sender, amount);
    }

    function tokenContractBalance() public view returns (uint256) {
        return polkaBridge.balanceOf(address(this));
    }

    function oldTokenBalance(address add) public view returns (uint256) {
        return ERC20Burnable(oldPBRAddress).balanceOf(add);
    }

      function oldTokenAddress() public view returns (address) {
        return oldPBRAddress;
    }

    function burnAllToken() public {
        require(msg.sender == owner, "only owner can burn");

        polkaBridge.burn(tokenContractBalance());
    }

    function burnToken(uint256 amount) public {
        require(msg.sender == owner, "only owner can burn");

        polkaBridge.burn(amount);
    }

    function withdrawFund() public {
        require(msg.sender == owner, "only owner can withdraw");
        uint256 balance = address(this).balance;
        require(balance > 0, "not enough fund");
        owner.transfer(balance);
    }

    //withdraw contract token
    //use for someone send token to contract
    //recuse wrong user

    function withdrawErc20(IERC20 token) public {
        token.transfer(owner, token.balanceOf(address(this)));
    }

    function setOldPBRAddress(address add) public {
        require(msg.sender == owner, "only owner can do it");
        oldPBRAddress = add;
    }

    receive() external payable {}
}
