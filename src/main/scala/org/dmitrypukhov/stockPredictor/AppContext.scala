package org.dmitrypukhov.stockPredictor

import java.time.LocalDateTime

import com.typesafe.config.ConfigFactory
import org.apache.spark.SparkConf
import org.apache.spark.rdd.RDD
import org.apache.spark.sql.{Dataset, SparkSession}
import org.apache.spark.streaming.{Seconds, StreamingContext}
import org.dmitrypukhov.stockPredictor.entity.Tick

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

  /**
    * Spark session for datasets
    */
  val sparkSession = SparkSession.builder().getOrCreate()

  /**
    * Ticks storage
    */
  var ticks: Dataset[Tick] = sparkSession.createDataset(List[Tick]())

  private def newStreamingContext = {
    // Create streaming context
    val conf = new SparkConf().setMaster("local").setAppName("Predictor")
    new StreamingContext(conf, Seconds(1))
  }
}
