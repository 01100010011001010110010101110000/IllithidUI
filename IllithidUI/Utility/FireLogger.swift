// Copyright (C) 2020 Tyler Gregory (@01100010011001010110010101110000)
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of  MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <http://www.gnu.org/licenses/>.

import Foundation

import Alamofire
import Willow

final class FireLogger: EventMonitor {
  // MARK: Lifecycle

  init(logger: Logger) {
    self.logger = logger
  }

  // MARK: Internal

  let queue = DispatchQueue(label: "com.flayware.IllithidUI.FireLogger", qos: .background)
  let logger: Logger

  func requestDidResume(_ request: Request) {
    logger.debugMessage("Request \(request.description) was resumed")
  }

  func requestDidFinish(_ request: Request) {
    logger.debugMessage("Request to \(request.description) finished")
  }

  func urlSession(_: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse) {
    logger.debugMessage("Request to \(dataTask.originalRequest?.description ?? "Unknown request") is being considered for caching: \(proposedResponse.storagePolicy)")
  }
}
