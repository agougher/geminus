#' Sending prompts to Gemini & GPT APIs
#'
#' The function sends prompts to Google's Gemini API and OpenAI's GPT APIs, and returns a text string as response. Prompts can be either text or text and an image. Currently, the function will only return one text string as a response. When asking the LLM to return a table, it is important to be very clear about which symbols should be used as row and newline delimiters. Rudimentary cleaning to convert a single text string (returned from this function) to a table can be done with the cleanTable function, but results need to verified to be sure it was parsed correctly. Check the Gemini and GPT websites for current rate limits.
#'
#' @param prompt Text prompt to send to Gemini or GPT. Should be a single text string.
#' @param type Can be either "text" or "image". If "image" the directory location or url of the image should be given.
#' @param apiKey Google Developer's API key or OpenAI's API key. Needed to run the function. See https://ai.google.dev/gemini-api/docs/api-key
#' @param image If type is "image" this should be the local directory location of the image or a url.
#' @param imageDetail Image resolution used for GPT model. Can be "low" or "high"
#' @param temperature Temperature is a parameter that controls the degree of randomness and creativity in the response. For more deterministic and repeatable responses, use a lower number. Higher temperatures may yield greater possibility of hallucination. For Gemini, the temperature should be between 0 and 1, and for GPT between 0 and 2.
#' @param safety Safety threshold for blocking responses in Gemini. Currently, only one value can be set for all safety categories. Possible values are "HARM_BLOCK_THRESHOLD_UNSPECIFIED", "BLOCK_LOW_AND_ABOVE","BLOCK_MEDIUM_AND_ABOVE","BLOCK_ONLY_HIGH". The default value is "BLOCK_MEDIUM_AND_ABOVE".
#' @param model Model variant to be used. Default is "gemini-1.5-flash" which can be used for text or images. See https://ai.google.dev/gemini-api/docs/models/gemini and https://platform.openai.com/docs/models for other options. Currently only "Gemini" and "GPT" models are supported.
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
sendPrompt <- function(prompt, type="text", apiKey=NULL, image=NULL, imageDetail="low", temperature=0, safety="BLOCK_MEDIUM_AND_ABOVE", model="gemini-1.5-flash"){

  if(!curl::has_internet()){
    stop("Internet connection needed to run this function. Check connectivity.", call.=FALSE)
  }

  if(is.null(apiKey)){
    stop("API key needed!", call.=FALSE)
  }

  #Gemini models
  if(grepl(pattern="gemini", x=model)){

    safetySetting <- list(
      list(category="HARM_CATEGORY_HATE_SPEECH",
           threshold=safety),
      list(category="HARM_CATEGORY_SEXUALLY_EXPLICIT",
           threshold=safety),
      list(category="HARM_CATEGORY_DANGEROUS_CONTENT",
           threshold=safety),
      list(category="HARM_CATEGORY_HARASSMENT",
           threshold=safety))

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
        warning("No response returned due to safety. Consider increasing the safety threshold.", call.=FALSE)
      } else if(httr::content(res)$candidates[[1]]$finishReason == "RECITATION"){
        warning("No response returned due to recitation.", call.=FALSE)
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
      } else if(httr::content(res)$candidates[[1]]$finishReason == "RECITATION"){
        warning("No response returned due to recitation.", call.=FALSE)
      } else {
        return(trimws(httr::content(res)$candidates[[1]]$content$parts[[1]]$text))
      }

    }
  }

  #GPT models
  if(grepl(pattern="gpt", x=model)){

    #For text
    if(type == "text"){

      if(!is.null(image)){
        warning("An image was provided. Did you mean to set type to 'image'?", call.=FALSE)
      }

      url <- "https://api.openai.com/v1/chat/completions"

      jsonToSend <- list(
        model = model,
        temperature = temperature,
        messages = list(list(
          role = "user",
          content = prompt
        )
        )
      )

      response <- httr::POST(
        url = url,
        httr::add_headers(Authorization = paste("Bearer", apiKey)),
        httr::content_type_json(),
        encode = "json",
        body = jsonToSend
      )

      return(content(response)$choices[[1]]$message$content)


    }

    #For images
    if(type == "image"){

      url <- "https://api.openai.com/v1/chat/completions"

      imageData <- base64enc::base64encode(image)
      imageData = paste0("data:image/jpeg;base64,",imageData)

      jsonToSend <- list(
        model = model,
        temperature=temperature,
        messages = list(list(
            role = "user",
            content = list(
              list(type = "text", text = prompt),
              list(
                type = "image_url",
                image_url = list(url = imageData, detail = imageDetail)
              )
            )
          )
        )
      )

      response <- httr::POST(
        url = url,
        httr::add_headers(Authorization = paste("Bearer", apiKey)),
        httr::content_type_json(),
        encode = "json",
        body = jsonToSend
      )

      return(content(response)$choices[[1]]$message$content)

    }

  }

}
