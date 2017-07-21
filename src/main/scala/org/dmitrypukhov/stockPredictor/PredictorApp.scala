package org.dmitrypukhov.stockPredictor


import org.apache.spark
import org.apache.spark.SparkConf
import org.apache.spark.sql.SparkSession
import org.apache.spark.streaming.{Seconds, StreamingContext}

/**
  * Application entry with main()
  */
object PredictorApp extends App {

  println("Predictor")

  // Create streaming context
  val conf = new SparkConf().setMaster("local").setAppName("Predictor")
  val ssc = new StreamingContext(conf, Seconds(1))

  // Create stream
  val inputDir = "data"
  val ds = ssc.textFileStream(inputDir)

  // Print data for test
  ds.print(10)

  // Start the app
  ssc.start()
  ssc.awaitTermination()
  ssc.stop()


}
