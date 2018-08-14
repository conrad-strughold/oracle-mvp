# Bug Verification Oracle [![Build Status](https://travis-ci.org/solidified-platform/oracle-mvp.svg?branch=master)](https://travis-ci.org/solidified-platform/oracle-mvp) [![Coverage Status](https://coveralls.io/repos/github/solidified-platform/oracle-mvp/badge.svg)](https://coveralls.io/github/solidified-platform/oracle-mvp)
Smart contracts implementing the selling of bug verification oracles(BOV)

### Centralized Bug Oracles
The CBO is a more specialized version of Gnosis Centralized Oracle, which takes information regarding a specif bug and provides a ruling indicating weather it is valid or not. A proxied version of a centralized bug oracle is deployed after both parts agree on the bug information and the fees are paid. After the deployed, the contract is ready to recieve an outcome from the centralized entity, whci may either be valid, invalid or non-determined, used for when there's an issue with the bug information.

### The BOV Vending Machine
The concept of this smart contracts is to implement a system for anyone to request BOVs on demand, by paying a fee in SOLID Tokens.  
This contract handles the logic behind receiving tokens and deploying the lastest version of the oracle.

#### BOV deployment
There are two ways for a contract to be deployed:
1) By a privileged user:
This is way is dedicated to be called by the Solidified Bug Bounty platform, to resolve a disagreement between two users. In this case, both of the parties already agree on the provided bug information and the fees to participate in a oracle, and therefore, it doesn't require a multi-step process.

2) By a maker-taker process:
This starts with a oracle proposal and takes as input a taker address, which must later accepts the proposal, and an a IPFS Hash of the detailed bug information(source code, intended behavior, bug description). The sender(which is the maker) has his fees deducted and the proposal can be canceled with a refund at any given moment until the taker approves it.

The taker needs to approve the proposal for the oracle to be deployed. He confirms the taker, the bug information on the IPFS and pays the fees before the oracle is ready to be released.

#### The credit Mechanism
The vending machine also implements a mechanism for credit, that checks a specif holders balance of SOLID tokens and saves it the vending machine. This is a temporary approach for giving the SOLID holders the right to use while the tokens are in the lockup period(6 months after the sale) as well it will serve as a trial period, as no tokens will be actually spent.

### Roadmap
This is the first iteration and there're some planned modifications in the system:

1) Switch from the credit system to a token based payment, which is intended to be released after the lockup period expired

2) Updating the oracle to a more refined version, since the current version is centralized. The proxy mechanism will allow us to experiment with different oracles approach, including the one that rely on a jury.  
