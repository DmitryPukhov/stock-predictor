package org.dmitrypukhov.stockPredictor.entity

import java.time.LocalDateTime

/**
 * Price and vol tick
 */
case class Tick(ticker: String, time: LocalDateTime, price: Double, volume: Double) {

}
