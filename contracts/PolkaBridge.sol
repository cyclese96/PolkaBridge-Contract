pragma solidity >=0.6.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";

contract PolkaBridge is ERC20, ERC20Detailed, ERC20Burnable {
    

    constructor(uint256 initialSupply)
        public
        ERC20Detailed("PolkaBridge", "POBR", 18)
    {
        _deploy(msg.sender, initialSupply,1615766400);//15 Mar 2021 1615766400
        
    }

    //withdraw contract token
    

}
