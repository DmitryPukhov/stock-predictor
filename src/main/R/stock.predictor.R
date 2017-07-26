# Quantmod library
library("quantmod")

# Load ticks
ticks.path <- "../../../../data/SBER_170721_170722.csv"
ticks <- read.csv(ticks.path)


head(ticks)
