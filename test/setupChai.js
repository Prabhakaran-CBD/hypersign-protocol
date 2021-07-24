/*Notes : chai set up are configured here so that we can import this set up file whereever whant to
use chai testing library..also chai doesn't allow to do multipletime setup going in each file
so need one time setup/config and then import them
*/
'use strict'
var chai = require('chai')
var BN = web3.utils.BN
var chaiBN = require('chai-bn')(BN)
var chaiAsPromised = require('chai-as-promised')

chai.use(chaiBN)
chai.use(chaiAsPromised)

module.exports = chai
