#' Sending prompts to Gemini API
#'
#' The function sends prompts to Google's Gemini API and returns a text string as response. Prompts can be either text or text and an image. Currently, the function will only return one text string as a response. When asking the LLM to return a table, it is important to be very clear about which symbols should be used as row and newline delimiters. Rudimentary cleaning to convert a single text string (returned from this function) to a table can be done with the cleanTable function, but results need to verified to be sure it was parsed correctly. Check the Gemini API website for current rate limits.
#'
#' @param prompt Text prompt to send to Gemini. Should be a single text string.
#' @param type Can be either "text" or "image". If "image" the directory location or url of the image should be given.
#' @param apiKey Google Developer's API key. Needed to run the function. See https://ai.google.dev/gemini-api/docs/api-key
#' @param image If type is "image" this should be the local directory location of the image or a url.
#' @param temperature numeric value between 0 and 1. Temperature is a Gemini parameter that controls the degree of randomness and creativity in the response. For more deterministic and repeatable responses, use a lower number. Higher temperatures may yield greater possibility of hallucination.
#' @param safety Safety threshold for blocking responses. Currently, only one value can be set for all safety categories. Possible values are "HARM_BLOCK_THRESHOLD_UNSPECIFIED", "BLOCK_LOW_AND_ABOVE","BLOCK_MEDIUM_AND_ABOVE","BLOCK_ONLY_HIGH". The default value is "BLOCK_MEDIUM_AND_ABOVE".
#' @param model Gemini model variant to be used. Default is "gemini-1.5-flash" which can be used for text or images. See https://ai.google.dev/gemini-api/docs/models/gemini for other options.
#'
#'
#' @return
#' Response is a single character string returned without any cleaning. See cleanTable to do some rudimentary cleaning to return a table.
#' @export
#'
#'@references
#'https://ai.google.dev/gemini-api/docs/models/gemini
#' @examples
#' \dontrun{
#' #Simple text  prompt
#' sendPrompt(prompt="Hi, how are you?", apiKey="###")
#'
#' #Sending an image
#' sendPrompt(prompt="What does this image show?", type="image", image= "https://en.wikipedia.org/static/images/icons/wikipedia.png", apiKey="###")
#' }
sendPrompt <- function(prompt, type="text", apiKey=NULL, image=NULL, temperature=0, safety="BLOCK_MEDIUM_AND_ABOVE", model="gemini-1.5-flash"){

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
      ),
      generationConfig = list( #temperature controls the amount of randomness in the response. Setting to 0 is more deterministic/repeatable
        temperature = temperature
      ),
      safetySettings = safetySetting
    )


    url <- paste0("https://generativelanguage.googleapis.com/v1beta/models/",model, ":generateContent?key=")

    # Add the API key to the URL
    url <- paste0(url, apiKey)

    headers <- c(
      "Content-Type" = "application/json"
    )

    # Send the POST request with JSON body
    res <- httr::POST(url, body = jsonToSend,encode="json", addHeaders = headers)

    if(httr::content(res)$candidates[[1]]$finishReason == "SAFETY"){
      warning("No response returned due to safety. Consider adjusting the safety threshold.", call.=FALSE)
    } else {

      return(trimws(httr::content(res)$candidates[[1]]$content$parts[[1]]$text))
    }




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
      ),
      generationConfig = list( #temperature controls the amount of randomness in the response. Setting to 0 is more deterministic/repeatable
        temperature = temperature
      ),
      safetySettings = safetySetting
    )

    url <- paste0("https://generativelanguage.googleapis.com/v1beta/models/", model,":generateContent?key=")

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
