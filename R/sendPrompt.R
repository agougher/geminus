#' Send prompts to Gemini & GPT APIs
#'
#' The function sends prompts to Google's Gemini API and OpenAI's GPT API, and returns a text string as response. Prompts can be either text or text and an image or pdf file. Currently, the function will only return one text string as a response. When asking the LLM to return a table, it is important to be very clear about which symbols should be used as row and newline delimiters. Rudimentary cleaning to convert a single text string (returned from this function) to a table can be done with the cleanTable function, but results need to verified to be sure it was parsed correctly. Check the Gemini and GPT websites for current rate limits.
#'
#' @param prompt Text prompt to send to Gemini or GPT. Should be a single text string.
#' @param apiKey Google Developer's API key or OpenAI's API key. Needed to run the function. See https://ai.google.dev/gemini-api/docs/api-key and https://platform.openai.com/settings/organization/api-keys
#' @param filePath Path or url to image or pdf file. The function attempts to automatically detect the file type. Not every file type is supported by each model. Current files that are supported here are - Gemini: images, PDFs (png, jpeg, webp, heic, heif), CSVs; GPT: images (png, jpeg), PDFs
#' @param imageDetail Image resolution used for GPT models. Can be "low" or "high"
#' @param temperature Temperature is a parameter that controls the degree of randomness and creativity in the response. For more deterministic and repeatable responses, use a lower number. Higher temperatures may yield greater possibility of hallucination. For Gemini, the temperature should be between 0 and 1, and for GPT between 0 and 2.
#' @param safety Safety threshold for blocking responses in Gemini. Currently, only one value can be set for all safety categories. Possible values are "HARM_BLOCK_THRESHOLD_UNSPECIFIED", "BLOCK_LOW_AND_ABOVE","BLOCK_MEDIUM_AND_ABOVE","BLOCK_ONLY_HIGH". The default value is "BLOCK_MEDIUM_AND_ABOVE".
#' @param model Model variant to be used. Default is "gemini-1.5-flash" which can be used for text or images. See https://ai.google.dev/gemini-api/docs/models/gemini and https://platform.openai.com/docs/models for other options. Currently only the flagship models are supported.
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
#' sendPrompt(prompt="What does this image show?", filePath = "https://en.wikipedia.org/static/images/icons/wikipedia.png", apiKey="###")
#' }
sendPrompt <- function(prompt, apiKey=NULL, filePath=NULL, imageDetail="low", temperature=0, safety="BLOCK_MEDIUM_AND_ABOVE", model="gemini-1.5-flash"){

  if(!curl::has_internet()){
    stop("Internet connection needed to run this function. Check connectivity.", call.=FALSE)
  }

  if(is.null(apiKey)){
    stop("API key needed!", call.=FALSE)
  }


  #Gemini models
  if(grepl(pattern="gemini", x=model)){

    #Define safety settings
    safetySetting <- list(
      list(category="HARM_CATEGORY_HATE_SPEECH",
           threshold=safety),
      list(category="HARM_CATEGORY_SEXUALLY_EXPLICIT",
           threshold=safety),
      list(category="HARM_CATEGORY_DANGEROUS_CONTENT",
           threshold=safety),
      list(category="HARM_CATEGORY_HARASSMENT",
           threshold=safety))

    #If just text, filePath is NULL
    if(is.null(filePath)){
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
    } else
      #If files are provided, filePath isn't NULL
      if(!is.null(filePath)){

        #Get the file type
        filetype <- tolower(tail(strsplit(x=filePath, split=".", fixed=TRUE)[[1]], n=1))

        if(filetype %in% c("pdf","csv","png","jpeg","webp","heic","heif")){
          if(filetype == "pdf"){
            mimeInfo <- "application/pdf"
          } else if(filetype %in% c("png","jpeg","webp","heic","heif")){
            mimeInfo <- paste0("image/", filetype)
          } else if(filetype == "csv") {
            mimeInfo <- "text/csv"
          }
        } else {
          stop("File type not supported!", call.=FALSE)
        }

        #Base64 encode the file
        fileData <- base64enc::base64encode(filePath)

        jsonToSend <- list(
          contents = list(
            list(
              parts = list(
                list(text = prompt)
                ,
                list( #for just text just remove this list item
                  inlineData = list(
                    mimeType = mimeInfo,
                    data = fileData
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
      }

    url <- paste0("https://generativelanguage.googleapis.com/v1beta/models/", model,":generateContent?key=", apiKey)


    # Set the request headers
    headers <- c(
      "Content-Type" = "application/json"
    )

    # Send the POST request with JSON body
    res <- httr::POST(url, body = jsonToSend,encode="json", addHeaders = headers)

    #Send some warnings if the model returns an error work
    if(httr::content(res)$candidates[[1]]$finishReason == "SAFETY"){
      warning("No response returned due to safety. Consider increasing the safety threshold.", call.=FALSE)
    } else if(httr::content(res)$candidates[[1]]$finishReason == "RECITATION"){
      warning("No response returned due to recitation.", call.=FALSE)
    } else {
      return(trimws(httr::content(res)$candidates[[1]]$content$parts[[1]]$text))
    }

  }

  #GPT models
  if(grepl(pattern="gpt|o4|o3", x=model)){


    url <- "https://api.openai.com/v1/chat/completions"
    #If just text, filePath is NULL
    if(is.null(filePath)){
      jsonToSend <- list(
        model = model,
        temperature = temperature,
        messages = list(list(
          role = "user",
          content = prompt
        )
        )
      )

    } else if(!is.null(filePath)){ #if a file is provided

      filetype <- tolower(tail(strsplit(x=filePath, split=".", fixed=TRUE)[[1]], n=1))

      #if file is an image
      if(filetype %in% c("png","jpeg")){
        imageData <- base64enc::base64encode(filePath)
        imageData = paste0("data:image/", filetype,";base64,",imageData)

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
      } else if(filetype %in% "pdf"){ #if file is a pdf
        fileData <- base64enc::base64encode(filePath)
        fileData = paste0("data:application/", filetype,";base64,",fileData)

        jsonToSend <- list(
          model = model,
          temperature=temperature,
          messages = list(list(
            role = "user",
            content = list(
              list(type = "text", text = prompt),
              list(
                type = "file",
                file=list(
                  filename=filePath,
                  file_data = fileData)
              )
            )
          )
          )
        )

      } else {
        stop("File type not supported!", call.=FALSE)
      }

    }
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
