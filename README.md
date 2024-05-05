# Saverville

## Overview
* Saverville is a decentralized application (DApp) that implements a Farmville-style game using on-chain savings mechanisms.
* Players, referred to as Farmers, engage in the game by depositing funds into the system, represented as seeds, which mature over time into plants, akin to certificates of deposit (CDs).
* Upon maturity, plants can be harvested, resulting in a payout from the Market, allowing Farmers to withdraw their initial deposit plus interest.

## Mechanics
1. **Seed Purchase and Planting**:
    * Farmers can purchase seeds from the Market.
    * Purchased seeds can be planted in the Farmer's Farm.

2. **Plant Growth and Harvesting**:
    * Seeds grow into plants over time.
    * Plants mature after a specified duration, possibly with a random variation.
    * Mature plants can be harvested by the Farmer.
    * Harvesting a plant results in a payout from the Market, representing the matured deposit plus interest.

3. **Market Operations**:
    * Farmers can sell plants to the Market.
    * The Market facilitates the payout to Farmers upon harvesting.

4. **Farm Management**:
    * Farmers can view their Farm, which includes planted seeds and matured plants.
    * Farmers can withdraw funds from their Farm.

## Protocol Components

### Smart Contract: `Saverville`

#### Structs
* `Seed`
    * `address owner`
    * `uint purchaseTimestamp`
    * `uint maturityTimestamp`
    * `uint depositAmount`
* `Plant`
    * `address owner`
    * `uint maturityTimestamp`
    * `uint depositAmount`
    * `bool harvested`

#### Variables
* `mapping(uint => Seed) seeds` - Maps seed IDs to their respective details.
* `mapping(uint => Plant) plants` - Maps plant IDs to their respective details.

#### Events
* `SeedPurchased(address buyer, uint seedId, uint depositAmount)`
* `PlantHarvested(address farmer, uint plantId, uint payoutAmount)`
* `PlantSold(address farmer, uint plantId, uint saleAmount)`
* `FundsWithdrawn(address farmer, uint amount)`

#### Methods
* `purchaseSeed(uint depositAmount)`: Allows a Farmer to purchase a seed by depositing funds.
* `plantSeed(uint seedId)`: Allows a Farmer to plant a purchased seed in their Farm.
* `harvestPlant(uint plantId)`: Allows a Farmer to harvest a matured plant, receiving a payout.
* `sellPlant(uint plantId)`: Allows a Farmer to sell a matured plant to the Market.
* `withdrawFunds()`: Allows a Farmer to withdraw funds from their Farm.

## User Interface
* Saverville should provide a user-friendly interface for Farmers to interact with the game, including:
    * Seed purchasing
    * Planting seeds
    * Harvesting plants
    * Selling plants
    * Withdrawing funds

This protocol specification outlines the core functionality and components of Saverville, enabling Farmers to engage in on-chain savings through a gamified experience.