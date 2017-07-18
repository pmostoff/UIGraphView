# UIGraphView

UIGraphView is a view type designed for iOS using the Swift programming language.

Designed to display a timeline of information:
- Past day by hour
- Past week by day
- Past month by day
- Past year by month

Can be modified to display different types of information sets.

## Features
- Easy installation with a single function to set up
- Customizable design through interface builder
- Automatically creates x-axis labels based on timeFrame passed and current date

### Installation
Simply add `UIGraphView.swift` to your Xcode project.

### Usage

Add `UIGraphView.swift` to your Xcode project.

Add a view to your view controller and set its class to UIGraphView.

Create an @IBOutlet of type UIGraphView and point it at the view:

```swift
@IBOutlet var graphView: UIGraphView!
```

To setup the graph information use `configure`:

```swift
graphView.configure(graphData: [Double],
                    graphTimeFrame: String,
                    graphTitle: String,
                    graphSubtitle: String,
                    latestEntry: String,
                    latestEntryTime: String)
```

`graphData` expects an array of Doubles and should automatically adjust placement of data points based on the amount of entries in the array.
`graphTimeFrame` expects a string of `Day`, `Week`, `Month`, or `Year`. If one of these strings is passed to `graphTimeFrame`, x-axis labels will be automatically created for you based on that time frame and the current date.
`graphTitle`, `graphSubtitle`, `latestEntry`, and `latestEntryTime` all expect String values.

While the graph should accept any length of `graphData` array, for the data points to properly line up with the x-axis labels you should use an array with a length appropriate for the `graphTimeFrame` you use:
- `Day` expects 24 entries
- `Week` expects 7 entries
- `Month` expects 31 entries
- `Year` expects 12 entries

### Interface Builder Designable
`UIGraphView` can be set up in Interface Builder. You can specify Graph Type (`barGraph`), Graph Corners (`cornerRounding`, `cornerRadius`), Graph Background Colors (`gradientTop`, `gradientBottom`), and Graph Information Colors (`graphLineColor`, `graphDataColor`, `graphFontColor`). All of these have default settings.

## Requirements
UIGraphView was built and tested using:
- iOS 10.3
- Xcode 8
- Swift 3 and 4

## License
`UIGraphView` is available under the MIT license. See the LICENSE file for more info.
