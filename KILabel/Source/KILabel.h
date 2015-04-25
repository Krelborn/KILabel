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

// Constants for identifying link types we can detect
typedef NS_ENUM(NSUInteger, KILinkType)
{
    KILinkTypeUserHandle,
    KILinkTypeHashtag,
    KILinkTypeURL,
};

// Flags for specifying combinations of link types as a bitmask
typedef NS_OPTIONS(NSUInteger, KILinkTypeOption)
{
    KILinkTypeOptionNone         = 0,
    
    KILinkTypeOptionUserHandle   = 1 << KILinkTypeUserHandle,
    KILinkTypeOptionHashtag      = 1 << KILinkTypeHashtag,
    KILinkTypeOptionURL          = 1 << KILinkTypeURL,
    
    KILinkTypeOptionAll          = NSUIntegerMax,
};


@class KILabel;

// Block method that is called when an interactive word is touched
typedef void (^KILinkTapHandler)(KILabel *label, NSString *string, NSRange range);

extern NSString * const KILabelLinkTypeKey;
extern NSString * const KILabelRangeKey;
extern NSString * const KILabelLinkKey;

/**
 * Smart UILabel subclass that detects links, hashtags and usernames.
 **/
@interface KILabel : UILabel <NSLayoutManagerDelegate>

/** ****************************************************************************************** **
 * @name Setting the link detector
 ** ****************************************************************************************** **/

/**
 * Automatic detection of links, hashtags and usernames.
 **/
@property (nonatomic, assign, getter = isAutomaticLinkDetectionEnabled) BOOL automaticLinkDetectionEnabled;

/**
 * The combination of link types to detect. Default value is KILinkTypeAll.
 **/
@property (nonatomic, assign) KILinkTypeOption linkDetectionTypes;

/**
 * Set containing words to be ignored as links, hashtags or usernames.
 * @discussion The comparison between the matches and the ignored words is case insensitive.
 **/
@property (nonatomic, strong) NSSet *ignoredKeywords;

/** ****************************************************************************************** **
 * @name Format & Appearance
 ** ****************************************************************************************** **/

/**
 * Color used to highlight selected link background. Default value is (0.95, 0.95, 0.95, 1.0).
 **/
@property (nonatomic, copy) UIColor *selectedLinkBackgroundColor;

/**
 * Flag to use the sytem format for URLs (underlined + blue color). Default value is NO.
 **/
@property (nonatomic, assign) BOOL systemURLStyle;

/**
 * Get the current attributes for the given link type.
 *
 * @param linkType The link type to get the attributes.
 * @return A dictionary of text attributes.
 * @discussion Default attributes contain colored font using the tintColor color property
 **/
- (NSDictionary*)attributesForLinkType:(KILinkType)linkType;

/**
 * Set the text attributes for each link type.
 *
 * @param attributes The text attributes.
 * @param linkType The link type.
 * @discussion Default attributes contain colored font using the tintColor color property.
 **/
- (void)setAttributes:(NSDictionary*)attributes forLinkType:(KILinkType)linkType;

/** ****************************************************************************************** **
 * @name Callbacks
 ** ****************************************************************************************** **/

/**
 * Callback block for KILinkTypeUserHandle link tap.
 **/
@property (nonatomic, copy) KILinkTapHandler userHandleLinkTapHandler;

/**
 * Callback block for KILinkTypeHashtag link tap.
 **/
@property (nonatomic, copy) KILinkTapHandler hashtagLinkTapHandler;

/**
 * Callback block for KILinkTypeURL link tap.
 **/
@property (nonatomic, copy) KILinkTapHandler urlLinkTapHandler;

/** ****************************************************************************************** **
 * @name Geometry
 ** ****************************************************************************************** **/

/**
 * Returns a dictionary of data about the link that it at the location. Returns nil if there is no link. 
 *
 * A link dictionary contains the following keys:
 *     KILabelLinkTypeKey: a TDLinkType that identifies the type of link.
 *     KILabelRangeKey: the range of the link within the label text.
 *     KILabelLinkKey: the link text. This could be an URL, handle or hashtag depending on the linkType value.
 *
 * @param point The point in the coordinates of the label view.
 * @return A dictionary containing the link.
 **/
- (NSDictionary*)linkAtPoint:(CGPoint)point;

@end
