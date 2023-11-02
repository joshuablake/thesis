log_sum_exp <- function(x, y) {
  max_value <- pmax(x, y)
  max_value + log1p(exp(pmin(x, y) - max_value))
}

logVL <- function(t, vp) {
  vl <- log(vp[1]) + log(vp[2] + vp[3]) - log_sum_exp(log(vp[3]) - vp[2] * t, log(vp[2]) + vp[3] * t)
  return(vl)
}