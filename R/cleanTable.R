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
  if(any(apply(out, 1, function(x) all(x == x[1])))){
    out <- out[-which(apply(out, 1, function(x) all(x == x[1]))),]
  }


  #if the row only has one unique character, remove it (some are just "-" of different lengths)
  if(any(apply(out,1,function(x) length(unique(strsplit(paste(x, collapse=""),"")[[1]])) == 1))){
    out <- out[-which(apply(out,1,function(x) length(unique(strsplit(paste(x, collapse=""),"")[[1]])) == 1)),]

  }

  return(out)

}
