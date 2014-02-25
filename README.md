# KILabel

A simple to use drop in replacement for UILabel for iOS 7 that hilights links such as URLs, twitter style usernames and hashtags and makes them tappable.

<img width=320 src="https://raw.github.com/Krelborn/KILabel/master/IKLabelDemoScreenshot.png" alt="KILabel Screenshot">

## How to use it in your project
KILabel doesn't have any special dependencies so just include the files from KILabel/Source in your project. Then use the KILabel class in place of UILabel.

1. Download the latest source.
2. Add the files KILabel.m and KILabel.h to your project.
3. Either:-
    * Design your user interface as you would normally. In Interface Builder set the custom class for any UILabel you want to replace to KILabel. The label should honour all IB settings. OR
    * Create KILabel objects in code.

## Things to know
* To handle taps on links you attach a block to the label's linkTapHandler property (See sample code).
* Usernames and hashtag links are coloured using the label's **tint** property. This can be configured through IB.
* URLs are attributed using the **NSLinkAttributeName** and are displayed accordingly.
* It should be possible to use either the label's **text** or **attributedText** properties to set the label content.
* When using the **attributedText** property, KILabel will attempt to preserve the original attributes as much as possilbe. If you see any problems with this let me know.
* The link hilighting and interaction can be enabled/disabled using the **automaticLinkDetectionEnabled** property.
* The constructor always sets *userInteractionEnabled* to YES. If you subsequently set it NO you will lose the ability to interact with links even it **automaticLinkDetectionEnabled** is set to YES.
* Use the **getLinkAtLocation** method to find out if there is link text at a point in the label's coordinate system. This returns nil if there is no link at the location, otherwise returns a dictionary with the following keys:
    * *linkType* a TDLinkType value that identifies the type of link
    * *range* an NSRange that gives the range of the link within the label's text
    * *link* an NSString containing the raw text of the link
* Use the *linkDetectionTypes* property to select the type of link you want tappable
* If you attach attributedText with existing links attached, they will be preserved, but only tappable if URL detection is enabled. This is handy for manually cleaning up displayed URLs while preserving the original link behind the scenes.

## A bit of sample code

The code snippet below show's how to setup a label with a tap handling block. A more complete example can be seen in the KILabelDemo project included in the repository.

``` objective-c
// Create the label, you can do this in Interface Builder as well
KILabel *label = [[KILabel alloc] initWithFrame:NSRectMake(20, 64, 280, 60)];
label.text = @"Follow @krelborn or visit http://matthewstyles.com #shamelessplug";

// Attach a block. This will get called when the user taps a link
label.linkTapHandler = ^(KILinkType linkType, NSString *string, NSRange range) {
    NSLog(@"User tapped %@", string);
};

[self.view addSubview:label];
```

## Demo

Repository includes KILabelDemo that shows a simple use of the label in a storyboard with examples for implementing tappable links.

The demo also demonstrates how to use a gesture recognizer with the label to implement a long press on a link, which uses the **getLinkAtLocation|** method.

## License & Credits

KILabel is available under the MIT license.

KILabel was inspired by STTweetLabel (http://github.com/SebastienThiebaud) and others such as NimbusAttributedLabel (http://latest.docs.nimbuskit.info/NimbusAttributedLabel.html). If KILabel can't help you, maybe they can.

## Contact

Please get in touch with any comments or report any bugs through the obvious channels.

- http://matthewstyles.com
- http://twitter.com/krelborn
- http://github.com/krelborn
