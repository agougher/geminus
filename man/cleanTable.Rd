\name{cleanTable}
\alias{cleanTable}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
Parsing text string to a table
}
\description{
This function takes a text string from the sendPrompt function and attempts to parse it to a dataframe. Much of the parsing was done via trial and error in trying to understand how Gemini returns tables. In general, it is important to specify the column names in the sendPrompt function and how the text should be delimited. The default values in this function should work ok when no particular instructions were given, but it is very important to verify the output.
}
\usage{
cleanTable(txt, rowsplit = "|", newline = "\\n")
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{txt}{
Single text string from sendPrompt to attempt to parse into a table
}
  \item{rowsplit}{
Character used to split rows of the table
}
  \item{newline}{
Character used to identify a new line
}
}
\details{
%%  ~~ If necessary, more details than the description above ~~
}
\value{
A dataframe parsed from the text string
}
\references{
%% ~put references to the literature/web site here ~
}
\author{
%%  ~~who you are~~
}
\note{
%%  ~~further notes~~
}

%% ~Make other sections like Warning with \section{Warning }{....} ~

\seealso{
%% ~~objects to See Also as \code{\link{help}}, ~~~
}
\examples{
## Note an API key is needed for the sendPrompt function to work!
\dontrun{
cleanTable(sendPrompt(prompt="Return a table of the 5 largest US states by population. Include the state name and the total population.", type="text", apiKey="###"))
}
}
