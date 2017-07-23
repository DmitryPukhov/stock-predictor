package org.dmitrypukhov.stockPredictor.input

import java.time.LocalDateTime

import org.scalatest.FunSuite

class TickParserTest extends FunSuite {

  val parser = new TickParser

  test("parseDateTime") {
    // Call
    val dateTime = parser.parseDateTime("20170723", "083910")

    // Check
    assert(dateTime.getYear == 2017)
    assert(dateTime.getMonthValue == 7)
    assert(dateTime.getDayOfMonth == 23)

    assert(dateTime.getHour == 8)
    assert(dateTime.getMinute == 39)
    assert(dateTime.getSecond == 10)
  }

  test("parse") {

    // Call
    val tick = parser.parse("SBER,0,20170721,095935,163.990000000,10")

    // Check
    val dateTime = LocalDateTime.of(2017, 7, 21, 9, 59, 35)
    assert(tick.time == dateTime)
    assert(tick.price == 163.99)
    assert(tick.volume == 10)

  }

  test("parse empty input") {
    var tick = parser.parse("")
    assert(tick == null)
  }

  test("parse null input") {
    var tick = parser.parse(null)
    assert(tick == null)
  }

  test("parse header") {
    // If input file contains header, it should not produce exception
    var tick = parser.parse("<TICKER>,<PER>,<DATE>,<TIME>,<LAST>,<VOL>")
    assert(tick == null)
  }
}
