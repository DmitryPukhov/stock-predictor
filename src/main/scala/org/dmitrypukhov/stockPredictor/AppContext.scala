package org.dmitrypukhov.stockPredictor

import com.typesafe.config.ConfigFactory
import org.apache.spark.SparkConf
import org.apache.spark.streaming.{Seconds, StreamingContext}

/**
 * Application config, Spark context etc.
 * Common for the whole app.
 */
object AppContext {

  /**
   * Application config
   */
  val config = ConfigFactory.load()

  /**
   * SparkStreaming context
   */
  val streamingContext = newStreamingContext

  private def newStreamingContext = {
    // Create streaming context
    val conf = new SparkConf().setMaster("local").setAppName("Predictor")
    new StreamingContext(conf, Seconds(1))
  }
}
