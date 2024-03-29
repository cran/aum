\name{aum_line_search}
\alias{aum_line_search}
\title{aum line search}
\description{Exact line search using a C++ STL map (red-black tree) to
implement a queue of line intersection events. If number of rows
of \code{error.diff.df} is B, and number of iterations is I, then space
complexity is O(B) and time complexity is O( (I+B)log B ).}
\usage{aum_line_search(error.diff.df, 
    feature.mat, weight.vec, 
    pred.vec = NULL, 
    maxIterations = nrow(error.diff.df))}
\arguments{
  \item{error.diff.df}{\code{\link{aum_diffs}} data frame with B rows, one for each breakpoint in
example-specific error functions.}
  \item{feature.mat}{N x p matrix of numeric features.}
  \item{weight.vec}{p-vector of numeric linear model coefficients.}
  \item{pred.vec}{N-vector of numeric predicted values. If NULL, \code{feature.mat} and
\code{weight.vec} will be used to compute predicted values.}
  \item{maxIterations}{max number of line search iterations, either a positive integer or
"max.auc" or "min.aum" indicating to keep going until AUC
decreases or AUM increases.}
}

\value{List of class aum_line_search. Element named "line_search_result"
is a data table with number of rows equal to \code{maxIterations} (if it
is positive integer, info for all steps, q.size column is number
of items in queue at each iteration), otherwise 1 (info for the
best step, q.size column is the total number of items popped off
the queue).}

\author{Toby Dylan Hocking <toby.hocking@r-project.org> [aut, cre], Jadon Fowler [aut] (Contributed exact line search C++ code)}




\examples{

if(require("data.table"))setDTthreads(1L)#for CRAN check.

## Example 1: two binary data.
(bin.diffs <- aum::aum_diffs_binary(c(0,1)))
if(requireNamespace("ggplot2"))plot(bin.diffs)
bin.line.search <- aum::aum_line_search(bin.diffs, pred.vec=c(10,-10))
if(requireNamespace("ggplot2"))plot(bin.line.search)

## Example 2: two changepoint examples, one with three breakpoints.
data(neuroblastomaProcessed, package="penaltyLearning", envir=environment())
nb.err <- with(neuroblastomaProcessed$errors, data.frame(
  example=paste0(profile.id, ".", chromosome),
  min.lambda,
  max.lambda,
  fp, fn))
(nb.diffs <- aum::aum_diffs_penalty(nb.err, c("1.1", "4.2")))
if(requireNamespace("ggplot2"))plot(nb.diffs)
nb.line.search <- aum::aum_line_search(nb.diffs, pred.vec=c(1,-1))
if(requireNamespace("ggplot2"))plot(nb.line.search)
aum::aum_line_search(nb.diffs, pred.vec=c(1,-1)-c(1,-1)*0.5)

## Example 3: all changepoint examples, with linear model.
X.sc <- scale(neuroblastomaProcessed$feature.mat)
keep <- apply(is.finite(X.sc), 2, all)
X.keep <- X.sc[1:50,keep]
weight.vec <- rep(0, ncol(X.keep))
(nb.diffs <- aum::aum_diffs_penalty(nb.err, rownames(X.keep)))
nb.weight.search <- aum::aum_line_search(
  nb.diffs,
  feature.mat=X.keep,
  weight.vec=weight.vec, 
  maxIterations = 200)
if(requireNamespace("ggplot2"))plot(nb.weight.search)

## Alternate viz with x=iteration instead of step size.
nb.weight.full <- aum::aum_line_search(
  nb.diffs,
  feature.mat=X.keep,
  weight.vec=weight.vec, 
  maxIterations = 1000)
library(data.table)
weight.result.tall <- suppressWarnings(melt(
  nb.weight.full$line_search_result[, iteration:=1:.N][, .(
    iteration, auc, q.size,
    log10.step.size=log10(step.size),
    log10.aum=log10(aum))],
  id.vars="iteration"))
if(require(ggplot2)){
  ggplot()+
    geom_point(aes(
      iteration, value),
      shape=1,
      data=weight.result.tall)+
    facet_grid(variable ~ ., scales="free")+
    scale_y_continuous("")
}

}
