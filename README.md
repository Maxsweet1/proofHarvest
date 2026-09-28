ProofHarvest is an agricultural escrow project exploring how smart contracts can support milestone-based payments between buyers and agricultural suppliers.

The project grew from a real-world problem: reducing payment risk in cross-border agricultural transactions while creating a transparent record of when agreed milestones have been completed.

This repository contains two Solidity escrow implementations and an interactive frontend workflow prototype.

## Live Demo
Try the interactive ProofHarvest workflow prototype:

**[Launch ProofHarvest Demo](https://maxsweet1.github.io/proofharvest-demo/)**

The demo simulates the proposed agricultural escrow workflow, including buyer and seller roles, milestone requests, approvals, and percentage-based payment releases.

> **Note:** The demo is a frontend workflow prototype. It does not currently submit transactions to the Solidity contracts in this repository.


## Project Structure

```text
proofHarvest/
├── src/
│   ├── SimpleEscrow.sol
│   └── GulupaEscrow.sol
├── demo/
│   └── index.html
├── LICENSE
└── README.md
```

## SimpleEscrow

`SimpleEscrow.sol` implements the basic escrow model.

The contract supports:

- ERC-20 based escrow funding
- Multiple escrow agreements
- Farmer and depositor roles
- Configurable milestones
- Milestone percentage validation
- Owner-controlled milestone completion
- Release of escrowed funds after all milestones are completed
- Refund functionality
- Events for important state changes
- Read functions for escrow and milestone status

This contract represents the simpler version of the ProofHarvest escrow concept.

## GulupaEscrow

`GulupaEscrow.sol` extends the milestone model with incremental payments and oracle validation.

The contract supports:

- USDC-based escrow funding
- Multiple agricultural agreements
- Configurable payment milestones
- Percentage-based milestone releases
- Owner-controlled payment authorization
- Chainlink oracle integration
- Oracle freshness checks
- Incomplete/stale round validation
- Optional minimum oracle value
- Configurable oracle settings

Unlike `SimpleEscrow`, GulupaEscrow releases a portion of the escrowed payment when each milestone is approved.

For example, a $1,000 agreement could define:

| Milestone | Payment |
| --- | ---: |
| Harvest Confirmation | 30% |
| Shipment Sent | 40% |
| Delivery Verified | 30% |

Each successful milestone release transfers the corresponding portion of the escrowed USDC to the farmer.

## Chainlink Oracle Gate

Before `GulupaEscrow` releases a milestone payment, the contract validates data returned by the configured Chainlink price feed.

The contract checks:

- The oracle answer is positive
- The oracle round has been completed
- The returned round is valid
- The data has not exceeded the configured stale-time limit
- An optional minimum oracle value has been satisfied

If an oracle check fails, the milestone payment transaction reverts.

This provides an example of using external oracle data as a condition for smart-contract execution.

## ProofHarvest Workflow Demo

The `/demo` directory contains an interactive frontend prototype showing a broader agricultural escrow workflow.

The demo explores concepts including:

- Buyer and seller roles
- Agricultural agreements
- Milestone creation
- Seller milestone requests
- Buyer approval and rejection
- Percentage-based payments
- Progress tracking
- USDC-denominated escrow balances

### Important

The frontend is currently a **workflow prototype**.

It simulates the proposed buyer/seller interaction in the browser and does not currently connect to a wallet or submit transactions to the Solidity contracts.

The Solidity contracts in `/src` are separate implementations of the underlying escrow concepts.

## Why I Built It

ProofHarvest was inspired by the practical problems involved in purchasing and processing agricultural products across borders.

Traditional payment methods often require one party to accept significant risk:

- Buyers may have to pay before work is completed.
- Suppliers may have to perform work before receiving payment.
- International payments add additional cost and friction.
- Verification of progress can happen outside the payment system.

Milestone escrow provides another model:

1. Funds are committed to an escrow.
2. The parties agree on measurable milestones.
3. Progress is verified.
4. Payment is released according to the agreement.

ProofHarvest explores how Solidity, stablecoins, and external verification mechanisms can support that workflow.

## Technology

- Solidity ^0.8.20
- OpenZeppelin Contracts
- ERC-20 / USDC
- Chainlink price feeds
- EVM-compatible networks
- HTML / JavaScript frontend prototype

## Current Status

ProofHarvest is an active portfolio and development project.

Currently implemented:

- Basic ERC-20 escrow contract
- Configurable milestone tracking
- Percentage-based milestone payments
- USDC payment logic
- Chainlink oracle validation
- Interactive agricultural escrow workflow prototype

Future development may include additional Foundry testing, expanded verification mechanisms, stronger role separation, deployment tooling, and tighter integration between the frontend and smart contracts.

## Security

The contracts should be treated as development and portfolio code rather than audited production software.

Before production use, the contracts would require comprehensive testing, security review, deployment validation, and an independent professional audit.

## License

MIT License
