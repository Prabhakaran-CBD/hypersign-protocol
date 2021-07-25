const HIDToken = artifacts.require('./HIDToken.sol')
const HIDVesting = artifacts.require('./HIDVesting.sol')
const config = require('../config')

const {
  _token,
  _beneficiary,
  _startTime,
  _cliffDuration,
  _waitDuration,
  _payOutPercentage,
  _payOutInterval,
  _revocable,
} = config.vesting

module.exports = async (deployer) => {
  const accounts = await web3.eth.getAccounts()
  //contract creates the token
  await deployer.deploy(HIDToken, config.TOTAL_SUPPLY)
  //HID Vesting contract
  await deployer.deploy(
    HIDVesting, //Contract
    HIDToken.address, //HID token address
    accounts[1], // address of beneficiary
    _startTime, // start time in seconds (epoch time)
    _cliffDuration, //cliff duration in seconds
    _waitDuration, //wait duration after cliff in seconds
    _payOutPercentage, //% (in multiple of 100 i.e 12.50% = 1250) funds released in each interval.
    _payOutInterval, //intervals (in seconds) at which funds will be released
    _revocable, //revocable flag
  )
  //transfer alloted tokens to the beneficiary
  let instance = await HIDToken.deployed()
  await instance.transfer(HIDVesting.address, 10000) // tansfer token to the beneficiary
}
