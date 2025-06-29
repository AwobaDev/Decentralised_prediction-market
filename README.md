# Decentralized Prediction Market

A comprehensive prediction market smart contract built on the Stacks blockchain using Clarity. This contract enables users to create prediction markets, trade on outcomes, provide liquidity, and resolve markets through a decentralized oracle system.

## 🌟 Features

### 📊 **Market Creation**
- **Multi-outcome Markets**: Support for up to 10 different outcomes per market
- **Flexible Parameters**: Customizable fees, minimum trade amounts, and resolution times
- **Category System**: Organize markets by categories (crypto, sports, politics, etc.)
- **Oracle Integration**: Each market requires a designated oracle for resolution

### 💰 **Trading System**
- **AMM-Style Pricing**: Automated Market Maker with dynamic pricing based on liquidity
- **Buy/Sell Shares**: Trade on any outcome with real-time price discovery
- **Minimum Trade Amounts**: Configurable minimum trade sizes per market
- **Position Tracking**: Track user positions across multiple outcomes

### 🌊 **Liquidity Provision**
- **Add Liquidity**: Provide liquidity to earn fees from trading
- **Proportional Shares**: Liquidity providers receive shares proportional to their contribution
- **Remove Liquidity**: Exit liquidity positions after market resolution

### ⚖️ **Oracle & Resolution System**
- **Multi-Oracle Support**: Support for multiple trusted oracles
- **Reputation System**: Oracle reputation tracking (0-100%)
- **Dispute Mechanism**: Users can dispute oracle resolutions with stake
- **Time-Locked Resolution**: Dispute period before final settlement

### 🏛️ **Governance**
- **Owner Controls**: Contract owner can manage oracles and system parameters
- **Fee Management**: Adjustable protocol fees and oracle fees
- **Parameter Updates**: Modify dispute periods, minimum stakes, etc.

## 🏗️ Architecture

### Core Data Structures

#### Markets
```clarity
{
  creator: principal,
  description: (string-utf8 500),
  category: (string-ascii 50),
  outcomes: (list 10 (string-utf8 100)),
  resolution-time: uint,
  closing-time: uint,
  fee-percentage: uint,
  oracle: principal,
  oracle-fee: uint,
  min-trade-amount: uint,
  status: (string-ascii 20), // "active", "closed", "resolved", "disputed", "finalized"
  resolved-outcome: (optional uint),
  total-liquidity: uint,
  outcome-reserves: (list 10 uint),
  dispute-deadline: (optional uint)
}
```

#### User Positions
```clarity
{
  market-id: uint,
  user: principal,
  outcome: uint,
  shares: uint,
  claimed: bool
}
```

#### Liquidity Positions
```clarity
{
  market-id: uint,
  provider: principal,
  shares: uint,
  share-percentage: uint
}
```

## 🚀 Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet for testing

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Decentralised_prediction-market
   ```

2. **Check contract syntax**
   ```bash
   clarinet check
   ```

3. **Run tests**
   ```bash
   clarinet test
   ```

4. **Deploy to devnet**
   ```bash
   clarinet integrate
   ```

## 📖 Usage Guide

### 1. Initialize Contract

The contract must be initialized by the owner with a list of trusted oracles:

```clarity
(contract-call? .prediction-market initialize 
  (list 'SP1ABC... 'SP2DEF... 'SP3GHI...))
```

### 2. Create a Market

Anyone can create a prediction market:

```clarity
(contract-call? .prediction-market create-market
  u"Will BTC exceed $100k by end of 2025?"  ;; description
  "crypto"                                  ;; category
  (list u"Yes" u"No")                      ;; outcomes
  u1000                                    ;; resolution-time (block height)
  u900                                     ;; closing-time (block height)
  u250                                     ;; fee-percentage (2.5%)
  'SP1ORACLE...                           ;; oracle
  u10000000                               ;; oracle-fee (10 STX)
  u1000000                                ;; min-trade-amount (1 STX)
  (some u"Additional market details"))     ;; additional-data
```

### 3. Add Liquidity

Provide liquidity to earn trading fees:

```clarity
(contract-call? .prediction-market add-liquidity 
  u1           ;; market-id
  u50000000)   ;; amount (50 STX)
```

### 4. Trade Shares

Buy shares in a specific outcome:

```clarity
(contract-call? .prediction-market buy-shares
  u1           ;; market-id
  u0           ;; outcome-id (0 = "Yes")
  u10000000)   ;; amount (10 STX)
```

Sell shares:

```clarity
(contract-call? .prediction-market sell-shares
  u1           ;; market-id
  u0           ;; outcome-id
  u5000000)    ;; shares to sell
```

### 5. Resolve Market

Oracle resolves the market after closing:

```clarity
(contract-call? .prediction-market resolve-market
  u1  ;; market-id
  u1) ;; winning-outcome-id
```

### 6. Dispute Resolution

Users can dispute within the dispute period:

```clarity
(contract-call? .prediction-market dispute-resolution
  u1           ;; market-id
  u0           ;; proposed-outcome-id
  u2000000)    ;; stake-amount (2 STX)
```

### 7. Finalize & Claim

After dispute period, anyone can finalize:

```clarity
(contract-call? .prediction-market finalize-market u1)
```

Winners claim their payouts:

```clarity
(contract-call? .prediction-market claim-winnings u1)
```

## 🧪 Testing

The contract includes comprehensive tests covering:

- ✅ Contract initialization and ownership
- ✅ Market creation with various parameters
- ✅ Liquidity provision and management
- ✅ Trading functionality (buy/sell shares)
- ✅ Oracle resolution and dispute system
- ✅ Market finalization and claims
- ✅ Governance and access control
- ✅ Error handling and edge cases

Run the full test suite:

```bash
clarinet test
```

For continuous testing during development:

```bash
clarinet test --watch
```

## ⚙️ Configuration

### Default Parameters

| Parameter | Default Value | Description |
|-----------|---------------|-------------|
| Protocol Fee | 1% (100 basis points) | Fee charged on trades |
| Min Dispute Stake | 1 STX | Minimum stake to dispute resolution |
| Dispute Period | 144 blocks (~24 hours) | Time window for disputes |
| Max Fee Percentage | 10% (1000 basis points) | Maximum market fee allowed |

### Error Codes

| Code | Error | Description |
|------|-------|-------------|
| u100 | err-owner-only | Only contract owner can call this function |
| u101 | err-not-found | Resource not found |
| u102 | err-unauthorized | Caller not authorized |
| u103 | err-invalid-params | Invalid parameters provided |
| u104 | err-insufficient-funds | Insufficient balance |
| u105 | err-market-closed | Market is closed for trading |
| u106 | err-market-not-resolved | Market not yet resolved |
| u107 | err-market-already-resolved | Market already resolved |
| u108 | err-dispute-period-active | Dispute period still active |
| u109 | err-dispute-period-expired | Dispute period has expired |
| u110 | err-already-claimed | Winnings already claimed |
| u111 | err-no-winnings | No winnings to claim |
| u112 | err-market-not-finalized | Market not finalized |

## 🔒 Security Considerations

### Access Control
- **Owner Functions**: Critical functions protected by owner-only modifier
- **Oracle Authorization**: Only authorized oracles can resolve markets
- **Balance Checks**: All transfers validated against user balances

### Economic Security
- **Dispute Stakes**: Minimum stake required to prevent spam disputes
- **Time Locks**: Dispute periods prevent immediate finalization
- **Fee Caps**: Maximum fees prevent exploitation

### Data Validation
- **Input Sanitization**: All user inputs validated
- **Range Checks**: Numeric parameters within acceptable ranges
- **State Validation**: Market state transitions properly controlled

## 🛣️ Roadmap

### Phase 1: Core Functionality ✅
- [x] Basic market creation and trading
- [x] Liquidity provision system
- [x] Oracle resolution mechanism
- [x] Dispute system

### Phase 2: Advanced Features (Future)
- [ ] Market categories and filtering
- [ ] Advanced AMM curves
- [ ] Cross-market arbitrage prevention
- [ ] Enhanced oracle aggregation

### Phase 3: Governance (Future)
- [ ] Decentralized governance token
- [ ] Community-driven parameter updates
- [ ] Oracle reputation voting
- [ ] Fee sharing mechanisms

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

For questions, issues, or contributions:
- Create an issue on GitHub
- Join our Discord community
- Follow us on Twitter

---

**Built with ❤️ on Stacks**
