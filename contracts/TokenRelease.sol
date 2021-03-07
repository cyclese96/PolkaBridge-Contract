pragma solidity >=0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./PolkaBridge.sol";

contract TokenRelease {
    using SafeMath for uint256;
    PolkaBridge private _polkaBridge;
    event TokensReleased(address beneficiary, uint256 amount);
    address payable private owner;
    // beneficiary of tokens after they are released
    string public name = "PolkaBridge: Token Vesting";

    struct Vesting {
        string Name;
        address Beneficiary;
        uint256 Cliff;
        uint256 Start;
        uint256 AmountReleaseInOne;
        uint256 MaxRelease;
        bool IsExist;
    }
    mapping(address => Vesting) private _vestingList;

    constructor(
        PolkaBridge polkaBridge,
        address team,
        address marketing,
        address eco,
        uint256 cliffTeam,
        uint256 cliffMarketing,
        uint256 cliffEco,
        uint256 amountReleaseInOneTeam,
        uint256 amountReleaseInOneMarketing,
        uint256 amountReleaseInOneEco,
        uint256 maxReleaseTeam,
        uint256 maxReleaseMarketing,
        uint256 maxReleaseEco
    ) public {
        _polkaBridge = polkaBridge;
        _vestingList[team].Name = "Team Fund";
        _vestingList[team].Beneficiary = team;
        _vestingList[team].Cliff = cliffTeam;
        _vestingList[team].Start = 1611248400;//22 jan 2021
        _vestingList[team].AmountReleaseInOne = amountReleaseInOneTeam;
        _vestingList[team].MaxRelease = maxReleaseTeam;
        _vestingList[team].IsExist = true;

        _vestingList[marketing].Name = "Marketing Fund";
        _vestingList[marketing].Beneficiary = marketing;
        _vestingList[marketing].Cliff = cliffMarketing;
        _vestingList[marketing].Start = 1616346000;//22 March 2021
        _vestingList[marketing]
            .AmountReleaseInOne = amountReleaseInOneMarketing;
        _vestingList[marketing].MaxRelease = maxReleaseMarketing;
        _vestingList[marketing].IsExist = true;

        _vestingList[eco].Name = "Ecosystem Fund";
        _vestingList[eco].Beneficiary = eco;
        _vestingList[eco].Cliff = cliffEco;
        _vestingList[eco].Start = 1616346000;//22 March 2021
        _vestingList[eco].AmountReleaseInOne = amountReleaseInOneEco;
        _vestingList[eco].MaxRelease = maxReleaseEco;
        _vestingList[eco].IsExist = true;

        owner = msg.sender;
    }

    function depositETHtoContract() public payable {}

    function addLockingFund(
        string memory name,
        address beneficiary,
        uint256 cliff,
        uint256 start,
        uint256 amountReleaseInOne,
        uint256 maxRelease
    ) public {
        require(msg.sender == owner, "only owner can addLockingFund");
        _vestingList[beneficiary].Name = name;
        _vestingList[beneficiary].Beneficiary = beneficiary;
        _vestingList[beneficiary].Cliff = cliff;
        _vestingList[beneficiary].Start = start;
        _vestingList[beneficiary].AmountReleaseInOne = amountReleaseInOne;
        _vestingList[beneficiary].MaxRelease = maxRelease;
        _vestingList[beneficiary].IsExist = true;
    }

    function beneficiary(address acc) public view returns (address) {
        return _vestingList[acc].Beneficiary;
    }

    function cliff(address acc) public view returns (uint256) {
        return _vestingList[acc].Cliff;
    }

    function start(address acc) public view returns (uint256) {
        return _vestingList[acc].Start;
    }

    function amountReleaseInOne(address acc) public view returns (uint256) {
        return _vestingList[acc].AmountReleaseInOne;
    }

    function getNumberCycle(address acc) public view returns (uint256) {
        return
            (block.timestamp.sub(_vestingList[acc].Start)).div(
                _vestingList[acc].Cliff
            );
    }

    function getRemainBalance() public view returns (uint256) {
        return _polkaBridge.balanceOf(address(this));
    }

    function getRemainUnlockAmount(address acc) public view returns (uint256) {
        return _vestingList[acc].MaxRelease;
    }

    function isValidBeneficiary(address _wallet) public view returns (bool) {
        return _vestingList[_wallet].IsExist;
    }

    function release(address acc) public {
        require(acc != address(0), "TokenRelease: address 0 not allow");
        require(
            isValidBeneficiary(acc),
            "TokenRelease: invalid release address"
        );

        require(
            _vestingList[acc].MaxRelease > 0,
            "TokenRelease: no more token to release"
        );

        uint256 unreleased = _releasableAmount(acc);

        require(unreleased > 0, "TokenRelease: no tokens are due");

        _polkaBridge.transfer(_vestingList[acc].Beneficiary, unreleased);
        _vestingList[acc].MaxRelease -= unreleased;

        emit TokensReleased(_vestingList[acc].Beneficiary, unreleased);
    }

    function _releasableAmount(address acc) private returns (uint256) {
        uint256 currentBalance = _polkaBridge.balanceOf(address(this));
        if (currentBalance <= 0) return 0;
        uint256 amountRelease = 0;
        //require(_start.add(_cliff) < block.timestamp, "not that time");
        if (
            _vestingList[acc].Start.add(_vestingList[acc].Cliff) >
            block.timestamp
        ) {
            //not on time

            amountRelease = 0;
        } else {
            uint256 numberCycle = getNumberCycle(acc);
            if (numberCycle > 0) {
                amountRelease =
                    numberCycle *
                    _vestingList[acc].AmountReleaseInOne;
            } else {
                amountRelease = 0;
            }

            _vestingList[acc].Start = block.timestamp; //update start
        }
        return amountRelease;
    }

    function withdrawEtherFund() public {
        require(msg.sender == owner, "only owner can withdraw");
        uint256 balance = address(this).balance;
        require(balance > 0, "not enough fund");
        owner.transfer(balance);
    }
}
