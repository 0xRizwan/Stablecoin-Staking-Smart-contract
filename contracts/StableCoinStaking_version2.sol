// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (uint256);    
}

contract StableCoinStaking_version2 is Initializable {
    IERC20 public stakedToken;
    IERC20 public rewardToken;
    address owner;


    // Staking duration plans
    // 1 Month (30 * 24 * 60 * 60)
    uint256 public oneMonthPlan = 2592000;
    // 6 Months (180 * 24 * 60 * 60)
    uint256 sixMonthPlan = 15552000;
    // 12 Months (365 * 24 * 60 * 60 )
    uint256 oneYearPlan = 31536000;
    
    // Staking Annual Percentage Rates(APR)
    uint256 public oneMonthAPR = 5;
    uint256 public oneMonthExtraAPR_100 = oneMonthAPR + extraAPR_100 ;
    uint256 public oneMonthExtraAPR_500 = oneMonthAPR + extraAPR_500 ;
    uint256 public oneMonthExtraAPR_1000 = oneMonthAPR + extraAPR_1000;

    uint256 public sixMonthAPR = 10;
    uint256 public sixMonthExtraAPR_100 = sixMonthAPR + extraAPR_100 ;
    uint256 public sixMonthExtraAPR_500 = sixMonthAPR + extraAPR_500 ;
    uint256 public sixMonthExtraAPR_1000 = sixMonthAPR + extraAPR_1000;

    uint256 public constant oneYearAPR = 15;
    uint256 public oneYearExtraAPR_100 = oneYearAPR + extraAPR_100 ;
    uint256 public oneYearExtraAPR_500 = oneYearAPR + extraAPR_500 ;
    uint256 public oneYearExtraAPR_1000 = oneYearAPR + extraAPR_1000;

    uint256 public extraAPR_100 = 2;
    uint256 public extraAPR_500 = 5;
    uint256 public extraAPR_1000 = 10;

    
    uint256 public selectedPlan;
    uint8 public totalStakers;

    struct StakeInfo {        
        uint256 startStaking;
        uint256 endStaking;        
        uint256 amount; 
        uint256 claimed;       
    }
    
    event Staked(address indexed from, uint256 amount);
    event Claimed(address indexed from, uint256 amount);
    
    mapping(address => StakeInfo) public stakeInfos;
    mapping(address => bool) public addressStaked;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _stakedToken, address _rewardToken) public initializer {
        stakedToken = IERC20(_stakedToken);
        rewardToken = IERC20(_rewardToken);
    }

    function changeTokens(address _newStakedToken, address _newRewardToken) public {
        stakedToken = IERC20(_newStakedToken);
        rewardToken = IERC20(_newRewardToken);
    }

    modifier onlyOwner() {
        require (owner == msg.sender, "Only owner can access this function");
        _;
    }


    function transferToken(address to,uint256 amount) external onlyOwner{
        require(stakedToken.transfer(to, amount), "Token transfer failed");  
    }

    function claimReward() external returns (bool){
        require(addressStaked[msg.sender] == true, "You have not stacked Tokens");
        require(stakeInfos[msg.sender].endStaking < block.timestamp, "Staking time is not over yet");
        require(stakeInfos[msg.sender].claimed == 0, "Stake is already claimed");

        uint256 rewardTokens;
        uint256 stakeAmount = stakeInfos[msg.sender].amount;
        uint256 stakeTime = stakeInfos[msg.sender].endStaking;

        // ************ one month *************
        // For One Month reward
        rewardTokens = (stakeTime == oneMonthPlan) ? (stakeAmount + (stakeAmount * oneMonthAPR /100)) : 0 ;
        // For one month and stake amount is greater than 100 and less than 500
        rewardTokens = (stakeTime == oneMonthPlan && stakeAmount > 100) ? (stakeAmount + (stakeAmount * oneMonthExtraAPR_100 /100)) : 0;
        // For one month and stake amount is greater than 500 and less than 1000
        rewardTokens = (stakeTime == oneMonthPlan && stakeAmount > 500) ? (stakeAmount + (stakeAmount * oneMonthExtraAPR_500 /100)) : 0;
        // For one month and stake amount is greater than 1000
        rewardTokens = (stakeTime == oneMonthPlan && stakeAmount > 1000) ? (stakeAmount + (stakeAmount * oneMonthExtraAPR_1000 /100)) : 0;

        // ************ Six month *************
        // For six Month reward
        rewardTokens = (stakeTime == sixMonthPlan) ? (stakeAmount + (stakeAmount * sixMonthAPR /100)) : 0;

        // For six month and stake amount is greater than 100 and less than 500
        rewardTokens = (stakeTime == sixMonthPlan && stakeAmount > 100) ? (stakeAmount + (stakeAmount * sixMonthExtraAPR_100 /100)) : 0;

        // For six month and stake amount is greater than 500 and less than 1000
        rewardTokens = (stakeTime == sixMonthPlan && stakeAmount > 500) ? (stakeAmount + (stakeAmount * sixMonthExtraAPR_500 /100)) : 0;

        // For six month and stake amount is greater than 1000
        rewardTokens = (stakeTime == sixMonthPlan && stakeAmount > 1000) ? (stakeAmount + (stakeAmount * sixMonthExtraAPR_1000 /100)) : 0;

        // ************ One Year *************
        // For one Year reward
        rewardTokens = (stakeTime == oneYearPlan) ? (stakeAmount + (stakeAmount * oneYearAPR /100)) : 0;
        // For one Year and stake amount is greater than 100 and less than 500
        rewardTokens = (stakeTime == oneYearPlan && stakeAmount > 100) ? (stakeAmount + (stakeAmount * oneYearExtraAPR_100 /100)) : 0;


        // For one Year and stake amount is greater than 500 and less than 1000
        rewardTokens = (stakeTime == oneYearPlan && stakeAmount > 500) ? (stakeAmount + (stakeAmount * oneYearExtraAPR_500 /100)) : 0;
        
        // For one Year and stake amount is greater than 1000
        rewardTokens = (stakeTime == oneYearPlan && stakeAmount > 1000) ? (stakeAmount + (stakeAmount * oneYearExtraAPR_1000 /100)) : 0;

        stakeInfos[msg.sender].claimed = rewardTokens;
        stakedToken.transfer(msg.sender, rewardTokens);

        emit Claimed(msg.sender, rewardTokens);

        return true;
    }

    function stakeToken(uint256 _selectedPlan, uint256 stakeAmount) external payable {
        require(stakeAmount > 0, "Stake amount should be greater than 0");
        require((_selectedPlan == oneMonthPlan) || (_selectedPlan== sixMonthPlan) || (_selectedPlan == oneYearPlan), "Invalid staking time, Please choose correct one");
        require(block.timestamp < _selectedPlan , "Plan Expired");
        require(addressStaked[msg.sender] == false, "You already participated");
        require(stakedToken.balanceOf(msg.sender) >= stakeAmount, "Insufficient Balance");

        selectedPlan = block.timestamp + _selectedPlan;

        stakedToken.transferFrom(msg.sender, address(this), stakeAmount);
        totalStakers++;
        addressStaked[msg.sender] = true;

        stakeInfos[msg.sender] = StakeInfo({                
                                                 startStaking: block.timestamp,
                                                 endStaking: selectedPlan,
                                                 amount: stakeAmount,
                                                 claimed: 0
            });
        
        emit Staked(msg.sender, stakeAmount);
    }    

}
