pragma solidity >=0.6.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";

contract PolkaBridge is ERC20, ERC20Detailed, ERC20Burnable {
    uint256 BeginExtract;

    constructor(uint256 initialSupply)
        public
        ERC20Detailed("PolkaBridge", "PBR", 18)
    {
        _deploy(msg.sender, initialSupply);
        BeginExtract = 1615766400; //15 Mar 2021
    }

    function _caculateExtractAmount(uint256 amount)
        internal
        override
        returns (uint256, uint256)
    {
        if (block.timestamp > BeginExtract) {
            uint256 extractAmount = (amount * 5) / 1000;

            uint256 burnAmount = (extractAmount * 10) / 100;
            uint256 rewardAmount = (extractAmount * 90) / 100;

            return (burnAmount, rewardAmount);
        } else {
            return (0, 0);
        }
    }
}
