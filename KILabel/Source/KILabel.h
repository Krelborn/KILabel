/***********************************************************************************
 *
 * The MIT License (MIT)
 *
 * Copyright (c) 2013 Matthew Styles
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 ***********************************************************************************/

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Constants for identifying link types we can detect
 */
typedef NS_ENUM(NSUInteger, KILinkType)
{
    /**
     *  Usernames starting with "@" token
     */
    KILinkTypeUserHandle,
    
    /**
     *  Hashtags starting with "#" token
     */
    KILinkTypeHashtag,
    
    /**
     *  URLs, http etc
     */
    KILinkTypeURL,
};

/**
 *  Flags for specifying combinations of link types as a bitmask
 */
typedef NS_OPTIONS(NSUInteger, KILinkTypeOption)
{
    /**
     *  No links
     */
    KILinkTypeOptionNone = 0,
    
    /**
     *  Specifies to include KILinkTypeUserHandle links
     */
    KILinkTypeOptionUserHandle = 1 << KILinkTypeUserHandle,
    
    /**
     *  Specifies to include KILinkTypeHashtag links
     */
    KILinkTypeOptionHashtag = 1 << KILinkTypeHashtag,
    
    /**
     *  Specifies to include KILinkTypeURL links
     */
    KILinkTypeOptionURL = 1 << KILinkTypeURL,
    
    /**
     *  Convenience contstant to include all link types
     */
    KILinkTypeOptionAll = NSUIntegerMax,
};


@class KILabel;
@class KILabelLinkClassifier;

/**
 *  Type for block that is called when a link is tapped
 *
 *  @param label  The KILabel in which the tap took place
 *  @param string Content of the link that was tapped, includes @ or # tokens
 *  @param range  The range of the string within the label's text
 */
typedef void (^KILinkTapHandler)(KILabel *label, NSString *string, NSRange range);

/**
 *  Type for block that identifies and returns a list of links for the specified label
 *
 *  @param label Label requesting links
 *
 *  @return Array of Link Descriptor dictionaries
 */
typedef NSArray * __nonnull (^KILinkClassifier)(KILabel *label);

/**
 *  @name Link Descriptors
 *
 *  Currently a link descriptor is just an NSDictionary containing the keys below. Link descriptors
 *  identify individual links within the labels text.
 */

/**
 *  Key used to store KILinkType in a link descriptor dictionary
 */
extern NSString * const KILabelLinkTypeKey;

/**
 *  Key used to store NSRange for a link in a link descriptor dictionary
 */
extern NSString * const KILabelRangeKey;

/**
 *  Key used to store a copy of the original text that the link represents
 */
extern NSString * const KILabelLinkKey;

/**
 *  Key used to associate classifier with the link it generated
 */
extern NSString * const KILabelClassifierKey;

/**
 * A UILabel subclass that highlights links, hashtags and usernames and enables response to user
 * interactions with those links.
 **/
IB_DESIGNABLE
@interface KILabel : UILabel <NSLayoutManagerDelegate>

/**
 * @name Setting the link detector
 **/

/**
 * Enable/disable automatic detection of links, hashtags and usernames.
 */
@property (nonatomic, assign, getter = isAutomaticLinkDetectionEnabled) IBInspectable BOOL automaticLinkDetectionEnabled;

/**
 * Specifies the combination of link types to detect. Default value is KILinkTypeOptionAll.
 */
@property (nonatomic, assign) IBInspectable KILinkTypeOption linkDetectionTypes;

/**
 * Set containing words to be ignored as links, hashtags or usernames.
 *
 * @discussion The comparison between the matches and the ignored words is case insensitive.
 */
@property (nullable, nonatomic, strong) NSSet *ignoredKeywords;

/**
 * @name Format & Appearance
 **/

/**
 * The color used to highlight selected link background.
 *
 * @discussion The default value is (0.95, 0.95, 0.95, 1.0).
 */
@property (nullable, nonatomic, copy) IBInspectable UIColor *selectedLinkBackgroundColor;

/**
 * Flag sets if the sytem appearance for URLs should be used (underlined + blue color). Default value is NO.
 */
@property (nonatomic, assign) IBInspectable BOOL systemURLStyle;

/**
 * Get the current attributes for the given link type.
 *
 * @param linkType The link type to get the attributes.
 * @return A dictionary of text attributes.
 * @discussion Default attributes contain colored font using the tintColor color property.
 */
- (nullable NSDictionary*)attributesForLinkType:(KILinkType)linkType;

/**
 * Set the text attributes for each link type.
 *
 * @param attributes The text attributes.
 * @param linkType The link type.
 * @discussion Default attributes contain colored font using the tintColor color property.
 */
- (void)setAttributes:(nullable NSDictionary*)attributes forLinkType:(KILinkType)linkType;

/**
 * @name Callbacks
 **/

/**
 * Callback block for KILinkTypeUserHandle link tap.
 **/
@property (nullable, nonatomic, copy) KILinkTapHandler userHandleLinkTapHandler;

/**
 * Callback block for KILinkTypeHashtag link tap.
 */
@property (nullable, nonatomic, copy) KILinkTapHandler hashtagLinkTapHandler;

/**
 * Callback block for KILinkTypeURL link tap.
 */
@property (nullable, nonatomic, copy) KILinkTapHandler urlLinkTapHandler;

/**
 *  @name Classifiers
 */

/**
 *  Adds a link classifier, which will detect links and optionally handle taps.
 *
 *  @param classifier KILinkClassifier block (see documentation)
 */
- (void)addLinkClassifier:(KILabelLinkClassifier *)classifier;

/**
 *  Removes a link classifier, it will no longer detect links or handle taps.
 *
 *  @param classifier KILabelLinkClassifer to remove
 */
- (void)removeLinkClassifier:(KILabelLinkClassifier *)classifier;

/**
 *  Finds the first link classifier with the specified tag.
 *
 *  Useful for modifiying classifiers after attached to the label. Using tags means you can avoid
 *  holding on to references to the objects. Will only return the first instance with the tag, 
 *  there's no restrictions on tags being unique so it's up to the developer to manage this.
 *
 *  @param tag Tag used to match classifier
 *
 *  @return KILabelLinkClassifier with tag or nil if no classifier exists.
 */
- (KILabelLinkClassifier *)linkClassifierWithTag:(NSInteger)tag;

/**
 * @name Geometry
 **/

/**
 * Returns a dictionary of data about the link that it at the location. Returns nil if there is no link.
 *
 * A link dictionary contains the following keys:
 *
 * - **KILabelLinkTypeKey**, a TDLinkType that identifies the type of link.
 * - **KILabelRangeKey**, the range of the link within the label text.
 * - **KILabelLinkKey**, the link text. This could be an URL, handle or hashtag depending on the linkType value.
 *
 * @param point The point in the coordinates of the label view.
 * @return A dictionary containing the link.
 */
- (nullable NSDictionary*)linkAtPoint:(CGPoint)point;

@end

#pragma mark - KILabelLinkClassifier

/**
 *  KILabelLinkClassifier objects can be attached to KILabel instances. They define a link detector
 *  associated with a touch handler callback.
 */
@interface KILabelLinkClassifier: NSObject

/**
 *  An application defined tag. Useful for managing classifiers without having to hold on to 
 *  references to their instances.
 */
@property NSInteger tag;

/**
 *  Block used to detect links for the label. If this is nil the classifier won't do anything.
 */
@property (nullable, nonatomic, copy) KILinkClassifier classifier;

/**
 *  Block called when a link detected by the classifier is tapped. Leave nil if you don't want to
 *  handle taps.
 */
@property (nullable, nonatomic, copy) KILinkTapHandler tapHandler;

/**
 *  The attributes for the links attributes string
 */
@property (nullable, nonatomic, copy) NSDictionary *linkAttributes;

/**
 *  Create a new instance of KILabelLinkClassifer with the given classifier block
 *
 *  @param classifier Block that will used to classify links in the parent label
 *
 *  @return Instance of KILabelLinkClassifier
 */
- (instancetype)initWithClassifier:(KILinkClassifier)classifier;

/**
 *  Create a new instance of KILabelLinkClassifier that will use the given regex for classifying
 *
 *  @param regex Regex used to match strings for links
 *
 *  @return Instance of KILabelLinkClassifier
 */
+ (instancetype)linkClassifierWithRegex:(NSRegularExpression *)regex;

/**
 *  Helper method for extracting the string to use as the "link" from an attributed string. The
 *  plain text matching the range will be used, unless an NSLinkAttributedName property is present.
 *  See linkClassifierWithRegex: for an example.
 *
 *  @param attrStr String to extract link from
 *  @param range   Range of characters for the link in the plain text of the string
 *
 *  @return String to use a link string.
 */
+ (NSString *)linkStringFromAttributedString:(NSAttributedString *)attrStr withRange:(NSRange)range;

@end

NS_ASSUME_NONNULL_END
