package org.dmitrypukhov.stockPredictor


import org.apache.spark.sql.SparkSession

/**
  * Application entry with main()
  */
object PredictorApp extends App {

  println("Test")
  val spark = SparkSession.builder.master("local").appName("Predictor").getOrCreate()
  import spark.implicits._
  val ds = spark.createDataset(List("aaa","bbb","ccc"))
  println(ds.collect.mkString(","))
  spark.stop()


}
