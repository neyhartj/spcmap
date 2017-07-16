#' Summarize a spcmap object
#'
#' @param x An object of class \code{spcmap}.
#'
#' @export
#'
summary.spcmap <- function(x) {

  # Extract the data
  data <- x$data

  # Extract the risk classes
  risks <- as.factor(data$risk)
  # Alphabetize the levels
  levels(risks) <- c(setdiff(levels(risks), "None"), "None")

  # If the risk level is only "None" print
  if (all(levels(risks) == "None")) {
    cat("Phew! No severe wether is anticipated for the coordinates.\n")

  } else {
    cat("Danger Will Robinson! There is severe weather anticipated for the coordinates.\n")

    # Iterate over the risk levels
    for (risk_level in levels(risks)) {

      # Count the number of points within that risks
      n_in_risk <- sum(data$risk == risk_level)

      # Print
      cat("\nThere are", n_in_risk, "points in the", risk_level, "risk category.")

    }

    cat("\n")

  } # Close the if function

} # Close the function


#' Print a spcmap object
#'
#' @rdname summary.spcmap
#'
#' @export
#'
print.spcmap <- function(x) summary(x)



#' Plot a spcmap object
#'
#' @param x An object of class \code{spcmap}.
#' @param method The plotting method. Can be \code{"ggplot2"} for \code{ggplot2}-based
#' plots.
#'
#' @import ggplot2
#' @import maps
#'
#' @export
#'
plot.spcmap <- function(x, method = c("ggplot2")) {

  # Require the maps library to access the databases
  require(maps, quietly = TRUE, warn.conflicts = FALSE)

  # Match the method argument
  method <- match.arg(method)

  # Extract the data
  data <- x$data
  spc <- x$spc

  # If spc is NULL, stop
  if (is.null(spc)) {
    stop("There is no 'spc' data available. Plotting cannot proceed.")
  }

  # Grab USA polygon data
  usa <- tidy(maps::map(database = "state", fill = TRUE, plot = FALSE))


  ## Plot
  if (method == "ggplot2") {

    gp <- ggplot(data = usa, aes(x = long, y = lat, group = group)) +
      geom_polygon(fill = "grey90", color = "white", lwd = 1.2) +
      geom_polygon(data = spc, aes(x = long, y = lat, fill = id, group = group), alpha = 0.5) +
      coord_fixed(ratio = 1.3) +
      geom_point(data = data, aes(x = long, y = lat), inherit.aes = FALSE) +
      scale_fill_discrete(name = "Category") +
      theme(
        panel.background = element_blank()
      )

    print(gp)

  }

} # Close the function
