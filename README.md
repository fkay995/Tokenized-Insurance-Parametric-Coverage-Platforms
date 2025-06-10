# Tokenized Insurance Parametric Coverage Platform

A decentralized parametric insurance platform built on Stacks blockchain using Clarity smart contracts.

## Overview

This platform provides automated parametric insurance coverage through smart contracts, eliminating the need for traditional claims processing. Insurance payouts are triggered automatically based on predefined parameters and verified data sources.

## Architecture

### Core Contracts

1. **Insurance Provider Verification** (`insurance-provider.clar`)
    - Validates and manages insurance providers
    - Handles provider registration and verification
    - Manages provider reputation and staking

2. **Data Source Contract** (`data-source.clar`)
    - Manages parametric data sources (weather, earthquake, etc.)
    - Validates data feed authenticity
    - Handles oracle integration

3. **Trigger Monitoring Contract** (`trigger-monitoring.clar`)
    - Monitors parametric triggers
    - Evaluates trigger conditions
    - Initiates payout processes

4. **Payout Automation Contract** (`payout-automation.clar`)
    - Automates parametric payouts
    - Calculates payout amounts
    - Distributes funds to policyholders

5. **Risk Pooling Contract** (`risk-pooling.clar`)
    - Pools parametric insurance risks
    - Manages premium collection
    - Handles risk distribution

## Features

- **Automated Payouts**: No manual claims processing required
- **Transparent Operations**: All operations recorded on blockchain
- **Risk Distribution**: Efficient risk pooling mechanisms
- **Provider Verification**: Ensures only verified providers participate
- **Data Integrity**: Secure and verified data sources

## Getting Started

### Prerequisites

- Stacks CLI
- Clarinet (for local development)
- Node.js (for testing utilities)

### Installation

\`\`\`bash
git clone <repository-url>
cd parametric-insurance
npm install
\`\`\`

### Testing

\`\`\`bash
npm test
\`\`\`

### Deployment

\`\`\`bash
clarinet deploy
\`\`\`

## Contract Interactions

### Register as Insurance Provider

\`\`\`clarity
(contract-call? .insurance-provider register-provider "Provider Name" u1000000)
\`\`\`

### Create Insurance Policy

\`\`\`clarity
(contract-call? .risk-pooling create-policy u100 u1000 "earthquake" u7)
\`\`\`

### Add Data Source

\`\`\`clarity
(contract-call? .data-source add-source "weather-api" "https://api.weather.com")
\`\`\`

## Security Considerations

- All contracts include proper access controls
- Data sources are verified before use
- Provider staking ensures accountability
- Multi-signature requirements for critical operations

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

MIT License - see LICENSE file for details
