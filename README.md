# Saverville

## Overview
Saverville is a decentralized game based on blockchain technology that simulates farming activities using a financial model akin to certificates of deposit (CDs). Players, known as "Farmers," manage virtual farms, growing crops that represent financial investments with defined maturity periods.

## Game Mechanics
- **Purchasing Seeds**: Farmers buy seeds from the Market.
- **Planting Seeds**: Farmers plant their seeds on various plots within their farm.
- **Growth Period**: Seeds mature over time, with a random variance in growth duration.
- **Harvesting**: Harvested plants represent the maturity of the CDs, yielding the initial investment plus interest.
- **Selling Crops**: Farmers can sell their harvested crops at the Market.
- **Withdrawing Funds**: Funds can be withdrawn, similar to withdrawing from a savings account.

## Smart Contracts

### 1. `Market`
Handles all transactions related to buying seeds and selling crops.

#### Methods
- **buySeeds(uint seedType, uint quantity, address farmAddress)**
  - Farmers purchase seeds, which are sent to their specified farm address.
- **sellCrops(uint plotId, uint amount)**
  - Farmers sell crops from a specific plot for in-game currency.

### 2. `Farm`
Manages the individual farmer's entire farming operation, containing multiple farm plots.

#### Variables
- `address owner` - Owner of the farm.
- `FarmPlot[] plots` - Array of plots within the farm.

#### Methods
- **addPlot()**
  - Adds a new plot to the farm.
- **plantSeeds(uint plotId, uint[] seedTypes)**
  - Plants seeds in a specified plot within the farm.
- **harvestCrops(uint plotId)**
  - Harvests mature crops from a specified plot.

### 3. `FarmPlot`
Tracks the seeds planted in each plot and their maturity.

#### Variables
- `uint[] seeds` - Seeds planted in this plot.
- `uint plantingDate` - Date when seeds were planted.

#### Methods
- **plant(uint seedType)**
  - Plants a seed in the plot.
- **harvest()**
  - Harvests all mature crops in the plot.

### Inheritance and Interfaces

- **ERC721 (NFT)**: Used in `Farm` to represent ownership of a farm.
- **ERC20 (Fungible Token)**: Used for transactions within the Market.

### Events

- **SeedPurchased**
  - `address buyer, uint seedType, uint quantity`
- **SeedPlanted**
  - `address farmAddress, uint plotId, uint seedType`
- **CropHarvested**
  - `address farmAddress, uint plotId, uint amount`
- **CropsSold**
  - `address seller, uint amountReceived`