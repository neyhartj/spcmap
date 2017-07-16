#' Compare sample coordinates with NOAA Storm Prediction Center risk maps
#'
#' @param data A \code{data.frame} with information on sample coordinates. The
#' object must have the columns \code{lat} and \code{long} and may have any
#' number of additional columns.
#' @param day The \code{integer} day of the outlook. Must be at least \code{1}
#' but no more that \code{3}.
#' @param type The type of convective outlook data. \code{"cat"} is categorical,
#' \code{"torn"} is tornado risk, \code{"hail"} is hail risk, and \code{"wind"}
#' is wind risk. Note that only \code{"cat"} can be accepted if \code{day} is
#' greater than \code{1}.
#'
#' @import dplyr
#' @import sp
#' @import broom
#' @importFrom rgdal readOGR
#'
#' @export
#'
spcmap <- function(data, day = 1, type = c("cat", "torn", "hail", "wind")) {

  # Convert data to data.frame
  data <- as.data.frame(data)

  # Check data for appropriate columns
  if (!all(c("long", "lat") %in% names(data))) {
    stop("The column names 'long' and 'lat' are not in the input 'data.'")
  }

  # Data must have >= 1 row
  if (nrow(data) < 1) {
    stop("There is no data in the input 'data.'")
  }

  ## Day must be 1 <= x <= 3
  if (!any(day == seq(3))) {
    stop("The input 'day' must be 1, 2, or 3.")
  }

  # Match the type argument
  type <- match.arg(type)

  # Verify that day is appropriate for the type.
  if (day > 1 & type != "cat") {
    stop("If 'day' is not 1, the input 'type' can only be 'cat.'")
  }


  ## Download the spc data
  # Create the filename
  spc_filename <- paste("http://www.spc.noaa.gov/products/outlook/day", day,
                        "otlk_", type, ".kml", sep = "")

  # Create a temporary download file
  temp_filename <- tempfile()
  # Download the file
  download.file(url = spc_filename, destfile = temp_filename, mode = "wb", quiet = TRUE)

  # Read in the fle
  suppressWarnings(spc <- try(readOGR(dsn = temp_filename, verbose = FALSE), silent = TRUE))
  # Delete the file
  invisible(file.remove(temp_filename))

  # If the spc download failed, give all points in 'data' a risk of "None" and
  # return
  if (class(spc) == "try-error") {
    data_risk <- data %>%
      mutate(risk = "None")

    # Warning
    warning("There was no outlook data available for the requested day or type. Returning the 'data' input.")

    # Create a list and return
    return(structure( list(data = data_risk), class = "spcmap" ))

  } else {

    # Tidy the polygon data
    spc_tidy <- tidy(x = spc, region = "Name")

    ## Find the intersection of trial points and severe weather categories
    # Convert data to spatial points
    data_sp <- SpatialPointsDataFrame(coords = select(data, long, lat),
                                      data = select(data, -long, -lat))


    # Adjust the projection
    proj4string(data_sp) <- proj4string(spc)

    # Add risk data to the original data
    data_risk <- data %>%
      mutate(risk = as.character(over(data_sp, spc)$Name),
             risk = ifelse(is.na(risk), "None", risk))

    # Create a list and return
    structure( list(data = data_risk, spc = spc_tidy), class = "spcmap" )

  }

} # Close the function
