// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @title KipuBank
 */
contract KipuBank {
    // ============ IMMUTABLES ============
    /// @notice Maximum allowed withdrawal per request
    uint256 public immutable maxWithdrawalAmount;

    /// @notice Maximum total ETH the contract may hold
    uint256 public immutable bankCap;

    /// @notice Owner of the contract (deployer)
    address public immutable owner;

    // ============ STORAGE ============
    /// @notice User balances
    mapping(address => uint256) private balances;

    /// @notice Pending withdrawals (pull pattern)
    mapping(address => uint256) private pendingWithdrawals;

    /// @notice Number of deposits performed by each user
    mapping(address => uint256) public depositCount;

    /// @notice Number of withdrawals (requested) performed by each user
    mapping(address => uint256) public withdrawalCount;

    /// @notice Total number of deposit operations performed on the contract
    uint256 public totalDepositOps;

    /// @notice Total number of withdrawal operations requested on the contract
    uint256 public totalWithdrawalOps;

    /// @notice List of users that have deposited (may contain duplicates if desired)
    address[] private userAddresses;

    // ============ REENTRANCY GUARD ============
    bool private reentrancyLock;

    // ============ EVENTS ============
    /// @notice Emitted when a deposit is made
    /// @param user The depositor
    /// @param amount The amount deposited
    event Deposit(address indexed user, uint256 amount);

    /// @notice Emitted when a withdrawal is requested (pull)
    /// @param user The requester
    /// @param amount The amount requested
    event WithdrawalRequested(address indexed user, uint256 amount);

    /// @notice Emitted when a pending withdrawal is completed
    /// @param user The recipient
    /// @param amount The amount transferred
    event WithdrawalCompleted(address indexed user, uint256 amount);

    /// @notice Emitted when bank cap is reached or exceeded
    /// @param currentBalance Current contract balance
    /// @param cap The bank cap
    event BankCapReached(uint256 currentBalance, uint256 cap);

    // ============ ERRORS (CUSTOM) ============
    /// @notice Zero amount is not allowed
    error ZeroAmount();

    /// @notice The attempted action would exceed the bank cap
    /// @param attempted The balance that would result
    /// @param cap The configured cap
    error ExceedsBankCap(uint256 attempted, uint256 cap);

    /// @notice Requested amount exceeds maximum per-withdrawal limit
    /// @param requested Amount requested
    /// @param maxAllowed Max allowed amount
    error ExceedsMaxWithdrawal(uint256 requested, uint256 maxAllowed);

    /// @notice Caller has insufficient balance for the requested action
    /// @param requested The requested amount
    /// @param available The caller's available amount
    error InsufficientBalance(uint256 requested, uint256 available);

    /// @notice Only the owner may call the function
    /// @param caller The caller address
    error OnlyOwner(address caller);

    /// @notice Reentrancy attack detected
    error Reentrancy();

    /// @notice Transfer failed
    /// @param to Recipient
    /// @param amount Amount attempted
    /// @param reason Low-level call return data
    error TransferFailed(address to, uint256 amount, bytes reason);

    // ============ MODIFIERS ============
    /// @notice Only owner
    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner(msg.sender);
        _;
    }

    /// @notice Prevent reentrancy
    modifier nonReentrant() {
        if (reentrancyLock) revert Reentrancy();
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

    /// @notice Ensure amount > 0
    /// @param amount Amount to check
    modifier nonZeroAmount(uint256 amount) {
        if (amount == 0) revert ZeroAmount();
        _;
    }

    // ============ CONSTRUCTOR ============
    /**
     * @notice Deploy the bank
     * @param _maxWithdrawalAmount Maximum amount allowed per withdrawal request
     * @param _bankCap Maximum total ETH balance allowed in the bank
     */
    constructor(uint256 _maxWithdrawalAmount, uint256 _bankCap) {
        if (_maxWithdrawalAmount == 0) revert ZeroAmount();
        if (_bankCap == 0) revert ZeroAmount();

        maxWithdrawalAmount = _maxWithdrawalAmount;
        bankCap = _bankCap;
        owner = msg.sender;
    }

    // ============ DEPOSIT LOGIC ==========
    /**
     * @notice Deposit ETH into the bank
     * @dev Uses internal _handleDeposit to avoid duplicated logic with receive()
     */
    function deposit() external payable nonReentrant {
        _handleDeposit(msg.sender, msg.value);
    }

    /**
     * @notice Receive fallback to accept direct ETH transfers
     */
    receive() external payable {
        // no reentrancy modifier available on receive; call internal handler which has checks
        _handleDeposit(msg.sender, msg.value);
    }

    /**
     * @notice Internal deposit handler (private)
     * @param from Sender of the funds
     * @param amount Amount sent
     */
    function _handleDeposit(address from, uint256 amount) private nonZeroAmount(amount) {
        // CHECK: bank cap - address(this).balance already includes the incoming msg.value when called from payable entrypoints
        if (address(this).balance > bankCap) {
            emit BankCapReached(address(this).balance, bankCap);
            revert ExceedsBankCap(address(this).balance, bankCap);
        }

        // EFFECTS: minimize storage reads/writes by copying to memory
        uint256 userBalance = balances[from];
        if (userBalance == 0) {
            userAddresses.push(from);
        }

        unchecked {
            userBalance += amount; // safe because balances add up to contract balance which is bounded by bankCap
        }

        balances[from] = userBalance;

        // update counters
        depositCount[from] += 1;
        unchecked { totalDepositOps += 1; }

        emit Deposit(from, amount);
    }

    // ============ REQUEST WITHDRAWAL (PULL) ==========
    /**
     * @notice Request a withdrawal (adds to your pending withdrawals)
     * @param amount Amount to withdraw
     */
    function requestWithdrawal(uint256 amount) external nonReentrant nonZeroAmount(amount) {
        if (amount > maxWithdrawalAmount) revert ExceedsMaxWithdrawal(amount, maxWithdrawalAmount);

        // copy balance to memory to avoid multiple SLOADs
        uint256 userBalance = balances[msg.sender];
        if (amount > userBalance) revert InsufficientBalance(amount, userBalance);

        // EFFECTS: update state before interaction
        unchecked { userBalance -= amount; }
        balances[msg.sender] = userBalance;

        pendingWithdrawals[msg.sender] += amount;

        withdrawalCount[msg.sender] += 1;
        unchecked { totalWithdrawalOps += 1; }

        emit WithdrawalRequested(msg.sender, amount);
    }

    // ============ COMPLETE WITHDRAWAL ==========
    /**
     * @notice Complete your pending withdrawal (pull pattern)
     */
    function completeWithdrawal() external nonReentrant {
        uint256 amount = pendingWithdrawals[msg.sender];
        if (amount == 0) revert ZeroAmount();

        // EFFECTS: set to zero before external call
        pendingWithdrawals[msg.sender] = 0;

        // INTERACTION: perform the transfer via private helper
        _performTransfer(msg.sender, amount);

        emit WithdrawalCompleted(msg.sender, amount);
    }

    /**
     * @notice Internal ETH transfer helper
     * @dev Reverts with TransferFailed if the low-level call fails
     * @param to Recipient
     * @param amount Amount to send
     */
    function _performTransfer(address to, uint256 amount) private {
        (bool success, bytes memory data) = to.call{value: amount}("");
        if (!success) revert TransferFailed(to, amount, data);
    }

    // ============ VIEW / GETTERS ============
    /**
     * @notice Get the on-chain balance for a user
     * @param user Address to query
     * @return The balance of the user
     */
    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }

    /**
     * @notice Get pending withdrawal amount for user
     * @param user Address to query
     * @return Pending withdrawal amount
     */
    function getPendingWithdrawal(address user) external view returns (uint256) {
        return pendingWithdrawals[user];
    }

    /**
     * @notice Get the number of users that have deposited
     * @return Count of unique depositor addresses recorded
     */
    function getUserCount() external view returns (uint256) {
        return userAddresses.length;
    }

    /**
     * @notice Return aggregated bank stats
     * @return depositsOps Number of deposit operations
     * @return withdrawalOps Number of withdrawal operations
     * @return totalBalance Current contract ETH balance
     * @return users Number of recorded users
     */
    function getBankStats()
        external
        view
        returns (
            uint256 depositsOps,
            uint256 withdrawalOps,
            uint256 totalBalance,
            uint256 users
        )
    {
        depositsOps = totalDepositOps;
        withdrawalOps = totalWithdrawalOps;
        totalBalance = address(this).balance;
        users = userAddresses.length;
    }

    // ============ OWNER UTILITIES ============
    /**
     * @notice Emergency function to withdraw accidentally-sent ETH by owner
     * @param to Recipient address
     * @param amount Amount to send
     */
    function emergencyWithdraw(address to, uint256 amount) external onlyOwner nonReentrant {
        _performTransfer(to, amount);
    }
}
