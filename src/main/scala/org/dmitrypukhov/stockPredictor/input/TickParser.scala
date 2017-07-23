package org.dmitrypukhov.stockPredictor.input

import java.time.format.DateTimeFormatter
import java.time.{LocalDate, LocalDateTime, LocalTime}

import org.dmitrypukhov.stockPredictor.entity.Tick
import org.slf4j.LoggerFactory

/**
 * Created by dima on 23/07/17.
 */
class TickParser extends Serializable {
  private lazy val dateFormatter = DateTimeFormatter.ofPattern("yyyyMMdd");
  private lazy val timeFormatter = DateTimeFormatter.ofPattern("HHmmss")
  private val LOG = LoggerFactory.getLogger(this.getClass)

  private[input] def parse(str: String): Tick = {
    // Create tick from string of format:
    //    <TICKER>,<PER>,<DATE>,<TIME>,<LAST>,<VOL>
    //     Example: SBER,0,20170721,095935,163.990000000,10
    var tick: Tick = null
    try {
      // Get fields
      val values = str.split(",")

      // Prepare values
      val ticker = values(0)
      val dateTime = parseDateTime(values(2), values(3))
      val price = values(4).toDouble
      val vol = values(5).toDouble

      // Create tick on parsed values
      tick = Tick(ticker = ticker, time = dateTime, price = price, volume = vol)

    } catch {
      case ex: Throwable => LOG.error(ex.toString)
    }
    tick
  }

  /**
   * Parse date and time from serialized fields
   * @return
   */
  private[input] def parseDateTime(strDate: String, strTime: String): LocalDateTime = {

    // Get date and time
    val date = LocalDate.parse(strDate, dateFormatter)
    val time = LocalTime.parse(strTime, timeFormatter)
    val dateTime = LocalDateTime.of(date, time)

    dateTime
  }
}
