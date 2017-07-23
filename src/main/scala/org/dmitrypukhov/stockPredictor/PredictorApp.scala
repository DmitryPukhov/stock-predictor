package org.dmitrypukhov.stockPredictor


import org.dmitrypukhov.stockPredictor.input.TickStream

/**
  * Application entry with main()
  */
object PredictorApp extends App {

  println("Predictor")

  val ds = new TickStream("data").getTickStream()



  // Print data for test
  ds.print(10)

  // Start the app
  AppContext.streamingContext.start()
  AppContext.streamingContext.awaitTermination()

}
