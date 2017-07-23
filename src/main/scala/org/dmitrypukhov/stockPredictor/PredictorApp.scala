package org.dmitrypukhov.stockPredictor


import org.dmitrypukhov.stockPredictor.input.TickStream
import org.slf4j.LoggerFactory

/**
  * Application entry with main()
  */
object PredictorApp extends App {

  LOG.info("------------------------------------------------")
  LOG.info("---       Tick predictor application      ------")
  LOG.info("------------------------------------------------")
  // Input
  val ds = new TickStream().getTickStream()
  private val LOG = LoggerFactory.getLogger(this.getClass)

  // Process
  // Print data for test
  ds.print(10)

  // Start the app
  AppContext.streamingContext.start()
  AppContext.streamingContext.awaitTermination()

}
