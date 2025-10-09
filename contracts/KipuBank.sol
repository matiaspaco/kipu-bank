// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;


contract KipuBank {
    
    // ============ VARIABLES INMUTABLES ============
    uint256 public immutable maxWithdrawalAmount;
    uint256 public immutable bankCap;
    address public immutable owner;

    // ============ VARIABLES DE ALMACENAMIENTO ============
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _pendingWithdrawals;
    uint256 public totalDeposits;
    uint256 public totalWithdrawals;
    address[] private _userAddresses;
    
    // ============ PROTECCIÓN ANTI-REENTRANCY ============
    bool private _reentrancyLock;

    // ============ EVENTOS ============
    event Deposit(address indexed user, uint256 amount);
    event WithdrawalRequested(address indexed user, uint256 amount);
    event WithdrawalCompleted(address indexed user, uint256 amount);
    event BankCapReached(uint256 currentBalance, uint256 bankCap);

    // ============ MODIFICADORES ============
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier nonReentrant() {
        require(!_reentrancyLock, "Reentrancy detected");
        _reentrancyLock = true;
        _;
        _reentrancyLock = false;
    }

    modifier nonZeroAmount(uint256 amount) {
        require(amount > 0, "Zero amount");
        _;
    }

    // ============ CONSTRUCTOR ============
    constructor(uint256 _maxWithdrawalAmount, uint256 _bankCap) {
        require(_maxWithdrawalAmount > 0, "Invalid max withdrawal");
        require(_bankCap > 0, "Invalid bank cap");
        
        maxWithdrawalAmount = _maxWithdrawalAmount;
        bankCap = _bankCap;
        owner = msg.sender;
    }

    // ============ FUNCIÓN PARA DEPOSITAR ETH ============
    function deposit() external payable {
        // CHECK: Verificaciones de seguridad
        require(msg.value > 0, "Zero amount");
        
        uint256 currentTotalBalance = address(this).balance;
        if (currentTotalBalance > bankCap) {
            emit BankCapReached(currentTotalBalance, bankCap);
            revert("Exceeds bank cap");
        }

        // EFFECTS: Actualizar estado interno
        if (_balances[msg.sender] == 0) {
            _userAddresses.push(msg.sender);
        }
        _balances[msg.sender] += msg.value;
        totalDeposits++;

        emit Deposit(msg.sender, msg.value);
    }

    // ============ SOLICITAR RETIRO (PATRÓN PULL) ============
    function requestWithdrawal(uint256 amount) 
        external 
        nonReentrant 
    {
        require(amount > 0, "Zero amount");
        require(amount <= maxWithdrawalAmount, "Exceeds max withdrawal");
        require(amount <= _balances[msg.sender], "Insufficient balance");

        // EFFECTS: Actualizar estado antes de interacciones
        _balances[msg.sender] -= amount;
        _pendingWithdrawals[msg.sender] += amount;
        totalWithdrawals++;

        emit WithdrawalRequested(msg.sender, amount);
    }

    // ============ COMPLETAR RETIRO ============
    function completeWithdrawal() external nonReentrant {
        uint256 amount = _pendingWithdrawals[msg.sender];
        require(amount > 0, "Zero amount");

        // EFFECTS: Actualizar estado antes de interacciones
        _pendingWithdrawals[msg.sender] = 0;

        // INTERACTIONS: Transferencia (último paso)
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit WithdrawalCompleted(msg.sender, amount);
    }

    // ============ FUNCIONES DE CONSULTA (VIEW) ============
    function getBalance(address user) external view returns (uint256) {
        return _balances[user];
    }

    function getPendingWithdrawal(address user) external view returns (uint256) {
        return _pendingWithdrawals[user];
    }

    function getMyBalance() external view returns (uint256) {
        return _balances[msg.sender];
    }

    function getBankStats() external view returns (
        uint256 deposits,
        uint256 withdrawals,
        uint256 totalBalance,
        uint256 userCount
    ) {
        return (
            totalDeposits,
            totalWithdrawals,
            address(this).balance,
            _userAddresses.length
        );
    }

    // ============ RECEIVE PARA DEPÓSITOS DIRECTOS ============
    receive() external payable {
        _balances[msg.sender] += msg.value;
        totalDeposits++;
        emit Deposit(msg.sender, msg.value);
    }
}
