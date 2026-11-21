#' Remove the seasonal cycle
#'
#' Compute the mean of each calendar day-of-year (or month) and subtract it
#' from the original series.
#'
#' @param y Numeric vector of observations.
#' @param t_mmdd Integer vector of the same length as `y`, giving the calendar
#'   position of each observation (e.g. month or MMDD).
#'
#' @return A list with two elements:
#' - `mu`     : seasonal means, ordered by `sort(unique(t_mmdd))`.
#' - `anomaly`: de-seasonalised series.
#' @export
RemoveSeasonal <- function(y, t_mmdd) {
  stopifnot(length(y) == length(t_mmdd))

  inds <- sort(unique(t_mmdd))
  mu <- numeric(length(inds))
  anomaly <- numeric(length(y))

  for (i in seq_along(inds)) {
    ind <- which(t_mmdd == inds[i])
    mu[i] <- mean(y[ind], na.rm = TRUE)
    anomaly[ind] <- y[ind] - mu[i]
  }

  list(mu = mu, anomaly = anomaly)
}

#' Solve a least-squares problem
#'
#' Fit `response` on `design` via QR decomposition, and return the fitted
#' values and the residual sum of squares.
#'
#' @param design Design matrix, one column per coefficient.
#' @param response Numeric response vector.
#' @param only.SSE If `TRUE`, only return the residual sum of squares.
#' @param ... Ignored, kept for compatibility.
#'
#' @return A list with `coef`, `fitted`, `resi` and `SSE`,
#'   or only `SSE` when `only.SSE = TRUE`.
#' @export
lm_solve <- function(design, response, only.SSE = FALSE, ...) {
  fit <- .lm.fit(design, as.matrix(response))
  if (only.SSE) {
    return(list(SSE = sum(fit$residuals^2)))
  }

  list(
    coef = fit$coefficients,
    fitted = as.vector(design %*% fit$coefficients),
    resi = fit$residuals,
    SSE = sum(fit$residuals^2)
  )
}

#' Single-breakpoint piecewise regression
#'
#' Same slope, different intercept on each side of the breakpoint.
#'
#' @param Y Response vector.
#' @param X Predictor vector, usually time.
#' @param Ic Position of the change point: `[1, Ic]` and `[Ic + 1, n]` are the
#'   two segments. `NA` fits a single straight line.
#' @param ... Passed to [lm_solve()].
#'
#' @return See [lm_solve()].
#' @export
LS_OneBreak <- function(Y, X, Ic, ...) {
  n <- length(Y)
  design <- cbind(1, X)
  if (!is.na(Ic)) {
    design <- cbind(design, c(rep(0, Ic), rep(1, n - Ic)))
  }
  lm_solve(design, Y, ...)
}

#' Multiple-breakpoint piecewise regression
#'
#' Same slope, different intercept on each segment.
#'
#' @param Y Response vector.
#' @param X Predictor vector, usually time.
#' @param Ips Positions of the segment ends, the last one being `length(Y)`.
#' @param ... Passed to [lm_solve()].
#'
#' @return See [lm_solve()].
#' @export
LS_MultiBreaks <- function(Y, X, Ips, ...) {
  n_breaks <- length(Ips) - 1
  design <- cbind(1, X - mean(X))

  for (i in seq_len(n_breaks)) {
    segment <- numeric(length(Y))
    segment[(Ips[i] + 1):Ips[i + 1]] <- 1
    design <- cbind(design, segment)
  }

  lm_solve(design, Y, ...)
}
