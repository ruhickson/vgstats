# Steam Data Collector
# This script collects data from the Steam API

# Constants
STEAM_API_BASE_URL <- "https://api.steampowered.com"
STEAM_STORE_BASE_URL <- "https://store.steampowered.com/api"

# Function to get Steam API key from environment variable
get_steam_api_key <- function() {
  key <- Sys.getenv("STEAM_API_KEY")
  if (key == "") {
    warning("STEAM_API_KEY environment variable not set. Some API calls may be limited.")
    return(NULL)
  }
  return(key)
}

# Function to standardize game data frame
standardize_game_data <- function(games_df) {
  if (is.null(games_df) || nrow(games_df) == 0) return(NULL)
  
  # Ensure all required columns exist
  required_cols <- c("id", "name")
  if (!all(required_cols %in% names(games_df))) {
    warning("Missing required columns in game data")
    return(NULL)
  }
  
  # Select and rename columns to ensure consistency
  games_df <- games_df[, required_cols, drop = FALSE]
  names(games_df) <- c("id", "name")
  
  return(games_df)
}

# Function to get top selling games
get_top_selling_games <- function() {
  # Get featured categories
  url <- paste0(STEAM_STORE_BASE_URL, "/featuredcategories")
  
  response <- tryCatch({
    httr::GET(url)
  }, error = function(e) {
    warning("Failed to fetch top selling games: ", e$message)
    return(NULL)
  })
  
  if (is.null(response)) return(NULL)
  
  if (httr::http_type(response) != "application/json") {
    warning("API did not return JSON")
    return(NULL)
  }
  
  data <- jsonlite::fromJSON(httr::content(response, "text"))
  
  # Initialize empty data frame with correct structure
  all_games <- data.frame(
    id = integer(),
    name = character(),
    stringsAsFactors = FALSE
  )
  
  # Add top sellers
  if (!is.null(data$top_sellers$items)) {
    top_sellers <- standardize_game_data(data$top_sellers$items)
    if (!is.null(top_sellers)) {
      all_games <- rbind(all_games, top_sellers)
    }
  }
  
  # Add new releases
  if (!is.null(data$new_releases$items)) {
    new_releases <- standardize_game_data(data$new_releases$items)
    if (!is.null(new_releases)) {
      all_games <- rbind(all_games, new_releases)
    }
  }
  
  # Add specials
  if (!is.null(data$specials$items)) {
    specials <- standardize_game_data(data$specials$items)
    if (!is.null(specials)) {
      all_games <- rbind(all_games, specials)
    }
  }
  
  # Remove duplicates based on id
  all_games <- all_games[!duplicated(all_games$id), ]
  
  return(all_games)
}

# Function to get game details
get_game_details <- function(app_id) {
  url <- paste0(STEAM_STORE_BASE_URL, "/appdetails?appids=", app_id)
  
  response <- tryCatch({
    httr::GET(url)
  }, error = function(e) {
    warning("Failed to fetch game details for app_id ", app_id, ": ", e$message)
    return(NULL)
  })
  
  if (is.null(response)) return(NULL)
  
  if (httr::http_type(response) != "application/json") {
    warning("API did not return JSON")
    return(NULL)
  }
  
  data <- jsonlite::fromJSON(httr::content(response, "text"))
  return(data[[1]]$data)
}

# Function to get current player counts
get_current_players <- function(app_id) {
  url <- paste0(STEAM_API_BASE_URL, "/ISteamUserStats/GetNumberOfCurrentPlayers/v1/?appid=", app_id)
  
  response <- tryCatch({
    httr::GET(url)
  }, error = function(e) {
    warning("Failed to fetch player count for app_id ", app_id, ": ", e$message)
    return(NULL)
  })
  
  if (is.null(response)) return(NULL)
  
  if (httr::http_type(response) != "application/json") {
    warning("API did not return JSON")
    return(NULL)
  }
  
  data <- jsonlite::fromJSON(httr::content(response, "text"))
  return(data$response$player_count)
}

# Function to get game reviews
get_game_reviews <- function(app_id) {
  url <- paste0(STEAM_STORE_BASE_URL, "/appreviews/", app_id, "?json=1&filter=all&language=all&review_type=all&purchase_type=all")
  
  response <- tryCatch({
    httr::GET(url)
  }, error = function(e) {
    warning("Failed to fetch reviews for app_id ", app_id, ": ", e$message)
    return(NULL)
  })
  
  if (is.null(response)) return(NULL)
  
  if (httr::http_type(response) != "application/json") {
    warning("API did not return JSON")
    return(NULL)
  }
  
  data <- jsonlite::fromJSON(httr::content(response, "text"))
  return(data$query_summary)
}

# Main collection function
collect_steam_data <- function() {
  # Get top selling games
  top_games <- get_top_selling_games()
  if (is.null(top_games) || nrow(top_games) == 0) {
    warning("Failed to collect top selling games")
    return(NULL)
  }
  
  # Initialize data frame for results
  results <- data.frame(
    app_id = integer(),
    name = character(),
    current_players = integer(),
    price = numeric(),
    release_date = character(),
    review_score = character(),
    review_count = integer(),
    stringsAsFactors = FALSE
  )
  
  # Collect details for each game
  for (i in seq_len(nrow(top_games))) {
    app_id <- top_games$id[i]
    
    # Get game details
    details <- get_game_details(app_id)
    if (is.null(details)) next
    
    # Get current players
    players <- get_current_players(app_id)
    
    # Get reviews
    reviews <- get_game_reviews(app_id)
    
    # Add to results
    results <- rbind(results, data.frame(
      app_id = app_id,
      name = details$name,
      current_players = ifelse(is.null(players), NA, players),
      price = ifelse(is.null(details$price_overview), NA, details$price_overview$final / 100),
      release_date = ifelse(is.null(details$release_date), NA, details$release_date$date),
      review_score = ifelse(is.null(reviews), NA, reviews$review_score_desc),
      review_count = ifelse(is.null(reviews), NA, reviews$total_reviews),
      stringsAsFactors = FALSE
    ))
    
    # Be nice to the API
    Sys.sleep(1)
  }
  
  # Remove any remaining duplicates
  results <- results[!duplicated(results$app_id), ]
  
  # Save raw data
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  write.csv(results, 
            file = paste0("data/raw/steam_data_", timestamp, ".csv"),
            row.names = FALSE)
  
  return(results)
}

# Example usage:
# steam_data <- collect_steam_data() 