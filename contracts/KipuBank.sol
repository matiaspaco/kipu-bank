
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
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ============ ERRORES PERSONALIZADOS ============
    error ExceedsBankCap();
    error ExceedsMaxWithdrawal();
    error InsufficientBalance();
    error OnlyOwner();
    error ZeroAmount();
    error TransferFailed();
    error ReentrancyGuard();

    // ============ MODIFICADORES ============
    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    modifier nonReentrant() {
        if (_reentrancyLock) revert ReentrancyGuard();
        _reentrancyLock = true;
        _;
        _reentrancyLock = false;
    }

    modifier nonZeroAmount(uint256 amount) {
        if (amount == 0) revert ZeroAmount();
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
        if (msg.value == 0) revert ZeroAmount();
        
        uint256 currentTotalBalance = address(this).balance;
        if (currentTotalBalance > bankCap) {
            emit BankCapReached(currentTotalBalance, bankCap);
            revert ExceedsBankCap();
        }

        // EFFECTS: Actualizar estado interno
        if (_balances[msg.sender] == 0) {
            _userAddresses.push(msg.sender);
        }
        _balances[msg.sender] += msg.value;
        totalDeposits++;

        // INTERACTIONS: No hay interacciones externas en depósito

        emit Deposit(msg.sender, msg.value);
    }

    // ============ SOLICITAR RETIRO (PATRÓN PULL) ============
    function requestWithdrawal(uint256 amount) 
        external 
        nonReentrant 
        nonZeroAmount(amount) 
    {
        // CHECK: Verificaciones de límites y balance
        if (amount > maxWithdrawalAmount) revert ExceedsMaxWithdrawal();
        if (amount > _balances[msg.sender]) revert InsufficientBalance();

        // EFFECTS: Actualizar estado antes de interacciones
        _balances[msg.sender] -= amount;
        _pendingWithdrawals[msg.sender] += amount;
        totalWithdrawals++;

        // INTERACTIONS: No hay transferencias aquí (patrón pull)

        emit WithdrawalRequested(msg.sender, amount);
    }

    // ============ COMPLETAR RETIRO ============
    function completeWithdrawal() external nonReentrant {
        // CHECK: Verificar que hay fondos pendientes
        uint256 amount = _pendingWithdrawals[msg.sender];
        if (amount == 0) revert ZeroAmount();

        // EFFECTS: Actualizar estado antes de interacciones
        _pendingWithdrawals[msg.sender] = 0;

        // INTERACTIONS: Transferencia (último paso)
        _safeTransferETH(msg.sender, amount);

        emit WithdrawalCompleted(msg.sender, amount);
    }

    // ============ FUNCIÓN PARA TRANSFERIR OWNERSHIP ============
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAmount();
        emit OwnershipTransferred(owner, newOwner);
        
        // Note: owner es immutable, necesitaríamos redeploy para cambiar ownership
        // Esta función es placeholder para versión con owner mutable
    }

    // ============ FUNCIÓN PRIVADA PARA TRANSFERENCIAS SEGURAS ============
    function _safeTransferETH(address to, uint256 amount) private {
        if (address(this).balance < amount) revert InsufficientBalance();
        
        (bool success, ) = to.call{value: amount}("");
        if (!success) revert TransferFailed();
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

    // ============ FUNCIONES DEL OWNER ============
    function withdrawExcess(uint256 amount) external onlyOwner nonZeroAmount(amount) {
        uint256 currentBalance = address(this).balance;
        uint256 usedBalance = _calculateUsedBalance();
        uint256 excess = currentBalance - usedBalance;
        
        if (amount > excess) revert InsufficientBalance();

        _safeTransferETH(msg.sender, amount);
    }

    function _calculateUsedBalance() private view returns (uint256) {
        uint256 usedBalance = 0;
        uint256 length = _userAddresses.length;
        
        for (uint256 i = 0; i < length; ) {
            usedBalance += _balances[_userAddresses[i]];
            unchecked { ++i; }
        }
        return usedBalance;
    }

    // ============ RECEIVE PARA DEPÓSITOS DIRECTOS ============
    receive() external payable {
        // Lógica simplificada para receive
        _balances[msg.sender] += msg.value;
        totalDeposits++;
        emit Deposit(msg.sender, msg.value);
    }
}
