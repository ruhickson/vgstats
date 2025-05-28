# Video Game Industry Data Collection

This project collects and analyzes data from various video game platforms including:
- Steam
- Epic Games Store
- Nintendo Store
- Xbox Store
- PlayStation Store

## Setup

1. Install R (version 4.0.0 or higher)
2. Install required R packages:
```R
install.packages(c(
  "httr",
  "jsonlite",
  "dplyr",
  "tidyr",
  "ggplot2",
  "rvest",
  "xml2"
))
```

## Project Structure

- `src/` - R source files
  - `steam/` - Steam API integration
  - `epic/` - Epic Games Store integration
  - `nintendo/` - Nintendo Store integration
  - `xbox/` - Xbox Store integration
  - `playstation/` - PlayStation Store integration
- `data/` - Collected data storage
- `analysis/` - Analysis scripts and visualizations

## Data Collection

Each platform has its own data collection script that handles:
- API authentication (where required)
- Data fetching
- Data cleaning and standardization
- Storage in a common format

## Usage

Run the main script to collect data from all platforms:
```R
Rscript src/main.R
```

## Notes

- Some platforms require API keys or authentication
- Rate limits may apply to certain APIs
- Data collection frequency should be adjusted based on platform policies 