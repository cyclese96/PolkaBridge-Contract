pragma solidity >=0.6.0;

import "./PolkaBridge.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";

contract DistributeAirdrop is Ownable {
    string public name = "PolkaBridge: Distribute Airdrop";

    PolkaBridge private polkaBridge;

    constructor(PolkaBridge _polkaBridge) public {
        polkaBridge = _polkaBridge;
    }

    function distributeAirdrop(
        address[] memory listUser,
        uint256[] memory listAmount
    ) public onlyOwner {
        for (uint256 i = 0; i < listUser.length; i++) {
            polkaBridge.transferWithoutDeflationary(listUser[i], listAmount[i]);
        }
    }

    //withdraw contract token
    //use for someone send token to contract
    //recuse wrong user

    function withdrawPBRToken() public {
        polkaBridge.transferWithoutDeflationary(
            owner(),
            polkaBridge.balanceOf(address(this))
        );
    }

    receive() external payable {}
}
