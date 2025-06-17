geminus: Simple R functions for interacting with Gemini & GPT APIs
================
Andy Gougherty
2025-06-16

## Overview

Functions in this package provide an easy way to send basic requests to
Google’s Gemini API and OpenAI’s GPT API. The functions here build off
our work testing the reliability of an earlier version of Gemini to
extract information from the scientific literature (see
[here](https://doi.org/10.1038/s44185-024-00043-9) for more details).
The functions were built specifically for synthesizing large amounts of
text for meta-analyses, so they are likely not useful for all purposes.

The main function in this package is `sendPrompt` which sends text
prompts, optionally with an image or pdf, to the Gemini or GPT LLMs and
will return a single text string as a response. When tabular data is
requested, the `cleanTable` function can be used to attempt to parse the
text string to a data frame, based on how, in my experience, the LLMs
frequently returns tables. The table, however, should be carefully
checked to make sure it was parsed correctly.

Note, a Gemini or OpenAI API key is needed for these functions to run,
and the key must match the respective Gemini or GPT model being called
(i.e., a Gemini key can’t be used for GPT). These functions support
multiple model variants (e.g., Gemini 1.5 Flash, Gemini 1.5 Pro, GPT-3.5
Turbo, GPT-4o) but only the flagship Gemini and GPT models. The default
is Gemini 1.5 Flash.

### Installation

``` r
devtools::install_github("agougher/geminus", dependencies = TRUE)
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

#Get the number of tokens used in a prompt
countTokens(prompt="Hi, what's going on?", apiKey="###")

[1] 8
```

``` r
#Basic text and image prompt
sendPrompt(prompt="What does this image show?", 
           file = "https://en.wikipedia.org/static/images/icons/wikipedia.png", 
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
