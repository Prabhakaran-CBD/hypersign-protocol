//SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


contract HIDVesting is Ownable{
    
    using SafeERC20 for IERC20; 
    using SafeMath for uint256;

    IERC20 public hidToken;

    event TokensReleased(address indexed token, uint256 amount);
    event TokenVestingRevoked(address indexed token);
    event etherReceived(address indexed _sender, uint256 amount);

    // beneficiary of tokens after they are released
    address private beneficiary;

    // Durations and timestamps are expressed in UNIX time, the same units as block.timestamp.
    uint256 private cliff;
    uint256 private start;
    uint256 private duration;
    uint256 private waitTime;
    bool private revocable;
    
   //call the constructor for config initial value
   //its beneficiay specific
   constructor(
        IERC20 _token, // HID token address
        address _beneficiary, // address of beneficiary
        uint256 _startTime, // start time in seconds (epoch time)
        uint256 _cliffDuration, // cliff duration in seconds
        uint256 _waitDuration, // wait duration after cliff in seconds
        uint256 _payOutPercentage, // % (in multiple of 100 i.e 12.50% = 1250) funds released in each interval.
        uint256 _payOutInterval, // intervals (in seconds) at which funds will be released
        bool _revocable
    ) {
      
        start = _startTime;
        cliff = start.add(_cliffDuration);
        waitTime = cliff.add(_waitDuration);
        hidToken = _token;
        beneficiary = _beneficiary;
        revocable = _revocable;
        duration = waitTime;
       //Preparing vesting schedule
        uint256 numberOfPayouts = (100 * PERCENTAGE_MULTIPLIER).div(_payOutPercentage);

        //uint256 st = _startTime.add((_cliffDuration).add(_waitDuration));//same as waitTime

        Vesting storage vesting = vestings.push();
        for (uint256 i = 0; i < numberOfPayouts; i++) {
            vesting.vestingSchedules.push(
                VestingSchedule({
                    unlockPercentage: (i + 1).mul(_payOutPercentage),
                    unlockTime : duration.add(i.mul(_payOutInterval)) 
                })
            );
        }

        vesting.numberOfVestingPeriods = numberOfPayouts;
        vesting.totalUnlockedAmount = 0;
        vesting.lastUnlockedTime = 0;

        beneficiaryVestingScheduleRegistry[_beneficiary] = vesting;
    }

    mapping(address => uint256) private _released;
    mapping(address => bool) private _revoked;

    struct VestingSchedule {
        uint256 unlockTime; //releaseTime
        uint256 unlockPercentage; //releasePrecentage
    }

    struct Vesting {
        VestingSchedule[] vestingSchedules;
        uint256 numberOfVestingPeriods;
        uint256 totalUnlockedAmount;
        uint256 lastUnlockedTime;
    }

    uint256 PERCENTAGE_MULTIPLIER = 100;
    uint256 totalReleasedAmount = 0;

    mapping(address => Vesting) public beneficiaryVestingScheduleRegistry;
    Vesting[] public vestings;
   
    /**
     * @notice Only allow calls from the beneficiary of the vesting contract
     */
    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary);
        _;
    }

    //ether receive function
    receive() external payable {
        //emit the event once ether received by the contract
        emit etherReceived(msg.sender, msg.value);
    }

   
    //helper/getter function
    function released(address _beneficiary) public view returns(uint256) {
        return _released[_beneficiary];
    }
    
    function revoked(address _beneficiary) public view returns(bool) {
        return _revoked[_beneficiary];
    }

    //get the balance of the address
    function getBalance() public view returns (uint256) {
        return hidToken.balanceOf(address(this)); 
    }
    
    function getBenificiaryVestingSchedules(address _beneficiary,uint256 _index) public view returns (uint256, uint256) {
        return (
            beneficiaryVestingScheduleRegistry[_beneficiary].vestingSchedules[_index].unlockTime,
            beneficiaryVestingScheduleRegistry[_beneficiary].vestingSchedules[_index].unlockPercentage
        );
    }
    
     function getBenificiaryVestingDetails(address _beneficiary) public view returns (uint256, uint256,uint256 )
    {
        return (
            beneficiaryVestingScheduleRegistry[_beneficiary].numberOfVestingPeriods,
            beneficiaryVestingScheduleRegistry[_beneficiary].totalUnlockedAmount,
            beneficiaryVestingScheduleRegistry[_beneficiary].lastUnlockedTime
        );
    }
    
    //set token by the owner
    function setToken(IERC20 token) public onlyOwner {
        hidToken = token;
    }
    
    //Allow owner to revoke the vesting and vested are return to owner if it is remain in the contract
    function revoke(address _beneficiary, uint256 _index) public onlyOwner {
       //check the revocable flag can be revoke or not
       require(revocable, "Vesting can not be revocable!");
       //check already revoked , if it revoked then it should be true so flip the value to trigger the error
       require(!_revoked[_beneficiary], "Vesting already revoked!");
     
       uint256 balance = hidToken.balanceOf(address(this));
      
       //get the releasable balance amount
       uint256 unreleased = getReleasableAmount(_beneficiary, _index);
      
       //get the refund from the balance
       uint256 refund = balance.sub(unreleased);
      
       //revoke only if there is refund amount exist
       require(refund > 0, 'No refund to revoke!');
      
       //set the revoke flag enable/true  
       _revoked[_beneficiary] = true;
      
       //transfer the refund to Owner, owner() function is inherited from Ownable contract
       hidToken.safeTransfer(owner(), refund);
      
       //emit the event for revoked 
       emit TokenVestingRevoked(_beneficiary);
        
    }
    
    //release only can do by the respective beneficiary  
    function release(address _beneficiary) public onlyBeneficiary {
        
        //fund can not be released before cliff period
        require(block.timestamp > cliff,"No funds can be released during cliff period");

        // no funds to be released before waitTime
        require(block.timestamp >= waitTime,"No funds can be released during waiting period");
        
        //check is it already revoked, if it is then its true so flip the value to stop for release
        require(!_revoked[_beneficiary] , 'Vesting is revoked can not release');

        Vesting storage v = beneficiaryVestingScheduleRegistry[_beneficiary];

        
        uint256 index;
        if (v.lastUnlockedTime == 0) {
            index = 0;
        } else {
            for (uint256 i = 1; i <= v.vestingSchedules.length; i++) {
                if (
                    block.timestamp > v.lastUnlockedTime &&  block.timestamp <= v.vestingSchedules[i].unlockTime) {
                    index = i;
                    break; 
                }
            }
        }

        uint256 unreleased = getReleasableAmount(_beneficiary, index);

        v.lastUnlockedTime = v.vestingSchedules[index].unlockTime;
        v.totalUnlockedAmount = v.totalUnlockedAmount.add(unreleased);
        
        //add the released amount for the beneficiary 
        _released[_beneficiary] = _released[_beneficiary].add(unreleased);

        hidToken.safeTransfer(_beneficiary, unreleased); 
        //emit the event for released token
        emit TokensReleased(_beneficiary, unreleased );
    }

     //get releasable amount
    function getReleasableAmount(address _beneficiary, uint256 _index) public view returns (uint256){
        
        Vesting memory v = beneficiaryVestingScheduleRegistry[_beneficiary]; 
        return getVestedAmount(_beneficiary, _index).sub(v.totalUnlockedAmount); //initial balance should be zero
    }

    //get Vested Amount
    function getVestedAmount(address _beneficiary, uint256 _index) public view returns (uint256){
        
        Vesting memory v = beneficiaryVestingScheduleRegistry[_beneficiary];

        uint256 currentBalance = hidToken.balanceOf(address(this));
        uint256 totalBalance = currentBalance.add(v.totalUnlockedAmount); 

        VestingSchedule memory vs = v.vestingSchedules[_index];
        
        return(totalBalance.mul(vs.unlockPercentage)).div((100 * PERCENTAGE_MULTIPLIER));
    }
    
   
    
}//end of the contract