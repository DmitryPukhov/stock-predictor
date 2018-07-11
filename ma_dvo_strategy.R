######################################################
# Quantstrat strategy MA + oscillator
######################################################
#######################################################
# Prepare boilerplate
library(curl)
library(devtools)
library(quantmod)
library(quantstrat)

# Three Important Dates
initdate="1999-01-01"
from = "2003-01-01"
to = "2015-12-31"

#Seting up quantstrat
Sys.setenv(TZ="UTC")
currency("USD")

# Set  instruments
getSymbols("LQD",from=from, to=to, src="yahoo", adjust=TRUE)
getSymbols("SPY", from=from, to=to, src="yahoo", adjust=TRUE)
stock("LQD", currency="USD", multiplier=1)

# Trade Size and Initial Equity
tradesize <- 100000
initeq <- 100000

# Naming and Removing Strategies
strategy.st <- portfolio.st <- account.st <- "mastrat"
rm.strat(strategy.st)

#Initialize portfolio, account, orders
initPortf(portfolio.st, symbols="LQD", initDate=initdate, currency="USD")
initAcct(account.st, portfolios=portfolio.st, initDate=initdate, currency="USD",initEq=initeq)
initOrders(portfolio.st, initDate=initdate)
strategy(strategy.st, store=TRUE)

##############################3
# DVO indicator
DVO <- function(x, navg = 2, percentlookback = 126) {
  HLC <- x
  # Compute the ratio between closing prices to the average of high and low
  ratio <- Cl(HLC)/((Hi(HLC) + Lo(HLC))/2)
  
  # Smooth out the ratio outputs using a moving average
  avgratio <- SMA(ratio, n = navg)
  
  # Convert ratio into a 0-100 value using runPercentRank()
  out <- runPercentRank(avgratio, n = percentlookback, exact.multiplier = 1) * 100
  colnames(out) <- "DVO"
  return(out)
}
###################### 
# Add indicators

# SMA200 indicator
add.indicator(strategy = strategy.st,
              name="SMA",
              arguments=list(x=quote(Cl(mktdata)), 
                             n=200),
              label="SMA200")
# SMA50 indicator
add.indicator(strategy=strategy.st,
              name="SMA",
              arguments=list(x=quote(Cl(mktdata)),
                             n=50),
              label="SMA50")
# RSI3 indicator
add.indicator(strategy=strategy.st,
              name="SMA",
              arguments=list(x=quote(Cl(mktdata)), 
                             n=3),
              label="RSI3")
# DVO_2_126 indicator
add.indicator(strategy=strategy.st,
              name="DVO",
              arguments=list(x=quote(HLC(mktdata)),
                             navg=2,
                             percentlookback=126),
              label="DVO_2_126")
# Test all indicators
test<-applyIndicators(strategy=strategy.st, mktdata=OHLC(SPY))

#######################################
# Add signals

# Long filter signal - sma50 over sma200
add.signal(strategy.st,
           name="sigComparison",
           arguments=list(columns=c("SMA50","SMA200"),
                          relationship="gt"),
           label="longfilter")
# Exit signal - sma50 grosses sma200 updown
add.signal(strategy.st,
           name="sigCrossover",
           arguments=list(columns=c("SMA50","SMA200"),
                          relationship="lt"),
           label="filterexit")

# Long Threshold signal - dvo_2_126 < 20 - 
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

################################
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
chart.Posn(portfolio.st, Symbol="LQD")
sma50 <- SMA(x=Cl(SPY), n=50)
sma200 <- SMA(x=Cl(SPY), n=200)
dvo_2_126 <- DVO(x=HLC(SPY), navg=2, percentlookback = 126)
add_TA(sma50, on=1, col="blue")
add_TA(sma200, on=1, col="red")
add_TA(dvo_2_126)
zoom_Chart("2006-01/2006-12")

# Additional analysis
instrets <- PortfReturns(portfolio.st)
SharpeRatio.annualized(instrets, geometric=FALSE)
