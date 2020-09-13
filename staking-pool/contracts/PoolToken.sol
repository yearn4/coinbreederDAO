pragma solidity ^0.5.0;
import "./ERC20Interface.sol";
import "./BREE_STAKE_FARM.sol";
import "./SafeMath.sol";

contract StackToken {
    using SafeMath for uint256;
    ERC20Interface token;
    BREE_STAKE_FARM stakeFarm;
    address owner;
    uint256 poolsID = 1;
    uint256 unstakId;

    struct Pool {
        uint256 poolId;
        mapping(address => uint256) userBalance; //staking Balance
        address[] poolUsers; // User participants
        uint256 stakeTime; // stake start time
        uint256 poolBalance; // pool stackBalance
        uint256 unstakeTime; // Unstake token Time
        bool unstakeStatus; // Status of unstake
        uint256 unstakeBalance; // Reward + unstake
        uint256 ownerReward;  // Reward that send to Owner
    }
    // Token :  0x30c6eb233d21b66c98860eee5e9f162d34fe48cb

    // STAKE Farm:  0xfc8a588ebcec3689850614194be6183411493898
    // Stack Pool :0x0dc75df1d0fdcd4ee5f31697ae3eab9c639196c3
    // Owner : 0x9c830FFc3e4E7B23Bf122996616fb9054134f6E2
    mapping(uint256 => Pool) pools;
    mapping(address => uint256) balance;

    constructor(
        address _token,
        address _stakeFarm,
        address _owner
    ) public {
        token = ERC20Interface(_token);
        owner = _owner;
        stakeFarm = BREE_STAKE_FARM(_stakeFarm);
    }

    function stackingPool(uint256 _amount) public returns (bool) {
        require(
            token.balanceOf(msg.sender) >= _amount,
            "You have insufficient Balance"
        );
        require(
            token.allowance(msg.sender, address(this)) >= _amount,
            "You are not approve token to Contract"
        );
        token.transferFrom(msg.sender, address(this), _amount);

        Pool storage pool = pools[poolsID];

        if (pool.poolBalance >= 500) {
            poolsID++;
            pool.stakeTime = now;
            stakingCall(pool.poolBalance);
        }
        pool.poolId = poolsID;
        pool.userBalance[msg.sender] = _amount;
        pool.poolBalance += _amount;
        pool.poolUsers.push(msg.sender);

        return true;
    }

    function stakingCall(uint256 _amount) internal {
        // require(
        //     msg.sender == address(this),
        //     "Only Contract have access to call stack"
        // );
        // if(stakeFarm.YourActiveStake(address(this)))
        stakeFarm.AddToStake(_amount);
    }

    function callUnstake() public {
        // Called Unstake
        uint256 balanceBefore = token.balanceOf(address(this));
        stakeFarm.ClaimStakedTokens();
        stakeFarm.ClaimReward();
        uint256 balanceAfter = token.balanceOf(address(this));
     
        unstakId++;
        uint256 totalToken = balanceAfter.sub(balanceBefore);
        uint256 _ownerReward = totalToken.mul(10).div(100);

        totalToken = totalToken.sub(_ownerReward);
        Pool storage pool = pools[unstakId];
        pool.unstakeStatus = true;
        pool.unstakeBalance = totalToken;
        pool.ownerReward = _ownerReward;
    }

    function rewardDistribute(uint256 _unstakeID) internal {
        // Transfer tokens to all contributores
        // require(
        //     msg.sender == address(this),
        //     "Only Contract have access to call stack"
        // );
        Pool storage pool = pools[_unstakeID];
        uint256 perRewards = pool.unstakeBalance.div(pool.poolBalance);
        uint8 i;
        for (i = 0; i < pool.poolUsers.length; i++) {
            address userAddress = pool.poolUsers[i];
            uint256 balanceTo = pool.userBalance[userAddress].mul(perRewards);
            token.transfer(userAddress, balanceTo);
        }
        token.transfer(owner, pool.ownerReward);
        pool.unstakeStatus = true;
    }
}
