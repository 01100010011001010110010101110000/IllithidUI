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

/// A provider of metadata related to a media item, e.g. an image or video
protocol MediaMetadataProvider {
  /// The media item's title
  var mediaTitle: String { get }
  /// The description of the media item on its host
  var mediaDescription: String? { get }
  /// The number of upvotes the media item has on its host
  var upvotes: Int? { get }
  /// The number of downvotes the media item has on its host
  var downvotes: Int? { get }
  /// The display name of the media's host, e.g. `GfyCat`, or `YouTube`
  var hostDisplayName: String { get }
  /// The number of views the media item has gotten on its host
  var views: Int { get }
  /// The URL of the media's image source, if there is one
  var imageUrl: URL? { get }
  /// The URL of the media's MP4 source, if there is one
  var mp4Url: URL? { get }
  /// The URL of the media's image source, if there is one
  var gifUrl: URL? { get }
  /// The size of the media
  var size: CGSize { get }
}
