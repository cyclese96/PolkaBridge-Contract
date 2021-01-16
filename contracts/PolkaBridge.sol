pragma solidity >=0.6.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";


contract PolkaBridge is ERC20, ERC20Detailed,ERC20Burnable {
    constructor(uint256 initialSupply)
    ERC20Detailed("PolkaBridge", "PBR", 18)
    public
    {
        _deploy(msg.sender, initialSupply);
    }
}

