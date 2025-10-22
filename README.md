# 🏦 KipuBank — Smart Contract Bank

## 📖 Contract Overview

KipuBank is a smart contract that models a secure ETH bank with configurable limits and pull-style withdrawals. The implementation follows the patterns and constraints required:

- **Solidity 0.8.26** (custom errors available)
- **Check → Effects → Interaction**
- **Pull-over-push** withdrawal pattern
- **Reentrancy guard**
- **Custom errors** (no plain require strings)
- **NatSpec** for public API (in the contract source)

## 🎯 Core Features

- `deposit()` (payable) — deposit ETH into your account
- `receive()` — accept direct ETH transfers; routed to the same internal handler
- `requestWithdrawal(amount)` — request a withdrawal (adds to `pendingWithdrawals`, subject to `maxWithdrawalAmount`)
- `completeWithdrawal()` — complete the pending withdrawal; transfers ETH using `call`
- **Per-user counters**: `depositCount[address]` and `withdrawalCount[address]`
- **Global counters**: `totalDepositOps` and `totalWithdrawalOps`
- `bankCap` — maximum total ETH the contract is allowed to hold
- `maxWithdrawalAmount` — maximum allowed per withdrawal request
- `nonReentrant` modifier + private transfer helper `_performTransfer`
- `emergencyWithdraw(to, amount)` — owner-only emergency transfer
- **Events** for deposits, withdrawal requests, completed withdrawals and when bank cap is reached
- All sensitive checks use **custom errors** to save gas and follow the assignment requirements

## 📌 Public View / Interaction API

- `deposit()` payable
- `receive()` payable (send ETH to contract address)
- `requestWithdrawal(uint256 amount)`
- `completeWithdrawal()`
- `getBalance(address user) → uint256`
- `getPendingWithdrawal(address user) → uint256`
- `getUserCount() → uint256`
- `getBankStats() → (depositsOps, withdrawalOps, totalBalance, users)`
- `depositCount(address) → uint256`
- `withdrawalCount(address) → uint256`
- `emergencyWithdraw(address to, uint256 amount)` — owner-only

## 🔒 Security Notes

- Uses `nonReentrant` guard and **Check–Effects–Interactions** pattern
- Uses private transfer helper `_performTransfer` that reverts with custom error `TransferFailed` if call fails
- Minimizes storage accesses by copying state to memory first
- **Custom errors** (cheaper than revert strings) used for all failure conditions

---

## 🚀 Deployment (Remix)

### Prerequisites

- **MetaMask** connected to target network (e.g., Sepolia)
- **ETH** on the chosen testnet
- **Remix IDE**: https://remix.ethereum.org

### Compilation Settings

1. Open **Solidity compiler** plugin
2. Select compiler **0.8.26**
3. Set EVM version to **Default**
4. Click **Compile KipuBank.sol**

### Constructor Parameters

```solidity
constructor(uint256 _maxWithdrawalAmount, uint256 _bankCap)
```

Both values in **wei**:

- `_maxWithdrawalAmount` = `50000000000000000` (0.05 ETH)
- `_bankCap` = `1000000000000000000` (1 ETH)

### Deployment Steps

1. Go to **Deploy & Run Transactions**
2. **Environment**: `Injected Provider - MetaMask`
3. **Select contract**: `KipuBank`
4. Fill constructor arguments (wei values)
5. Click **Deploy**, confirm transaction

---

## ✅ How to Interact

### Deposit via Function

1. Locate `KipuBank` in **Deployed Contracts**
2. Enter amount in **VALUE** field (e.g., `0.05 ether`)
3. Click `deposit()`, confirm in wallet

### Direct Transfer

1. Use **Send Transaction** to contract address
2. Enter amount in **VALUE** field
3. Contract's `receive()` function will handle the transfer

### Request Withdrawal

1. Call `requestWithdrawal` with amount in wei
2. Amount moves to `pendingWithdrawals[msg.sender]`
3. Decreases `balances[msg.sender]`

### Complete Withdrawal

1. Call `completeWithdrawal()`
2. Contract transfers ETH using low-level call
3. Reverts with `TransferFailed` on failure

### Check Balances

- `getBalance(address)` — stored balance
- `getPendingWithdrawal(address)` — pending withdrawal amount

### Admin Functions

- `emergencyWithdraw(address to, uint256 amount)` — owner only

---

## 🔍 Etherscan Verification

1. Copy contract address after deployment
2. Go to block explorer (e.g., Sepolia Etherscan)
3. Click **Verify and Publish**
4. Select compiler **0.8.26** and license **MIT**
5. Paste source code matching Remix compilation
6. Provide constructor arguments in requested format

---

## 📝 Notes

- All numeric examples in **wei** unless using `ether` unit
- `depositCount` and `withdrawalCount` available as public mappings
- `getBankStats()` returns `(totalDepositOps, totalWithdrawalOps, address(this).balance, userCount)`
- Requires Solidity **0.8.26** for custom errors
