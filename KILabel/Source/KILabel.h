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


// Constants for identifying link types
typedef NS_ENUM(NSInteger, KILinkType)
{
    KILinkTypeUserHandle,
    KILinkTypeHashtag,
    KILinkTypeURL
};

// Constants for identifying link types we can detect
typedef NS_OPTIONS(NSUInteger, KILinkDetectionTypes)
{
    KILinkDetectionTypeUserHandle = (1 << 0),
    KILinkDetectionTypeHashtag = (1 << 1),
    KILinkDetectionTypeURL = (1 << 2),
    
    // Convenient constants
    KILinkDetectionTypeNone = 0,
    KILinkDetectionTypeAll = NSUIntegerMax
};



// Block method that is called when an interactive word is touched
typedef void (^KILinkTapHandler)(KILinkType linkType, NSString *string, NSRange range);



@interface KILabel : UILabel <NSLayoutManagerDelegate>

// Automatic detection of links, hashtags and usernames. When this is enabled links
// are coloured using the views tintColor property.
@property (nonatomic, assign, getter = isAutomaticLinkDetectionEnabled) BOOL automaticLinkDetectionEnabled;

@property (nonatomic, assign) KILinkDetectionTypes linkDetectionTypes;

// Colour used to hilight selected link background
@property (nonatomic, copy) UIColor *selectedLinkBackgroundColour;

// Get or set a block that is called when a link is touched
@property (nonatomic, copy) KILinkTapHandler linkTapHandler;

// Returns a dictionary of data about the link that it at the location. Returns
// nil if there is no link. A link dictionary contains the following keys:
//     @"linkType" a TDLinkType that identifies the type of link
//     @"range" the range of the link within the label text
//     @"link" the link text. This could be an URL, handle or hashtag depending on the linkType value
- (NSDictionary *)getLinkAtLocation:(CGPoint)location;

@end
