package org.dmitrypukhov.stockPredictor.process

import java.time.{LocalDateTime, ZoneOffset}
import java.time.temporal.TemporalField

import org.apache.spark.ml.classification.{ClassificationModel, MultilayerPerceptronClassificationModel, MultilayerPerceptronClassifier}
import org.apache.spark.rdd.RDD
import org.apache.spark.sql._
import org.apache.spark.sql.functions._
import org.apache.spark.streaming.dstream.DStream
import org.dmitrypukhov.stockPredictor.AppContext
import org.dmitrypukhov.stockPredictor.entity.Tick

import scala.collection.JavaConversions._
/**
  * Prediction process
  */
class Predictor {

  /** We preduct future based on past window of this duration */
  private val pastWindowDuration = AppContext.config.getDuration("predict.window.past")

  /** We preduct future for the nearest window of this duration  */
  private val futureWindowDuration = AppContext.config.getDuration("predict.window.future")


  /** Neural network trainer **/
  private val trainer = {
    // Get config
    val mlpcLayers = AppContext.config.getIntList("predict.mlpc.layers").toArray[Int]
    val maxIter = AppContext.config.getInt("predict.mlpc.maxIter")

    // Create mlpc
    new MultilayerPerceptronClassifier()
      .setLayers(mlpcLayers)
      .setMaxIter(maxIter)

  }

  /**
    * Trained model
    */
  private var model: MultilayerPerceptronClassificationModel = null


  /**
    * Predict nearest min and max using received ticks
    * @return Tuple with nearest low/high value. Low should happen before High
    */
  def predict(tickStream: DStream[Tick]): (Double, Double) = {

    // lowHigh to predict
    var lowHigh = (0.0,0.0)

    // Actually only last prediction matters
    // But usual situation is to have only 1 rdd in the stream,
    tickStream.foreachRDD(rdd => {

      // Update application ticks storage
      AppContext.ticks = AppContext.ticks.union(AppContext.sparkSession.createDataset[Tick](rdd)).sort("time")

      // Extract past ticks window for prediction
      val latestTickTime = AppContext.ticks.agg(max("time")).first()


      // Predict
      lowHigh = predict(AppContext.ticks, latestTickTime)
    })

    // Should contain prediction on the last rdd (usually only 1 rdd in the stream)
    lowHigh
  }

  /**
    * Train mlpc on ticks
    * @param ticks
    * @param latestTickTime
    */
  def train(ticks: Dataset[Tick], latestTickTime: LocalDateTime):(Double, Double) = {
      // We check our preduction when future happened
      // Past window was from pastWindowStart to futureWindowStart
      // Future window was from futureWindowStart to latestTickTime
      val pastWindowStart = latestTickTime.minus(pastWindowDuration.plus(futureWindowDuration))
      val futureWindowStart = latestTickTime.minus(futureWindowDuration)
    (0,0)


  }

  /**
    * Predict future using past ticks
    * @return Tuple with nearest low/high value. Low should happen before High
    */
  def predict(ticks: Dataset[Tick], latestTickTime: LocalDateTime): (Double, Double) = {

    // Extract past window
    val pastWindowStart = latestTickTime.minus(pastWindowDuration)
    val pastTicks = AppContext.ticks.filter(_.time.isAfter(pastWindowStart))
    val pastWindow = ticks.filter(_.time.isAfter(pastWindowStart))

    // Prepare input layer for the model
    // Possible problem: millis to double precision lost
    val input = ticks.flatMap(v => List(v.time.toInstant(ZoneOffset.UTC).toEpochMilli.toDouble, v.price, v.volume))

    // Predict
    val prediction = model.transform(input).collect()

    (prediction(0), prediction(1))
  }

}
