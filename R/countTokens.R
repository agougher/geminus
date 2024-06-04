#' Count number of tokens in a prompt
#'
#' @param prompt Text prompt to send to Gemini. Should be a single text string.
#' @param type Can be either "text" or "image". If "image" the directory location or url of the image should be given.
#' @param apiKey Google Developer's API key. Needed to run the function. See https://ai.google.dev/gemini-api/docs/api-key
#' @param image If type is "image" this should be the local directory location of the image or a url.
#' @param model Gemini model variant to be used. Default is "gemini-1.5-flash" which can be used for text or images. See https://ai.google.dev/gemini-api/docs/models/gemini for other options.
#'
#'
#' @return
#' Number of tokens used in the prompt.
#' @export
#'
#' @examples
#' \dontrun{
#' #Simple text  prompt
#' countTokens(prompt="Hi, how are you?", apiKey="###")
#' }
countTokens <- function(prompt, type="text", apiKey=NULL, image=NULL, model="gemini-1.5-flash"){

  if(!curl::has_internet()){
    stop("Internet connection needed to run this function. Check connectivity.", call.=FALSE)
  }

  if(is.null(apiKey)){
    stop("API key needed!", call.=FALSE)
  }


  #For text
  if(type == "text"){

    if(!is.null(image)){
      warning("An image was provided. Did you mean to set type to 'image'?", call.=FALSE)
    }

    # Construct the JSON request body
    jsonToSend <- list(
      contents = list(
        list(
          parts = list(
            list(text = prompt)
          )
        )
      )
    )


    url <- paste0("https://generativelanguage.googleapis.com/v1beta/models/",model, ":countTokens?key=")
    # Add the API key to the URL
    url <- paste0(url, apiKey)

    headers <- c(
      "Content-Type" = "application/json"
    )

    # Send the POST request with JSON body
    res <- httr::POST(url, body = jsonToSend,encode="json", addHeaders = headers)

    return(httr::content(res)$totalTokens)

  }

  #For images
  if(type == "image"){

    if(is.null(image)){
      stop("Image not provided!", call.=FALSE)
    }

    imageData <- base64enc::base64encode(image)

    jsonToSend <- list(
      contents = list(
        list(
          parts = list(
            list(text = prompt)
            ,
            list(
              inlineData = list(
                mimeType = "image/png",
                data = imageData
              )
            )
          )
        )
      )
    )

    url <- paste0("https://generativelanguage.googleapis.com/v1beta/models/", model,":countTokens?key=")

    # Add the API key to the URL
    url <- paste0(url, apiKey)

    # Set the request headers
    headers <- c(
      "Content-Type" = "application/json"
    )

    # Send the POST request with JSON body
    res <- httr::POST(url, body = jsonToSend,encode="json", addHeaders = headers)


    return(httr::content(res)$totalTokens)

  }

}
