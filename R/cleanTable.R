#' Parsing text string to a table
#'
#' This function takes a text string from the sendPrompt function and attempts to parse it to a dataframe. The procedure was developed via trial and error in trying to understand how Gemini returns tables. In general, it is important to specify the column names in the sendPrompt function and how the text should be delimited. The default values in this function should work ok when no particular instructions were given, but it is very important to verify the output.
#'
#' @param txt Single text string from sendPrompt to attempt to parse into a table
#' @param rowsplit Character used to split rows of the table
#' @param newline Character used to identify a new line
#'
#' @return A dataframe parsed from the text string
#' @export
#'
#' @examples
#' \dontrun{
#' cleanTable(sendPrompt(prompt="Return a table of the 5 largest US states by population. Include the state name and the total population.", type="text", apiKey="###"))
#' }
cleanTable <- function(txt, rowsplit="|", newline="\\n"){

  '%>%' <- purrr::'%>%'
  out <- purrr::map(txt, function(x) {
    tibble::tibble(text = unlist(stringr::str_split(x, pattern = newline))) %>%
      tibble::rowid_to_column(var = "line")
  })


  out <- out[[1]]

  #remove white spaces, and split based on vertical bar, which is used as the delimiter
  out <- as.data.frame(trimws(do.call('rbind', strsplit(out$text, split=rowsplit, fixed=TRUE)), which=c("both")))

  #in some previous runs, there was a remnant | at the beginning or end
  out[,1] <-  gsub(out[,1], pattern=paste0(rowsplit, " "), replacement="", fixed=TRUE)
  out[,ncol(out)] <-  gsub(out[,ncol(out)], pattern=paste0(" ",rowsplit), replacement="", fixed=TRUE)


  #if all the values in the row are the same as the first value remove it
  #in some initial runs the number of dashes were note the same
  #previously this was done below, but gpt sometimes returns a first row of "```\n", this should remove that row before setting the column names
  #This will effectively also remove any message the LLM returns before the table
  if(any(apply(out, 1, function(x) all(x == x[1])))){
    out <- out[-which(apply(out, 1, function(x) all(x == x[1]))),]
  }

  #set the first row as the column names, and remove the first row
  names(out) <- out[1,]
  out <- out[-1,]



  #if a column is all blanks, remove it
  #sometimes the row splits an empty row at the beginning
  if(any(apply(out,2, function(x) all(x=="")))){
    out <- out[,-which(apply(out,2, function(x) all(x=="")))]

  }


  #if all the values in the row are the same as the first value remove it
  #in some initial runs the number of dashes were note the same
  #also done above, as sometimes the values are all the same except the first column which is just blank
  if(any(apply(out, 1, function(x) all(x == x[1])))){
    out <- out[-which(apply(out, 1, function(x) all(x == x[1]))),]
  }


  #if the row only has one unique character, remove it (some are just "-" of different lengths)
  if(any(apply(out,1,function(x) length(unique(strsplit(paste(x, collapse=""),"")[[1]])) == 1))){
    out <- out[-which(apply(out,1,function(x) length(unique(strsplit(paste(x, collapse=""),"")[[1]])) == 1)),]

  }

  #if the row only has only one unique character AFTER the first character, remove it (sometimes it returns :--- with -'s of various lengths)
  if(any(apply(out,1,function(x) length(unique(strsplit(paste(str_sub(x,start=2), collapse=""),"")[[1]])) == 1))){
    out <- out[-which(apply(out,1,function(x) length(unique(strsplit(paste(str_sub(x,start=2), collapse=""),"")[[1]])) == 1)),]

  }


  return(out)

}
