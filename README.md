# Clarity Crowdfunding Smart Contract

A decentralized crowdfunding smart contract built on the Stacks blockchain using Clarity language.

## Features

- Create fundraising campaigns with customizable goals and durations
- Accept STX contributions from supporters
- Automatic campaign status tracking
- Secure fund withdrawal for successful campaigns
- Automated refund mechanism for unsuccessful campaigns
- Read-only functions for campaign and contribution data

## Contract Functions

### Campaign Management
- `create-campaign`: Start a new fundraising campaign
- `contribute`: Support a campaign with STX
- `withdraw`: Campaign creators can withdraw funds if goal is met
- `refund`: Contributors can claim refunds for unsuccessful campaigns

### Read-Only Functions
- `get-campaign`: Retrieve campaign details
- `get-contribution`: View specific contribution details
- `get-total-campaigns`: Get total number of campaigns created

## Error Codes

```
ERR-INVALID-GOAL (u300): Campaign goal must be greater than 0
ERR-INVALID-DURATION (u301): Campaign duration must be greater than 0
ERR-INVALID-AMOUNT (u302): Contribution amount must be greater than 0
ERR-NO-CAMPAIGN (u100): Campaign does not exist
ERR-NOT-CREATOR (u101): Only campaign creator can perform this action
ERR-ENDED (u102): Campaign has ended
ERR-NOT-ENDED (u103): Campaign has not ended yet
ERR-GOAL-NOT-MET (u104): Campaign did not reach its goal
ERR-ALREADY-REFUNDED (u105): Contribution already refunded
```

## Development

```bash
# Clone the repository
git clone https://github.com/yourusername/clarity-crowdfunding

# Run tests
clarinet test

# Deploy contract
clarinet deploy
```
