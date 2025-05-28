# Main script for video game industry data collection
# Author: [Your Name]
# Date: [Current Date]

# Load configuration
if (file.exists("config.R")) {
  source("config.R")
  setup_environment()
} else {
  warning("config.R not found. Please create it with your API keys.")
}

# Load required packages
required_packages <- c(
  "httr",
  "jsonlite",
  "dplyr",
  "tidyr",
  "ggplot2",
  "rvest",
  "xml2"
)

# Function to check and install missing packages
install_missing_packages <- function(packages) {
  new_packages <- packages[!(packages %in% installed.packages()[,"Package"])]
  if(length(new_packages)) install.packages(new_packages)
  lapply(packages, library, character.only = TRUE)
}

# Install and load required packages
install_missing_packages(required_packages)

# Create necessary directories if they don't exist
dirs <- c("data", "data/raw", "data/processed", "analysis")
sapply(dirs, function(dir) if(!dir.exists(dir)) dir.create(dir, recursive = TRUE))

# Source platform-specific scripts
source("src/steam/steam_collector.R")

# Function to collect data from all platforms
collect_all_data <- function() {
  # Start with Steam data collection
  message("Collecting Steam data...")
  steam_data <- collect_steam_data()
  
  # TODO: Implement other platform collectors
  # epic_data <- collect_epic_data()
  # nintendo_data <- collect_nintendo_data()
  # xbox_data <- collect_xbox_data()
  # playstation_data <- collect_playstation_data()
  
  # Combine all data
  all_data <- steam_data  # For now, just use Steam data
  
  # Save combined data
  if (!is.null(all_data)) {
    timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
    write.csv(all_data, 
              file = paste0("data/processed/combined_data_", timestamp, ".csv"),
              row.names = FALSE)
    message("Data saved to data/processed/combined_data_", timestamp, ".csv")
  }
}

# Main execution
if (interactive()) {
  message("Starting data collection...")
  collect_all_data()
  message("Data collection complete!")
} else {
  # If running from command line
  collect_all_data()
} 