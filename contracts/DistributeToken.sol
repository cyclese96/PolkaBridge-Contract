pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "@openzeppelin/contracts/ownership/Ownable.sol";

contract DistributeToken is Ownable {
    string public name = "PolkaBridge: Distribute Token";

    using SafeERC20 for IERC20;
    IERC20 token;

    constructor(IERC20 _tokenAddress) public {
        token = _tokenAddress;
    }

    function changeTokenContract(IERC20 tokenContract) public onlyOwner {
        token = tokenContract;
    }

    function distributeToken(
        address[] memory listUser,
        uint256[] memory listAmount
    ) public onlyOwner {
        for (uint256 i = 0; i < listUser.length; i++) {
            token.transfer(listUser[i], listAmount[i]);
        }
    }

    function withdrawToken() public {
        token.transfer(owner(), token.balanceOf(address(this)));
    }

    receive() external payable {}
}
