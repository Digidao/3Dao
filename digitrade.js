require('dotenv').config()
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
const DIGITRADE_TOKEN_CONTRACT_ADDRESS = '0x7e74259C85f94864008a41378D6bb0847f63A902'
const DIGITRADE_TOKEN_ABI = require('./contracts/abis/digitrade_token_abi.json')


checkBalance('0x8B12bAcF44bd9a2A06fd09f326A0d8e70741E3c1')

async function checkBalance(meAddress){
      const DigitradeTokenContract = new web3.eth.Contract(DIGITRADE_TOKEN_ABI, DIGITRADE_TOKEN_CONTRACT_ADDRESS)
      let balance = await DigitradeTokenContract.methods.balanceOf(meAddress).call()
      console.log('Balance is ', balance)
  }
