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

[1] "Not much is going on with me, as I'm just a large language model. 
How about you? What's happening in your world?"


#Get the number of tokens used in a prompt
countTokens(prompt="Hi, what's going on?", apiKey="###")

[1] 8
```

``` r
# Basic text and image prompt
sendPrompt(prompt = "What does this image show?", filePath = "https://en.wikipedia.org/static/images/icons/wikipedia.png",
    apiKey = "###")

"That's the Wikipedia logo, but modified to show a missing piece. 
Specifically, it depicts the Wikipedia globe with a section missing,
representing a gap or incompleteness in the project's coverage.  The
missing piece likely symbolizes a language edition or topic area that is
underdeveloped or absent."
```

``` r
#Example of table parsing
txt <- sendPrompt(prompt="Return a table of the 5 largest US states
                  by population. Use the column names 'state' and 'population'. Return only the table.", 
                  apiKey="###")

txt

[1] "| state | population |\n|---|---|\n| California | 39237836 |\n| Texas | 30028194 |\n| Florida | 22244823 |\n| New York | 20201249 |\n| Pennsylvania | 13002700 |"

cleanTable(txt)

         state population
3   California   39237836
4        Texas   30028194
5      Florida   22244823
6     New York   20201249
7 Pennsylvania   13002700
```
