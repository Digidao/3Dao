require('dotenv').config()
const Tx = require("ethereumjs-tx").Transaction

//const BigNumber = require('bignumber.js');
const express = require('express')
const bodyParser = require('body-parser')
const http = require('http')
const Web3 = require('web3')
const HDWalletProvider = require('@truffle/hdwallet-provider')
const axios = require('axios')
const PORT = process.env.PORT || 5000
const app = express();
const server = http.createServer(app).listen(PORT, () => console.log(`Listening on ${ PORT }`))
const web3 = new Web3(new HDWalletProvider(process.env.PRIVATE_KEY, process.env.RPC_URL))

const DIGITRADE_TOKEN_CONTRACT_ADDRESS = ''
const DIGITRADE_TOKEN_ABI = require('./contracts/abis/digitrade_token_abi.json')
const DigitradeContract = new web3.eth.Contract(DIGITRADE_TOKEN_ABI, DIGITRADE_TOKEN_CONTRACT_ADDRESS)

const DAO_CONTRACT_ADDRESS = ''
const DAO_ABI = require('./contracts/abis/dao_abi.json')
const DAOContract = new web3.eth.Contract(DAO_ABI, DAO_CONTRACT_ADDRESS)

const POOL_CONTRACT_ADDRESS = ''
const POOL_ABI = require('./contracts/abis/pool_abi.json')
const PoolContract = new web3.eth.Contract(POOL_ABI,POOL_CONTRACT_ADDRESS)

const DAOIC_CONTRACT_ADDRESS = ''
const DAOIC_ABI = require('./contracts/abis/daoic_abi.json')
const DAOICContract = new web3.eth.Contract(DAOIC_ABI,DAOIC_CONTRACT_ADDRESS)

const REP_CONTRACT_ADDRESS = ''
const REP_ABI = require('./contracts/abis/representation_abi.json')
const REPContract = new web3.eth.Contract(REP_ABI, REP_CONTRACT_ADDRESS)

const est_gas  = 250000

const callingAddress = ''

checkBalance(callingAddress)
//Digitrade Token
async function checkBalance(meAddress){
      let balance = await DigitradeContract.methods.balanceOf(meAddress).call()
      console.log('Balance is ', balance)
  }

//DAO GOV
async function checkRegistration(){
  let status = await DAOContract.methods.checkRegistration().call()
  console.log("Registration status is", status)
}

async function propose(detailedDescription,_dgtCost,_votePeriod){
  try{
        DAOContract.methods.propose(detailedDescription,_dgtCost,_votePeriod).send({from:callingAddress, gas:250000}).on('confirmation', (confirmations, receipt) => {
        console.log(receipt);
          })
        }catch (error) {
        console.error(error)
        }
}

async function initializeProposal(proposalNumber){
  try{
    DAOContract.methods.initializeProposal(proposalNumber).send({from:callingAddress, gas:250000})
    .on('confirmation', (confirmations, receipt) => {
        console.log(receipt);
      })
    }catch (error) {
    console.error(error)
    }
  }

async function vote(proposalNumber,voteTrue,voteFalse){
  try{
    DAOContract.methods.vote(proposalNumber,voteTrue,voteFalse).send({from:callingAddress, gas:250000})
    .on('confirmation', (confirmations, receipt) => {
        console.log(receipt);
      })
    }catch (error) {
    console.error(error)
    }
}

async function tally(proposalNumber){
  try{
  DAOContract.methods.tally(proposalNumber).send({from:callingAddress, gas:250000})
    .on('confirmation', (confirmations, receipt) => {
        console.log(receipt);
      })
    }catch (error) {
    console.error(error)
    }
}

async function calculateReleaseBlock(_weeks){
  let releaseBlock = await DAOContract.methods.calculateReleaseBlock(_weeks).call()
  console.log("ReleaseBlock is", releaseBlock)
}

async function enactProposal(_proposal,_weeks,_facilitator){
  try{
    DAOContract.methods.enactProposal(_proposal,_weeks,_facilitator).send({from:callingAddress, gas:250000})
    .on('confirmation', (confirmations, receipt) => {
        console.log(receipt);
      })
    }catch (error) {
    console.error(error)
    }
}

//DAOIC
async function contractBalance(){
  let balance = await DAOICContract.methods.contractBalance().call()
  console.log("Proposal pool balance is", balance)
}

async function sponsorDAOIC(amount){
  try{
    DAOICContract.methods.sponsorDAOIC(amount).send({from:callingAddress, gas:250000})
    .on('confirmation', (confirmations, receipt) => {
        console.log(receipt);
      })
    }catch (error) {
    console.error(error)
    }
}

async function cancel(reason){
  try{
    DAOICContract.methods.cancel(reason).send({from:callingAddress, gas:250000})
    .on('confirmation', (confirmations, receipt) => {
        console.log(receipt);
      })
    }catch (error) {
    console.error(error)
    }
}

async function completionNotification(id, message, status){
  try{
    DAOICContract.methods.completionNotification(is, message, status).send({from:callingAddress, gas:250000})
    .on('confirmation', (confirmations, receipt) => {
        console.log(receipt);
      })
    }catch (error) {
    console.error(error)
    }

}

async function payFacilitator(){
  try{
    DAOICContract.methods.payFacilitator().send({from:callingAddress, gas:250000})
    .on('confirmation', (confirmations, receipt) => {
        console.log(receipt);
      })
    }catch (error) {
    console.error(error)
    }

}

async function getSponsorBalance(sponsor){
  let balance = await DAOICContract.methods.getSponsorBalance(sponsor).call()
  console.log("Proposal pool balance is", balance)
}

async function getSponsorPaymentStatus(sponsor){
  let status = await DAOICContract.methods.getSponsorPaymentStatus(sponsor).call()
  console.log("Sponsor payment status is", status)
}

async function setSponsorBalance(){
  try{
    DAOICContract.methods.setSponsorBalance().send({from:callingAddress, gas:250000})
    .on('confirmation', (confirmations, receipt) => {
        console.log(receipt);
      })
    }catch (error) {
    console.error(error)
    }

}

async function getProposalStatus(){
  let status = await DAOICContract.methods.getProposalStatus().call()
  console.log("Proposal status is", status)
}

async function getProposer(){
  let address = await DAOICContract.methods.getProposer().call()
  console.log("Proposer is", address)
}

async function getProposerBonus() {
  let status = await DAOICContract.methods.getProposerBonus().call()
  console.log("Proposer Bonus is", status)
}

async function getReleaseBlock(){
  let block = await DAOICContract.methods.getReleaseBlock().call()
  console.log("release Block is", block)
}

//Pool
async function fundStrength(){
  let strength = await PoolContract.methods.fundStrength().call()
  console.log("Fund Strength is", strength)
}

async function getPoolSupply(){
  let supply = await PoolContract.methods.getPoolSupply().call()
  console.log("Pool Supply is", supply)
}

async function getProposalTokenLimit(){
  let limit = await PoolContract.methods.getProposalTokenLimit().call()
  console.log("Proposal Token Limit is", limit)
}

async function repaySponsor(contract, sponsor){
  try{
    PoolContract.methods.repaySponsor(contract,sponsor).send({from:callingAddress, gas:250000})
    .on('confirmation', (confirmations, receipt) => {
        console.log(receipt);
      })
    }catch (error) {
    console.error(error)
    }

}

async function getSponsorBalance(contract, sponsor){
  let balance = await PoolContract.methods.getSponsorBalance(sponsor).call()
  console.log("Sponsor balance is", balance)
}

async function getProposalProposer(contract){
  let proposer = await PoolContract.methods.getProposalProposer(contract).call()
  console.log("The proposer is", proposer)
}

async function getProposalBonusStatus(contract){
  let status = await PoolContract.methods.getProposalBonusStatus(contract).call()
  console.log("The proposal bonus status is", status)
}

async function setSponsorBalance(contract,sponsor) {
  try{
    PoolContract.methods.setSponsorBalance().send({from:callingAddress, gas:250000})
    .on('confirmation', (confirmations, receipt) => {
        console.log(receipt);
      })
    }catch (error) {
    console.error(error)
    }
}

//Rep
async function getUnlockBlock(address){
  let block = await REPContract.methods.getUnlockBlock(address).call()
  console.log("Unlock Block is", block)
}

async function getRep(address){
  let status = await REPContract.methods.getRep(address).call()
  console.log("The address is a Rep equals", status)
}

async function registerRep(){
  try{
    REPContract.methods.registerRep().send({from:callingAddress, gas:250000})
    .on('confirmation', (confirmations, receipt) => {
        console.log(receipt);
      })
    }catch (error) {
    console.error(error)
    }
}
