test_that("RemoveSeasonal subtracts the per-position mean", {
  y <- c(1, 2, 3, 1, 2, 3)
  t_mmdd <- c(1, 2, 3, 1, 2, 3)
  out <- RemoveSeasonal(y, t_mmdd)

  expect_equal(out$mu, c(1, 2, 3))
  expect_equal(out$anomaly, rep(0, 6))
})

test_that("RemoveSeasonal handles missing values in the series", {
  out <- RemoveSeasonal(c(1, 3, NA), c(1, 1, 1))
  expect_equal(out$mu, 2)
})

test_that("LS_OneBreak recovers a known intercept shift", {
  n <- 100
  X <- seq_len(n)
  Y <- 1 + 0.5 * X + c(rep(0, 60), rep(10, n - 60))

  out <- LS_OneBreak(Y, X, 60)
  expect_equal(unname(out$coef[3]), 10, tolerance = 1e-6)
  expect_lt(out$SSE, 1e-15)
})

test_that("LS_MultiBreaks reproduces LS_OneBreak for one break", {
  n <- 50
  X <- seq_len(n)
  Y <- rnorm(n) + c(rep(0, 20), rep(5, n - 20))

  one <- LS_OneBreak(Y, X, 20)
  multi <- LS_MultiBreaks(Y, X, c(20, n))

  expect_equal(one$SSE, multi$SSE, tolerance = 1e-10)
})
