package org.dmitrypukhov.stockPredictor


import org.dmitrypukhov.stockPredictor.input.TickStream
import org.dmitrypukhov.stockPredictor.process.Predictor
import org.slf4j.LoggerFactory

/**
  * Application entry with main()
  */
object PredictorApp extends App {

  private val LOG = LoggerFactory.getLogger(this.getClass)

  LOG.info("------------------------------------------------")
  LOG.info("---       Tick predictor application      ------")
  LOG.info("------------------------------------------------")

  // Input
  val ticks = new TickStream().getTickStream()

  // Predict nearest low-high pair
  val prediction = new Predictor().predict(ticks)


  // Process
  // Print data for test
  ds.print(10)

  // Start the app
  AppContext.streamingContext.start()
  AppContext.streamingContext.awaitTermination()

}
