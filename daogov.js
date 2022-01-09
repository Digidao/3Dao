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
const DAO_CONTRACT_ADDRESS = '0x8a29fd915aae034e6524799275822ed384ff6a89'
const DAO_ABI = require('./contracts/abis/dao_abi.json')
const DAOContract = new web3.eth.Contract(DAO_ABI, DAO_CONTRACT_ADDRESS)
const est_gas  = 250000

const meAddress = '0x8B12bAcF44bd9a2A06fd09f326A0d8e70741E3c1'

//checkRegistration('0x8B12bAcF44bd9a2A06fd09f326A0d8e70741E3c1')
//propose('I like apples', 1000, 11)

checkRegistration(meAddress)

async function checkRegistration(){
  let status = await DAOContract.methods.checkRegistration().call()
  console.log("Registration status is", status)
}

async function propose(detailedDescription,_dgtCost,_votePeriod){
  try{
        const theContract = new web3.eth.Contract(DAO_ABI , DAO_CONTRACT_ADDRESS)
        theContract.methods.propose(detailedDescription,_dgtCost,_votePeriod).send({from:meAddress, gas:250000}).on('confirmation', (confirmations, receipt) => {
        console.log(receipt);
          })
        }catch (error) {
        console.error(error)
        }
}

async function initializeProposal(proposalNumber){
  try{
    const theContract = new web3.eth.Contract(DAO_ABI , DAO_CONTRACT_ADDRESS)
    theContract.methods.initializeProposal(proposalNumber).send({from:meAddress, gas:250000})
    .on('confirmation', (confirmations, receipt) => {
        console.log(receipt);
      })
    }catch (error) {
    console.error(error)
    }
  }

async function vote(proposalNumber,voteTrue,voteFalse){
  try{
    const theContract = new web3.eth.Contract(DAO_ABI , DAO_CONTRACT_ADDRESS)
    theContract.methods.vote(proposalNumber,voteTrue,voteFalse).send({from:meAddress, gas:250000})
    .on('confirmation', (confirmations, receipt) => {
        console.log(receipt);
      })
    }catch (error) {
    console.error(error)
    }
}

async function tally(proposalNumber){
  try{
  const theContract = new web3.eth.Contract(DAO_ABI , DAO_CONTRACT_ADDRESS)
  theContract.methods.tally(proposalNumber).send({from:meAddress, gas:250000})
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
    const theContract = new web3.eth.Contract(DAO_ABI , DAO_CONTRACT_ADDRESS)
    theContract.methods.enactProposal(_proposal,_weeks,_facilitator).send({from:meAddress, gas:250000})
    .on('confirmation', (confirmations, receipt) => {
        console.log(receipt);
      })
    }catch (error) {
    console.error(error)
    }
}
