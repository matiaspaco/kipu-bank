🏦 KipuBank — Smart Contract Bank
📖 Contract Overview

KipuBank is a smart contract that models a secure ETH bank with configurable limits and pull-style withdrawals.
The implementation follows the patterns and constraints required:


Solidity 0.8.26 (custom errors available)

Check → Effects → Interaction

Pull-over-push withdrawal pattern

Reentrancy guard

Custom errors (no plain require strings)

NatSpec for public API (in the contract source)

🎯 Core Features

deposit() (payable) — deposit ETH into your account.

receive() — accept direct ETH transfers; routed to the same internal handler.

requestWithdrawal(amount) — request a withdrawal (adds to pendingWithdrawals, subject to maxWithdrawalAmount).

completeWithdrawal() — complete the pending withdrawal; transfers ETH using call.

Per-user counters: depositCount[address] and withdrawalCount[address].

Global counters: totalDepositOps and totalWithdrawalOps.

bankCap — a maximum total ETH the contract is allowed to hold.

maxWithdrawalAmount — maximum allowed per withdrawal request.

nonReentrant modifier + private transfer helper _performTransfer.

emergencyWithdraw(to, amount) — owner-only emergency transfer.

Events for deposits, withdrawal requests, completed withdrawals and when bank cap is reached.

All sensitive checks use custom errors to save gas and follow the assignment requirements.

📌 Public View / Interaction API (short)

deposit() payable

receive() payable (send ETH to contract address)

requestWithdrawal(uint256 amount)

completeWithdrawal()

getBalance(address user) -> uint256

getPendingWithdrawal(address user) -> uint256

getUserCount() -> uint256

getBankStats() -> (depositsOps, withdrawalOps, totalBalance, users)

depositCount(address) -> uint256

withdrawalCount(address) -> uint256

emergencyWithdraw(address to, uint256 amount) — owner-only

🔒 Security Notes

Uses nonReentrant guard and Check–Effects–Interactions.

Uses a private transfer helper _performTransfer that reverts with custom error TransferFailed if call fails.

Minimizes storage accesses by copying state to memory first (e.g. uint256 userBalance = balances[from];), then writing once.

Custom errors (cheaper than revert strings) are used for all failure conditions.

🚀 Deployment (Remix)
Prerequisites

MetaMask (or other injected provider) connected to target network (e.g., Sepolia)

ETH on the chosen testnet

Remix IDE: https://remix.ethereum.org

Recommended compile settings in Remix

Open Solidity compiler plugin.

Select compiler 0.8.26 (must match the pragma in the contract).

In Advanced Configuration set EVM version to Default (or a supported name like london/berlin), avoid empty/invalid entries.

Auto compile optional. Click Compile KipuBank.sol.

Make sure the contract top of file has:

// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

Constructor parameters

constructor(uint256 _maxWithdrawalAmount, uint256 _bankCap)

Both values are in wei. Convert ether → wei before deploying.

Example values:

_maxWithdrawalAmount = 50000000000000000 (0.05 ETH)

_bankCap = 1000000000000000000 (1 ETH)

You can convert ETH to wei in JavaScript console or simply type 0.05 ether in scripts; in Remix constructor input you must paste the numeric wei value.

Deploy (Remix UI)

Go to Deploy & Run Transactions plugin.

Environment: Injected Provider - MetaMask (or other).

Select contract: KipuBank.

Fill constructor arguments (wei numeric values).

Click Deploy, confirm transaction in MetaMask.

✅ How to interact (Remix UI examples)
Deposit (using function)

In Deployed Contracts locate KipuBank.

In VALUE field enter amount (e.g., 0.05 ether → Remix will convert), or enter the raw wei.

Click deposit(), confirm in wallet.

Deposit (direct transfer / receive)

In Remix Deploy & Run Transactions -> At Address or use Send Transaction to contract address.

Paste contract address in At Address field and press At Address to load the instance.

Use the VALUE field and click the contract's receive() by simply sending ETH to the contract address (Remix does this when you call a payable fallback/receive).

Request withdrawal (pull pattern)

Call requestWithdrawal with the amount in wei (e.g., 50000000000000000 for 0.05 ETH).

This moves that amount to pendingWithdrawals[msg.sender] and decreases your balances[msg.sender] accordingly.

Complete withdrawal

Call completeWithdrawal(). The contract will perform the transfer using a low-level call and revert with TransferFailed on failure.

Check balances & pending

getBalance(address) — returns your stored balance.

getPendingWithdrawal(address) — returns your pending withdrawal amount.

Admin / Owner action

emergencyWithdraw(address to, uint256 amount) — only owner (deployer) can call this.

🔍 Verifying the contract on Etherscan

After deployment, copy the contract address.

Go to the appropriate block explorer (e.g., Sepolia Etherscan).

Click Verify and Publish Contract.

Choose the correct compiler 0.8.26 and license MIT.

Paste the full source code exactly as compiled. Ensure any optimization settings match the compilation you used in Remix.

Provide constructor arguments in the format requested by Etherscan (usually plain ABI-encoded hex or the input values depending on the UI). If you compiled in Remix with default settings, choose matching settings in the verification form.


📝 Notes & Hints

All numeric examples in this README are in wei unless using explicit ether unit (as supported by Remix).

depositCount and withdrawalCount are available as public mappings for per-user operation counts.

getBankStats() returns (totalDepositOps, totalWithdrawalOps, address(this).balance, userCount).

The contract uses custom errors; if you try to compile with an older compiler it will fail. Use 0.8.26.
