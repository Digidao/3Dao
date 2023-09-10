import { createRequire } from 'module';
const require = createRequire(import.meta.url);
require('dotenv').config();

const Web3 = require('web3');
const HDWalletProvider = require('@truffle/hdwallet-provider');
const abi = require('../abis/token.json');

const tokenContractAddress = '0x81405e897c8922c22e1779724c0550c2a67be73c';
const maticAddress = '0x07CADcb2C86B44671BB5d036F2d80eD2f38e0Ec8';

let myMaticBalance;
let polyweb3 = new Web3(new HDWalletProvider(process.env.PRIVATE_KEY, process.env.RPC_URL));

const tokenContract = new polyweb3.eth.Contract(abi, tokenContractAddress);

console.log('I farted 2');

export async function functionName() {
    console.log('I farted');
    //let tc = await tokenContract.methods.totalSupply().call();
    //console.log(tc);
}

async function getTotalSupply() {
    //let tc = await tokenContract.methods.totalSupply().call();
    //console.log(tc);
    //return tc;
    console.log('I farted 2');
}


  
  