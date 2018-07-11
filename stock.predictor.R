# Quantmod library
library(curl)
library(quantmod)
library(rusquant)
library(xts)
library(astsa)
library(utils)
require(RCurl)
library(dplyr)

############### Main ##########################

#price.ohlc <- getSymbols("SBER", from = Sys.Date()-1, to = Sys.Date()-1, src = "Finam", period = "1 min", auto.assign = FALSE)
# Load the data
#url <- getURL("https://raw.githubusercontent.com/DmitryPukhov/stock-predictor/master/data/SBER_170721_170722.csv")
url <- getURL("https://raw.githubusercontent.com/DmitryPukhov/stock-predictor/master/data/RI.RTSI_180101_180313.csv")
price.csv <- read.csv(textConnection(url))
price.csv <- price.csv[-c(1:2)]

price.ohlcv = as.xts(read.zoo(price.csv, index.column=c(1,2), tz="UTC", format="%Y%m%d%H:%M:%S"))
names(price.ohlcv) <- c("Open","High","Low","Close","Vol")

# Consider SBER split to 1000 on 2007-07-18
#price.cl <- Cl(merge(c(price.ohlcv["/2007-07-17"]/1000, price.ohlc["2007-07-18/"])))
price.cl <- Cl(price.ohlcv)

# Convert to months. Could download months, but maybe days will be useful in future.
price.cl <- Cl(to.daily(price.cl))

# Up to 2017 for train
n = nrow(price.cl)
price.cl.train <- price.cl[1:round(0.7 * n)]
# 9 months for test
price.cl.test <- price.cl[(round(0.7 * n)+1):n]

# Analyze auto correlation:  ACF and PACF
acf2(na.omit(diff(log(price.cl.train))))

# Analyze acf2 for seasonality 
acf2(na.omit(diff(diff(log(price.cl.train)))))

# Fit the model, try different ar, i, ma
sarima(price.cl.train, p = 1, d = 1, q = 1, P = 0, D = 0, Q = 3, S = 12)

# Predict
price.cl.pred.raw <- sarima.for(price.cl, p = 1, d = 1, q = 1, P = 0, D = 0, Q = 3, S = 12, n.ahead=9)
price.cl.pred <- xts(price.cl.pred.raw$pred, timeBasedSeq("20180220/20180313"))

# Draw the plot
plot(merge(price.cl, price.cl.pred), type="n")
points(price.cl.train, col = "blue")
points(price.cl.pred, col = "red", lty=2)

