package org.dmitrypukhov.stockPredictor.input

import org.apache.spark.rdd.RDD
import org.apache.spark.streaming.dstream.DStream
import org.dmitrypukhov.stockPredictor.AppContext
import org.dmitrypukhov.stockPredictor.entity.Tick
import org.slf4j.LoggerFactory

import scala.collection.mutable.Queue

/**
 * Stream of ticks. Emulate it from local file for debugging.
 */
class TickStream extends Serializable {
  private val LOG = LoggerFactory.getLogger(this.getClass)

  private val tickParser = new TickParser



  /**
   * Input stream with ticks
   */
  def getTickStream(): DStream[Tick] = {
    val streamingContext = AppContext.streamingContext

    // Read text file as rdd and create a stream over it
    val inputUri = AppContext.config.getString("input.uri")
    streamingContext.textFileStream(inputUri)
    val fileRdd = streamingContext.sparkContext.textFile(inputUri).map(tickParser.parse).filter(_ != null)

    val q = Queue[RDD[Tick]](fileRdd)

    streamingContext.queueStream(q)
  }

}
