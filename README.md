geminus: Simple R functions for interacting with the Gemini API
================
Andy Gougherty
2024-05-17

## Overview

Functions in this package provide an easy way for sending basic requests
to Google’s Gemini API. The functions here build off our paper testing
the reliability of an earlier version of the LLM to extract information
from the scientific literature (see
[here](https://doi.org/10.1038/s44185-024-00043-9) for more details).
The functions were built specifically with scientific research in mind,
so are likely not useful for all purposes.

The main function in this package is `sendPrompt` which sends text or
text and image to the LLM and will return a single text string as a
response. When tabular data is requested, the `cleanTable` function can
be used to attempt to parse the text string to a data frame, based on
how, in my experience, Gemini frequently returns tables. The table,
however, should be carefully checked to make sure it was parsed
correctly.

Note, an [API key](https://ai.google.dev/gemini-api/docs/api-key) is
needed for these functions to run. Also, see the Gemini [help
documents](https://ai.google.dev/gemini-api/docs/api-overview) for
specifics about how the API works and current rate limits.

### Installation

``` r
devtools::install_github("agougher/geminus")
library(geminus)
```

### Examples

``` r
#Basic text prompt
sendPrompt(prompt="Hi, what's going on?", apiKey="###")

[1] "I am an AI chatbot assistant, I don't have personal experiences
or emotions, so I don't have anything going on. I am here to help
you with any questions or tasks you may have. Is there anything I
can assist you with today?"
```

``` r
#Basic text and image prompt
sendPrompt(prompt="What does this image show?", 
           type="image", 
           image= "https://en.wikipedia.org/static/images/icons/wikipedia.png", 
           apiKey="###")

[1] "The image shows a globe with puzzle pieces on it. Each puzzle
piece has a different letter on it. The letters are from different
alphabets."
```

``` r
#Example of table parsing
txt <- sendPrompt(prompt="Return a table of the 5 largest US states
                  by population. Include the state name and the
                  total population.", 
                  type="text", 
                  apiKey="###")

txt

[1] "| State | Population |\n|---|---|\n| California | 39.56 million
|\n| Texas | 29.5 million |\n| Florida | 21.78 million |\n| New York
| 20.2 million |\n| Pennsylvania | 12.8 million |"

cleanTable(txt)

         State    Population
3   California 39.56 million
4        Texas  29.5 million
5      Florida 21.78 million
6     New York  20.2 million
7 Pennsylvania  12.8 million
```
