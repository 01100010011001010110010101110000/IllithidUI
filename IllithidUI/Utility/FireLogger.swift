//
// FireLogger
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 03/03/2020
//

import Foundation

import Alamofire
import Willow

final class FireLogger: EventMonitor {
  let queue = DispatchQueue(label: "com.flayware.IllithidUI.FireLogger", qos: .background)
  let logger: Logger

  init(logger: Logger) {
    self.logger = logger
  }

  func requestDidResume(_ request: Request) {
    logger.debugMessage("Request \(request.description) was resumed")
  }

  func requestDidFinish(_ request: Request) {
    logger.debugMessage("Request to \(request.description) finished")
  }

  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse) {
    logger.debugMessage("Request to \(dataTask.originalRequest?.description) is being considered for caching \(proposedResponse.storagePolicy)")
  }
}
