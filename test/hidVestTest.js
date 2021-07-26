/*
Description : In this testing we are going to use chai (a assertion library for node.js), this
is paired/similary with javascrip testing framework like mocha, but  with more clean syntax.
*/
//note - Its clean-room-test so the test state is not shared.
//get the deployed contract instance
const HIDVesting = artifacts.require('HIDVesting.sol')
const HIDToken = artifacts.require('HIDToken.sol')

//const { web3 } = require('../utils/getContractInstance')
const chai = require('./setupChai')
//get the expect function from the chai
const expect = chai.expect
//need BN from web3
const BN = web3.utils.BN

//console.log('HIDVesting-', HIDVesting)

//Test cases
contract('HIDVesting', (accounts) => {
  //set the accounts for testing
  const [owner, beneficiary, hidToken, otherAccounts] = accounts
  //Get the instance of the deployed contract
  let HIDVestingContract
  let HIDTokenContract
  beforeEach(async () => {
    HIDVestingContract = await HIDVesting.deployed()
    HIDTokenContract = await HIDToken.deployed()
  })

  //test case - 1
  //test token total supply
  it('Verify the total token supply of the HID', async () => {
    const totalSupply = await HIDTokenContract.totalSupply()
    //console.log('Token supply', totalSupply)
    expect(totalSupply).to.be.a.bignumber.equal(
      new BN(50000000),
      'Failed: Not matched with intial supply count',
    )
  })

  //test case-2
  //testing the revoked flag(true/false) of the account and expecting defaule value as false ,
  //so if value is true for that account then its not eqaul
  it('Revoke flag shoube be false for the account since its not revoked', async () => {
    //console.log('Beneficiary address-', beneficiary)
    let revokedFlag = await HIDVestingContract.revoked(beneficiary) //defualt value is false for this flag
    //console.log('Reovked Flag -', revokedFlag)
    expect(revokedFlag).to.be.false
  })

  //test case -3
  it('hidToken address verify', async () => {
    const HIDToken = await HIDVestingContract.hidToken()
    //console.log('HIDVestingContract-', HIDTokenContract)
    expect(HIDToken).to.be.not.empty
  })

  //test case-4
  //testing vesting schedule to check number of vesting periods
  it('verify vesting detail of the beneficiary', async () => {
    const vestingDetails = await HIDVestingContract.getBenificiaryVestingDetails(
      beneficiary,
    )
    //console.log('numberOfVestingPeriods-', vestingDetails)
    //derive the calcuated value
    const calcVestingPeriods = (100 * 100) / 2000 //payout% as per given in the contract
    expect(vestingDetails[0]).to.be.a.bignumber.equal(
      new BN(calcVestingPeriods),
      'Failed:Value is not match',
    )
  })

  //test case-5
  //testing unlock time from vesting schedule
  it('verifing vesting schedule', async () => {
    const vestingSchedule = await HIDVestingContract.getBenificiaryVestingSchedules(
      beneficiary,
      0,
    )
    //console.log('UnlockTime-', vestingSchedule[0])
    //do convert the received unixtime/epoch time to local date string and then compare with releaseDate
    let vestingScheduleUnlockTime = vestingSchedule[0]
    let unixDate = new Date(vestingScheduleUnlockTime * 1000)
    //Derive the value that passed in the contract
    const startTime = Math.ceil((new Date().getTime() + 120000) / 1000)
    //console.log('start time-', startTime)
    //console.log('UnlockTime-', new Date(startTime * 1000).toLocaleDateString())
    //console.log('blocTimeout-', web3.eth.block)
    expect(unixDate.toLocaleDateString()).to.be.a.bignumber.equal(
      new BN(new Date(startTime * 1000).toLocaleDateString()),
      'Failure Message : value is not eqaul',
    )
  })

  //test case-6
  //test the initial/current balance of the contract it should be equal that paid
  //at initially for beneficiary
  it('Get Intial Balance of the beneficiary of the contract', async () => {
    //call the getBalance getter function from the contract
    const balance = await HIDVestingContract.getBalance()
    //console.log('Balance-', balance)
    expect(balance).to.be.a.bignumber.equal(
      new BN(10000),
      'Failed : Value is not matched ',
    )
  })

  //test case -8
  //testing the released amount of the account
  it('initial released amount of the address should be zero', async () => {
    //call the released getter function from the contract to check the released amount for the given account
    let releasedAmt = await HIDVestingContract.released(beneficiary)
    //console.log('releasedAmt-', releasedAmt)
    expect(releasedAmt).to.be.a.bignumber.equal(
      new BN(0),
      'Failed: value should not be zero',
    )
  })

  //test case - 7
  //test to release the vesting to the beneficiary based on the payout precentage
  it('release vesting validation', async () => {
    try {
      await HIDVestingContract.release(beneficiary, {
        from: beneficiary,
        gas: 1000000,
      })
        .then((res) => {
          console.log('result', res.message)
        })
        .catch((err) => {
          console.log('error message-', err.message)
        })
    } catch (err) {
      console.log('error message-', err.message)
    }

    // expect(getVestedAmount).to.be.a.bignumber.equal(
    //   new BN(0),
    //   'Failure: Value is should not be zero',
    // )
  })

  //test case -8
  //testing the released amount of the account
  it('released amount of the address', async () => {
    //call the released getter function from the contract to check the released amount for the given account
    let releasedAmt = await HIDVestingContract.released(beneficiary)
    console.log('releasedAmt-', releasedAmt)
    expect(releasedAmt).to.be.a.bignumber.not.equal(
      new BN(0),
      'Failed: value should not be zero',
    )
  })
}) //end of the contract test
