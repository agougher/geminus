sendPrompt <- function(prompt, type="text", apiKey=NULL, image=NULL, temperature=0, safety="BLOCK_LOW_AND_ABOVE"){

  if(!curl::has_internet()){
    stop("Internet connection needed to run this function. Check connectivity.", call.=FALSE)
  }

  safetySetting <- list(
    list(category="HARM_CATEGORY_HATE_SPEECH",
         threshold=safety),
    list(category="HARM_CATEGORY_SEXUALLY_EXPLICIT",
         threshold=safety),
    list(category="HARM_CATEGORY_DANGEROUS_CONTENT",
         threshold=safety),
    list(category="HARM_CATEGORY_HARASSMENT",
         threshold=safety))

  if(is.null(apiKey)){
    stop("API key needed!", call.=FALSE)
  }


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
      ),
      generationConfig = list( #temperature controls the amount of randomness in the response. Setting to 0 is more deterministic/repeatable
        temperature = temperature
      ),
      safetySettings = safetySetting
    )

    url <- "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key="

    # Add the API key to the URL
    url <- paste0(url, apiKey)

    headers <- c(
      "Content-Type" = "application/json"
    )

    # Send the POST request with JSON body
    res <- httr::POST(url, body = jsonToSend,encode="json", addHeaders = headers)

    if(httr::content(res)$candidates[[1]]$finishReason == "SAFETY"){
      warning("No response returned due to safety. Consider increasing the safety threshold.", call.=FALSE)
    } else {

      return(trimws(httr::content(res)$candidates[[1]]$content$parts[[1]]$text))
    }




  }

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
      ),
      generationConfig = list( #temperature controls the amount of randomness in the response. Setting to 0 is more deterministic/repeatable
        temperature = temperature
      ),
      safetySettings = safetySetting
    )

    url <- "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent?key="

    # Add the API key to the URL
    url <- paste0(url, apiKey)

    # Set the request headers
    headers <- c(
      "Content-Type" = "application/json"
    )

    # Send the POST request with JSON body
    res <- httr::POST(url, body = jsonToSend,encode="json", addHeaders = headers)

    if(httr::content(res)$candidates[[1]]$finishReason == "SAFETY"){
      warning("No response returned due to safety. Consider increasing the safety threshold.", call.=FALSE)
    } else {

      return(trimws(httr::content(res)$candidates[[1]]$content$parts[[1]]$text))
    }

  }

}
