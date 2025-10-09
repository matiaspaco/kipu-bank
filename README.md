
# 🏦 KipuBank - Contrato Inteligente Bancario

## 📖 Descripción del Contrato

### ¿Qué es KipuBank?
KipuBank es un contrato inteligente descentralizado que funciona como un banco seguro para Ethereum, permitiendo a los usuarios **depositar y retirar ETH** con múltiples capas de seguridad y límites configurables.

### 🎯 Funcionalidades Principales
- **💰 Depósitos Seguros**: Los usuarios pueden depositar ETH en bóvedas personales
- **🎫 Retiros con Límite**: Sistema de retiro en dos pasos (solicitar + completar) con límite máximo por transacción
- **🛡️ Seguridad Avanzada**: 
  - Patrón **Pull-over-Push** para prevenir ataques de reentrancia
  - **Checks-Effects-Interactions** en todas las funciones
  - Límite global de depósitos (`bankCap`) para proteger fondos
- **📊 Transparencia Total**: 
  - Eventos emitidos para todas las operaciones
  - Funciones de consulta para ver balances y estadísticas
  - Código 100% verificable en block explorer

---

## 🚀 Instrucciones de Despliegue

### Prerrequisitos
- **📱 MetaMask** instalado y configurado
- **💸 ETH de testnet** (para Sepolia puedes usar [Sepolia Faucet](https://sepoliafaucet.com/))
- **🌐 Remix IDE** ([remix.ethereum.org](https://remix.ethereum.org/))

### Pasos para Desplegar

#### 1. Preparar el Entorno
```bash
# Conectar MetaMask a Sepolia Testnet
1. Abre MetaMask
2. Selecciona "Sepolia Test Network" 
3. Asegúrate de tener ETH de testnet


#### 2. Preparar el Entorno
1. Ve a https://remix.ethereum.org/
2. Crea un nuevo archivo: KipuBank.sol
3. Pega el código del contrato
4. Compila (Solidity Compiler → Compile KipuBank.sol)
5. Ve a "Deploy & Run Transactions"
6. Configura:
//    - Environment: Injected Provider - MetaMask
//    - Contract: KipuBank
//    - Constructor Parameters:
//      * _maxWithdrawalAmount: 1000000000000000
//      * _bankCap: 10000000000000000
7. Haz clic en "Transact"
8. Confirma en MetaMask


#### 2. Verificar en Etherscan
# 1. Copia la dirección del contrato desplegado
# 2. Ve a https://sepolia.etherscan.io/
# 3. Pega la dirección y busca
# 4. Haz clic en "Verify and Publish"
# 5. Completa el formulario con:
#    - Compiler: 0.8.0+
#    - License: MIT
#    - Code: Pega el código completo y el siguiente bytecode de los parametros (_maxWithdrawalAmount y _bankCap): 0x00000000000000000000000000000000000000000000000000038d7ea4c68000000000000000000000000000000000000000000000000000002386f26fc10000



DEPOSITO:
// En "Deployed Contracts" → KipuBank
// 1. En "VALUE" ingresa: 100000000000000000 (0.1 ETH en wei)
// 2. Haz clic en "deposit"
// 3. Confirma en MetaMask

CONSULTA BALANCE:
// 1. Haz clic en "getMyBalance"
// 2. Verás tu balance actual en wei

SOLICITAR RETIRO:
// 1. En "requestWithdrawal" ingresa: 50000000000000000 (0.05 ETH)
// 2. Haz clic en "requestWithdrawal"
// 3. Confirma en MetaMask
// 📝 Los fondos ahora están "pendientes"

COMPLETAR RETIRO:

// 1. Haz clic en "completeWithdrawal"
// 2. Confirma en MetaMask
// ✅ Los fondos pendientes se transferirán a tu wallet

VER INFORMACION DEL BANCO:
// 1. Haz clic en "getBankStats"
// 2. Verás: [depósitos totales, retiros totales, balance total, usuarios]
