pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";

contract PolkaBridgeStaking is Ownable {
    string public name = "PolkaBridge: Staking";
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 rewardClaimed;
        uint256 lastBlock;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 stakeToken;
        IERC20 rewardToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accTokenPerShare;
        uint256 rewardPerBlock;
        uint256 totalTokenStaked;
        uint256 totalTokenClaimed;
    }

    // Info of each pool.
    PoolInfo[] private poolInfo;

    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    uint256 public totalUser;

    // The block number when staking  starts.
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(uint256 _startBlock) public {
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function addPool(
        uint256 _allocPoint,
        IERC20 _stakeToken,
        IERC20 _rewardToken,
        uint256 _rewardPerBlock,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 _lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;

        poolInfo.push(
            PoolInfo({
                stakeToken: _stakeToken,
                rewardToken: _rewardToken,
                allocPoint: _allocPoint,
                lastRewardBlock: _lastRewardBlock,
                accTokenPerShare: 0,
                rewardPerBlock: _rewardPerBlock,
                totalTokenStaked: 0,
                totalTokenClaimed: 0
            })
        );
    }

    function setPool(
        uint256 _pid,
        uint256 _allocPoint,
        uint256 _rewardPerBlock,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }

        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].rewardPerBlock = _rewardPerBlock;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _fromBlock, uint256 _toBlock)
        public
        view
        returns (uint256)
    {
        return _toBlock.sub(_fromBlock);
    }

    function getTotalTokenStaked(uint256 _pid) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        return pool.totalTokenStaked;
    }

    function pendingReward(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accTokenPerShare = pool.accTokenPerShare;
        uint256 totalTokenStaked = getTotalTokenStaked(_pid);

        if (block.number > pool.lastRewardBlock && totalTokenStaked > 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number); //number diff block
            uint256 tokenReward = multiplier.mul(pool.rewardPerBlock);

            accTokenPerShare = accTokenPerShare.add(
                tokenReward.mul(1e18).div(totalTokenStaked)
            );
        }
        return user.amount.mul(accTokenPerShare).div(1e18).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 totalTokenStaked = getTotalTokenStaked(_pid);

        if (totalTokenStaked == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 tokenReward = multiplier.mul(pool.rewardPerBlock);

        pool.accTokenPerShare = pool.accTokenPerShare.add(
            tokenReward.mul(1e18).div(totalTokenStaked)
        );
        pool.lastRewardBlock = block.number;
    }

    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        // if (_amount > 0) {
        //     pool.totalTokenStaked = pool.totalTokenStaked.add(_amount);
        // }
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accTokenPerShare).div(1e18).sub(
                    user.rewardDebt
                );
            if (pending > 0) {
                safeTokenTransfer(msg.sender, pending, _pid);
                pool.totalTokenClaimed = pool.totalTokenClaimed.add(pending);
                user.rewardClaimed = user.rewardClaimed.add(pending);
            }
        } else {
            //new user, or old user unstake all before
            totalUser = totalUser.add(1);
        }
        if (_amount > 0) {
            pool.stakeToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e18);
        user.lastBlock = block.number;
        emit Deposit(msg.sender, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: bad request");
        updatePool(_pid);
        uint256 pending =
            user.amount.mul(pool.accTokenPerShare).div(1e18).sub(
                user.rewardDebt
            );
        if (pending > 0) {
            safeTokenTransfer(msg.sender, pending, _pid);
            pool.totalTokenClaimed = pool.totalTokenClaimed.add(pending);
            user.rewardClaimed = user.rewardClaimed.add(pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.totalTokenStaked = pool.totalTokenStaked.sub(_amount);

            pool.stakeToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e18);
        user.lastBlock = block.number;
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.stakeToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    function safeTokenTransfer(
        address _to,
        uint256 _amount,
        uint256 _pid
    ) internal {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 totalPoolReward = pool.allocPoint;

        if (_amount > totalPoolReward) {
            pool.rewardToken.transfer(_to, totalPoolReward);
        } else {
            pool.rewardToken.transfer(_to, _amount);
        }
    }

    function getPoolInfo(uint256 _pid)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            poolInfo[_pid].accTokenPerShare,
            poolInfo[_pid].lastRewardBlock,
            poolInfo[_pid].rewardPerBlock,
            poolInfo[_pid].totalTokenStaked,
            poolInfo[_pid].totalTokenClaimed
        );
    }

    function getDiffBlock(address user, uint256 pid)
        public
        view
        returns (uint256)
    {
        UserInfo memory user = userInfo[pid][user];
        return block.number.sub(user.lastBlock);
    }
}
