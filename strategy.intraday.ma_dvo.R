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
require(quantstrat)
# DVO indicator
source("indicator.dvo.R")

# Three Important Dates
initdate="1999-01-01"
from = "2018-01-03"
to = "2018-03-13"

#Seting up quantstrat
Sys.setenv(TZ="UTC")
currency("USD")

# Set  instruments
#getSymbols("SPY", from=from, to=to, src="yahoo", adjust=TRUE)

url <- getURL("https://raw.githubusercontent.com/DmitryPukhov/stock-predictor/master/data/RI.RTSI_180101_180313.csv")
RTSI <- read.csv(textConnection(url))
RTSI <- RTSI[-c(1:2)]
RTSI = as.xts(read.zoo(RTSI, index.column=c(1,2), tz="UTC", format="%Y%m%d%H:%M:%S"))
names(RTSI) <- c("Open","High","Low","Close","Vol")
SYMBOL.name="RTSI"
SYMBOL.data=RTSI
stock(SYMBOL.name, currency="USD", multiplier=1)

# Trade Size and Initial Equity
tradesize <- 1000
initeq <- 1000

# Naming and Removing Strategies
strategy.st <- portfolio.st <- account.st <- "ma_dvo"
rm.strat(strategy.st)

#Initialize portfolio, account, orders
initPortf(portfolio.st, symbols=SYMBOL.name, initDate=initdate, currency="USD")
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
test<-applyIndicators(strategy=strategy.st, mktdata=OHLC(SYMBOL.data))

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
test_init <- applyIndicators(strategy = strategy.st, mktdata=OHLC(SYMBOL.data))
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
chart.Posn(portfolio.st, Symbol=SYMBOL.name)
SMA_FAST <- SMA(x=Cl(SYMBOL.data), n=15)
SMA_QUICK <- SMA(x=Cl(SYMBOL.data), n=480)
DVO_2_126 <- DVO(x=HLC(SYMBOL.data), navg=2, percentlookback = 126)
add_TA(SMA_FAST, on=1, col="blue")
add_TA(SMA_QUICK, on=1, col="red")
add_TA(DVO_2_126)
zoom_Chart("2018-02-03/2018-02-05")
zoom_Chart("2018-01-03/2018-01-04")

# Additional analysis
instrets <- PortfReturns(portfolio.st)
SharpeRatio.annualized(instrets, geometric=FALSE)
