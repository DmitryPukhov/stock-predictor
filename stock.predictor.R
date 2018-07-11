# Quantmod library
library(curl)
library(quantmod)
library(rusquant)
library(xts)
library(astsa)
library(utils)

############### Main ##########################

#price.ohlc <- getSymbols("SBER", from = Sys.Date()-1, to = Sys.Date()-1, src = "Finam", period = "1 min", auto.assign = FALSE)
# Load the data
price.ohlc <- getSymbols("RTSI", src = "Finam", period = "day", auto.assign = FALSE, verbose=TRUE)

# Consider SBER split to 1000 on 2007-07-18
price.cl <- Cl(merge(c(price.ohlc["/2007-07-17"]/1000, price.ohlc["2007-07-18/"])))

# Convert to months. Could download months, but maybe days will be useful in future.
price.cl <- Cl(to.period(price.cl, "month"))

# Up to 2017 for train
price.cl.train <- price.cl["/2017"]
# 9 months for test
price.cl.test <- price.cl["2017/2017-09"]

# Analyze auto correlation:  ACF and PACF
acf2(na.omit(diff(log(price.cl.train))))

# Analyze acf2 for seasonality 
acf2(na.omit(diff(diff(log(price.cl.train)))))

# Fit the model, try different ar, i, ma
sarima(price.cl.train, p = 1, d = 1, q = 1, P = 0, D = 0, Q = 3, S = 12)

# Predict
price.cl.pred.raw <- sarima.for(price.cl, p = 1, d = 1, q = 1, P = 0, D = 0, Q = 3, S = 12, n.ahead=9)
price.cl.pred <- xts(price.cl.pred.raw$pred, timeBasedSeq("201702/201710"))

# Draw the plot
plot(merge(price.cl, price.cl.pred), type="n")
points(price.cl.train, col = "blue")
points(price.cl.pred, col = "red", lty=2)

