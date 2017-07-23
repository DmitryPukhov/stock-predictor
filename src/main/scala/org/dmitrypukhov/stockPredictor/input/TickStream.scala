package org.dmitrypukhov.stockPredictor.input

import org.apache.spark.streaming.dstream.DStream
import org.dmitrypukhov.stockPredictor.AppContext

/**
 * Stream of ticks. Emulate it from local file for debugging.
 */
class TickStream(val inputUri: String) {

  /**
   * Input stream with ticks
   */
  def getTickStream(): DStream[String] = {
    val inputUri = AppContext.config.getString("input.uri")
    AppContext.streamingContext.textFileStream(inputUri)
  }
}
