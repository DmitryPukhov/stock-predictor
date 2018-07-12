######################################################
# Quantstrat strategy MA + oscillator
######################################################

#######################################################
# Prepare boilerplate
require(dplyr)
require(curl)
library(utils)
require(RCurl)
require(devtools)
require(quantmod)
require(FinancialInstrument)
require(PerformanceAnalytics)
require(blotter)
require(quantstrat)
# DVO indicator
source("indicator.dvo.R")

# Three Important Dates
initdate="1999-01-01"
from = "2003-01-01"
to = "2015-12-31"

#Seting up quantstrat
Sys.setenv(TZ="UTC")
currency("USD")

# Set  instruments
getSymbols("SPY", from=from, to=to, src="yahoo", adjust=TRUE)

#url <- getURL("https://raw.githubusercontent.com/DmitryPukhov/stock-predictor/master/data/RI.RTSI_180101_180313.csv")
#price.csv <- read.csv(textConnection(url))
#price.csv <- price.csv[-c(1:2)]
#price.ohlcv = as.xts(read.zoo(price.csv, index.column=c(1,2), tz="UTC", format="%Y%m%d%H:%M:%S"))
#names(price.ohlcv) <- c("Open","High","Low","Close","Vol")


stock("SPY", currency="USD", multiplier=1)

# Trade Size and Initial Equity
tradesize <- 100000
initeq <- 100000

# Naming and Removing Strategies
strategy.st <- portfolio.st <- account.st <- "ma_dvo"
rm.strat(strategy.st)

#Initialize portfolio, account, orders
initPortf(portfolio.st, symbols="SPY", initDate=initdate, currency="USD")
initAcct(account.st, portfolios=portfolio.st, initDate=initdate, currency="USD",initEq=initeq)
initOrders(portfolio.st, initDate=initdate)
strategy(strategy.st, store=TRUE)

####################################################### 
# Add indicators

# SMA_QUICK indicator
add.indicator(strategy = strategy.st,
              name="SMA",
              arguments=list(x=quote(Cl(mktdata)), 
                             n=200),
              label="SMA_QUICK")
# SMA_FAST indicator
add.indicator(strategy=strategy.st,
              name="SMA",
              arguments=list(x=quote(Cl(mktdata)),
                             n=50),
              label="SMA_FAST")

add.indicator(strategy=strategy.st,
              name="DVO",
              arguments=list(x=quote(HLC(mktdata)),
                             navg=2,
                             percentlookback=126),
              label="DVO_2_126")
# Test all indicators
test<-applyIndicators(strategy=strategy.st, mktdata=OHLC(SYMBOL))

#######################################
# Add signals

# Long filter signal - SMA_FAST over SMA_QUICK
add.signal(strategy.st,
           name="sigComparison",
           arguments=list(columns=c("SMA_FAST","SMA_QUICK"),
                          relationship="gt"),
           label="longfilter")
# Exit signal - SMA_FAST grosses SMA_QUICK updown
add.signal(strategy.st,
           name="sigCrossover",
           arguments=list(columns=c("SMA_FAST","SMA_QUICK"),
                          relationship="lt"),
           label="filterexit")

# Long Threshold signal - DVO < 20 - 
add.signal(strategy.st,
           name="sigThreshold",
           arguments=list(column="DVO_2_126",
                          threshold=20,
                          relationship="lt",
                          # We're interested in every instance that the oscillator is less than 20
                          cross=FALSE),
           label="longthreshold")
#  Exit threshold
add.signal(strategy.st,
           name="sigThreshold",
           arguments=list(column="DVO_2_126",
                          threshold=80,
                          relationship="gt",
                          cross=TRUE),
           label="thresholdexit")
add.signal(strategy.st,
           name="sigFormula",
           arguments=list(formula="longfilter & longthreshold",
                          cross=TRUE),
           label="longentry")
# Test datasets
test_init <- applyIndicators(strategy = strategy.st, mktdata=OHLC(SPY))
test <- applySignals(strategy = strategy.st, mktdata=test_init)

#######################################################
# Init rules
add.rule(strategy.st, 
         name="ruleSignal",
         arguments=list(sigcol="filterexit",
                        sigval=TRUE,
                        orderqty="all",
                        ordertype="market",
                        orderside="long",
                        replace=FALSE,
                        prever="Open"),
         type="exit")
add.rule(strategy.st,
         name="ruleSignal",
         arguments=list(sigcol="longentry",
                        sigval=TRUE,
                        orderqty=1,
                        ordertype="market",
                        orderside="long",
                        # Do not replace other signals
                        replace=FALSE,
                        # Buy at the next day's opening price
                        prefer="Open"),
         type="enter")

#################################################
# Run
applyStrategy(strategy=strategy.st, portfolios = portfolio.st)
updatePortf(portfolio.st)
daterange <- time(getPortfolio(portfolio.st)$summary)[-1]
updateAcct(account.st, daterange)
updateEndEq(account.st)


###################################################
# Analyze

# Get trade statistics
tstats <- tradeStats(Portfolios = portfolio.st)
tail(tstats)

# Positions chart
chart.Posn(portfolio.st, Symbol="SPY")
SMA_FAST <- SMA(x=Cl(SPY), n=50)
SMA_QUICK <- SMA(x=Cl(SPY), n=200)
DVO <- DVO(x=HLC(SPY), navg=2, percentlookback = 126)
add_TA(SMA_FAST, on=1, col="blue")
add_TA(SMA_QUICK, on=1, col="red")
add_TA(DVO)
zoom_Chart("2006-01/2006-12")

# Additional analysis
instrets <- PortfReturns(portfolio.st)
SharpeRatio.annualized(instrets, geometric=FALSE)
