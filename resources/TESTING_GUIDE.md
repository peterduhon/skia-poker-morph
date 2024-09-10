# Skia Poker Smart Contract Testing Guide

This document provides an overview and instructions for running the comprehensive test suite for the Skia Poker smart contracts. These tests are referenced in [SP-21] Testing Skia Poker Smart Contracts · Issue #16 · peterduhon/skia-poker-morph (github.com).

## Test Suites Overview

Our testing strategy comprises six main test suites:

1. Unit Testing
2. Integration Testing
3. State Transition Testing
4. Edge Case Testing
5. Security Testing
6. Gas Optimization Testing

### 1. Unit Testing

**Purpose**: To test individual functions and components of each smart contract in isolation.

**Key Areas**:
- GameLogic contract functions
- PlayerManagement contract functions
- RoomManagement contract functions
- Other individual contract functionalities

**Instructions**:
1. Navigate to the `test` directory.
2. Run: `npx hardhat test test/unit/`

### 2. Integration Testing

**Purpose**: To test interactions between different contracts and ensure they work together as expected.

**Key Areas**:
- Player registration and game joining flow
- Game start and progression
- Interaction between GameLogic and PlayerManagement

**Instructions**:
1. Navigate to the `test` directory.
2. Run: `npx hardhat test test/integration/`

### 3. State Transition Testing

**Purpose**: To ensure the game progresses correctly through its various states.

**Key Areas**:
- Transition from WaitingForPlayers to PreFlop
- Progression through betting rounds
- Game ending and resetting

**Instructions**:
1. Navigate to the `test` directory.
2. Run: `npx hardhat test test/state-transition/`

### 4. Edge Case Testing

**Purpose**: To test the contracts under extreme or unusual conditions.

**Key Areas**:
- Minimum and maximum player counts
- Minimum and maximum bet amounts
- All players folding except one

**Instructions**:
1. Navigate to the `test` directory.
2. Run: `npx hardhat test test/edge-cases/`

### 5. Security Testing

**Purpose**: To identify potential vulnerabilities and ensure the contracts are secure.

**Key Areas**:
- Reentrancy protection
- Access control
- Fund safety

**Instructions**:
1. Navigate to the `test` directory.
2. Run: `npx hardhat test test/security/`

### 6. Gas Optimization Testing

**Purpose**: To measure and optimize gas usage for key functions.

**Key Areas**:
- Joining a game
- Making bets
- Dealing cards
- Ending a game

**Instructions**:
1. Navigate to the `test` directory.
2. Run: `npx hardhat test test/gas-optimization/`

## Running All Tests

To run all tests in sequence:

1. Navigate to the project root directory.
2. Run: `npx hardhat test`

## Interpreting Results

- All tests should pass. Any failures indicate issues that need to be addressed.
- For gas optimization tests, compare the gas usage against the predefined thresholds. If any function exceeds its threshold, consider optimizing it.

## Continuous Integration

These tests are integrated into our CI pipeline. Any push to the main branch or pull request will trigger the test suite.

## Contributing New Tests

When adding new features or modifying existing ones, please add or update relevant tests. Follow the existing structure and naming conventions in the `test` directory.

## Troubleshooting

If you encounter any issues while running the tests:

1. Ensure all dependencies are installed (`npm install`)
2. Check that you're using the correct version of Hardhat and Solidity
3. Verify that your local environment variables are set correctly

For persistent issues, please create a new issue in the GitHub repository with a detailed description of the problem and the steps to reproduce it.
