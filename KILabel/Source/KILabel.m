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

#import "KILabel.h"

NSString * const KILabelLinkTypeKey = @"linkType";
NSString * const KILabelRangeKey = @"range";
NSString * const KILabelLinkKey = @"link";
NSString * const KILabelClassifierKey = @"classifier";

#pragma mark - Private Interface

@interface KILabel()

// Used to control layout of glyphs and rendering
@property (nonatomic, retain) NSLayoutManager *layoutManager;

// Specifies the space in which to render text
@property (nonatomic, retain) NSTextContainer *textContainer;

// Backing storage for text that is rendered by the layout manager
@property (nonatomic, retain) NSTextStorage *textStorage;

// Dictionary of detected links and their ranges in the text
@property (nonatomic, copy) NSArray *linkRanges;

// State used to trag if the user has dragged during a touch
@property (nonatomic, assign) BOOL isTouchMoved;

// During a touch, range of text that is displayed as selected
@property (nonatomic, assign) NSRange selectedRange;

@end

#pragma mark - Implementation

@implementation KILabel
{
    // Link classifiers for handling link detection and interaction
    NSMutableArray *_linkClassifiers;
    
    // Built in classifiers used when working with KILinkType based links
    KILabelLinkClassifier *_userHandleClassifier;
    KILabelLinkClassifier *_hashtagClassifier;
    KILabelLinkClassifier *_urlClassifier;
}

#pragma mark - Construction

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setupTextSystem];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self setupTextSystem];
    }
    
    return self;
}

// Common initialisation. Must be done once during construction.
- (void)setupTextSystem
{
    // Create a text container and set it up to match our label properties
    _textContainer = [[NSTextContainer alloc] init];
    _textContainer.lineFragmentPadding = 0;
    _textContainer.maximumNumberOfLines = self.numberOfLines;
    _textContainer.lineBreakMode = self.lineBreakMode;
    _textContainer.size = self.frame.size;
    
    // Create a layout manager for rendering
    _layoutManager = [[NSLayoutManager alloc] init];
    _layoutManager.delegate = self;
    [_layoutManager addTextContainer:_textContainer];
    
    // Attach the layou manager to the container and storage
    [_textContainer setLayoutManager:_layoutManager];
    
    // Make sure user interaction is enabled so we can accept touches
    self.userInteractionEnabled = YES;
    
    // Don't go via public setter as this will have undesired side effect
    _automaticLinkDetectionEnabled = YES;
    
    // All links are detectable by default
    _linkDetectionTypes = KILinkTypeOptionAll;
    
    // Storage for classifiers
    _linkClassifiers = [[NSMutableArray alloc] init];
    
    // Don't underline URL links by default.
    _systemURLStyle = NO;
    
    // By default we hilight the selected link during a touch to give feedback that we are
    // responding to touch.
    _selectedLinkBackgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    
    [self setupLinkClassifiers];
    
    // Establish the text store with our current text
    [self updateTextStoreWithText];
}

#pragma mark - Builtin Classifiers and Tap Handlers

// Create default classifiers
- (void)setupLinkClassifiers
{
    _userHandleClassifier = [KILabelLinkClassifier linkClassifierWithRegex:[self userHandleRegex]];
    _hashtagClassifier = [KILabelLinkClassifier linkClassifierWithRegex:[self hashtagRegex]];

    // Use a data detector to find urls in the text
    NSError *error = nil;
    NSDataDetector *detector = [[NSDataDetector alloc] initWithTypes:NSTextCheckingTypeLink error:&error];
    _urlClassifier = [KILabelLinkClassifier linkClassifierWithLinkAndRegex:detector];

    // Make sure the required link classifiers are attached
    [self updateDefaultLinkClassifiers];
}

// Gets Regex that defines user handles
- (NSRegularExpression *)userHandleRegex
{
    static NSRegularExpression *regex = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *error = nil;
        regex = [[NSRegularExpression alloc] initWithPattern:@"(?<!\\w)@([\\w\\_]+)?" options:0 error:&error];
    });

    return regex;
}

// Gets Regex that defines hashtags
- (NSRegularExpression *)hashtagRegex
{
    // Setup a regular expression for hashtags
    static NSRegularExpression *regex = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *error = nil;
        regex = [[NSRegularExpression alloc] initWithPattern:@"(?<!\\w)#([\\w\\_]+)?" options:0 error:&error];
    });

    return regex;
}

- (void)setUserHandleLinkTapHandler:(KILinkTapHandler __nullable)userHandleLinkTapHandler
{
    _userHandleClassifier.tapHandler = userHandleLinkTapHandler;
}

- (KILinkTapHandler __nullable)userHandleLinkTapHandler
{
    return _userHandleClassifier.tapHandler;
}

- (void)setHashtagLinkTapHandler:(KILinkTapHandler __nullable)hashtagLinkTapHandler
{
    _hashtagClassifier.tapHandler = hashtagLinkTapHandler;
}

- (KILinkTapHandler __nullable)hashtagLinkTapHandler
{
    return _hashtagClassifier.tapHandler;
}

- (void)setUrlLinkTapHandler:(KILinkTapHandler __nullable)urlLinkTapHandler
{
    _urlClassifier.tapHandler = urlLinkTapHandler;
}

- (KILinkTapHandler __nullable)urlLinkTapHandler
{
    return _urlClassifier.tapHandler;
}

- (void)setAutomaticLinkDetectionEnabled:(BOOL)decorating
{
    _automaticLinkDetectionEnabled = decorating;
    
    // Make sure the text is updated properly
    [self updateTextStoreWithText];
}

- (void)setLinkDetectionTypes:(KILinkTypeOption)linkDetectionTypes
{
    _linkDetectionTypes = linkDetectionTypes;
    
    // Attach or remove the classifiers for default links
    [self updateDefaultLinkClassifiers];
    
    // Make sure the text is updated properly
    [self updateTextStoreWithText];
}

// Adds or removes default classifiers based on the flags in the linkDetectionTypes
- (void)updateDefaultLinkClassifiers
{
    if (self.linkDetectionTypes & KILinkTypeOptionUserHandle)
    {
        [self addLinkClassifier:_userHandleClassifier];
    }
    else
    {
        [self removeLinkClassifier:_userHandleClassifier];
    }
    
    if (self.linkDetectionTypes & KILinkTypeOptionHashtag)
    {
        [self addLinkClassifier:_hashtagClassifier];
    }
    else
    {
        [self removeLinkClassifier:_hashtagClassifier];
    }
    
    if (self.linkDetectionTypes & KILinkTypeOptionURL)
    {
        [self addLinkClassifier:_urlClassifier];
    }
    else
    {
        [self removeLinkClassifier:_urlClassifier];
    }
}

#pragma mark - Custom Link Classifiers Management

- (void)addLinkClassifier:(KILabelLinkClassifier *)classifier
{
    // Don't allow multiple adds of the same object
    if ([_linkClassifiers containsObject:classifier])
    {
        return;
    }

    [_linkClassifiers addObject:classifier];

    [self updateTextStoreWithText];
}

- (void)removeLinkClassifier:(KILabelLinkClassifier *)classifier
{
    // Prevent a change if there's nothing to remove
    if (![_linkClassifiers containsObject:classifier])
    {
        return;
    }

    [_linkClassifiers removeObject:classifier];

    [self updateTextStoreWithText];
}

- (KILabelLinkClassifier *)linkClassifierWithTag:(NSInteger)tag
{
    for (KILabelLinkClassifier *classifier in _linkClassifiers)
    {
        // Only return if the tag matches and its not one of our built in ones.
        if ((classifier.tag == tag) && [self isCustomClassifier:classifier])
        {
            return classifier;
        }
    }

    return nil;
}

- (BOOL)isCustomClassifier:(KILabelLinkClassifier *)classifier
{
    return (classifier != _userHandleClassifier) &&
    (classifier != _hashtagClassifier) &&
    (classifier != _urlClassifier);
}

#pragma mark - Text and Style Management

- (NSDictionary *)linkAtPoint:(CGPoint)location
{
    // Do nothing if we have no text
    if (_textStorage.string.length == 0)
    {
        return nil;
    }
    
    // Work out the offset of the text in the view
    CGPoint textOffset = [self calcGlyphsPositionInView];
    
    // Get the touch location and use text offset to convert to text cotainer coords
    location.x -= textOffset.x;
    location.y -= textOffset.y;
    
    NSUInteger touchedChar = [_layoutManager glyphIndexForPoint:location inTextContainer:_textContainer];
    
    // If the touch is in white space after the last glyph on the line we don't
    // count it as a hit on the text
    NSRange lineRange;
    CGRect lineRect = [_layoutManager lineFragmentUsedRectForGlyphAtIndex:touchedChar effectiveRange:&lineRange];
    if (CGRectContainsPoint(lineRect, location) == NO)
        return nil;
    
    // Find the word that was touched and call the detection block
    for (NSDictionary *dictionary in self.linkRanges)
    {
        NSRange range = [[dictionary objectForKey:KILabelRangeKey] rangeValue];
        
        if ((touchedChar >= range.location) && touchedChar < (range.location + range.length))
        {
            return dictionary;
        }
    }
    
    return nil;
}

// Applies background color to selected range. Used to hilight touched links
- (void)setSelectedRange:(NSRange)range
{
    // Remove the current selection if the selection is changing
    if (self.selectedRange.length && !NSEqualRanges(self.selectedRange, range))
    {
        [_textStorage removeAttribute:NSBackgroundColorAttributeName range:self.selectedRange];
    }
    
    // Apply the new selection to the text
    if (range.length && _selectedLinkBackgroundColor != nil)
    {
        [_textStorage addAttribute:NSBackgroundColorAttributeName value:_selectedLinkBackgroundColor range:range];
    }
    
    // Save the new range
    _selectedRange = range;
    
    [self setNeedsDisplay];
}

- (void)setNumberOfLines:(NSInteger)numberOfLines
{
    [super setNumberOfLines:numberOfLines];
    
    _textContainer.maximumNumberOfLines = numberOfLines;
}

- (void)setText:(NSString *)text
{
    // Pass the text to the super class first
    [super setText:text];
    
    // Update our text store with an attributed string based on the original
    // label text properties.
    if (!text)
    {
        text = @"";
    }
    
    NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:text attributes:[self attributesFromProperties]];
    [self updateTextStoreWithAttributedString:attributedText];
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
    if(!attributedText)
    {
      attributedText = [[NSAttributedString alloc] initWithString:@"" attributes:[self attributesFromProperties]];
    }

    // Pass the text to the super class first
    [super setAttributedText:attributedText];
    
    [self updateTextStoreWithAttributedString:attributedText];
}

- (void)setSystemURLStyle:(BOOL)systemURLStyle
{
    _systemURLStyle = systemURLStyle;
    
    // Force refresh
    self.text = self.text;
}

- (NSDictionary*)attributesForLinkType:(KILinkType)linkType
{
    NSDictionary *attributes = [self classifierForLinkType:linkType].linkAttributes;
    
    if (!attributes)
    {
        attributes = @{NSForegroundColorAttributeName : self.tintColor};
    }
    
    return attributes;
}

- (void)setAttributes:(NSDictionary*)attributes forLinkType:(KILinkType)linkType
{
    [self classifierForLinkType:linkType].linkAttributes = attributes;
    
    // Force refresh text
    self.text = self.text;
}

- (KILabelLinkClassifier *)classifierForLinkType:(KILinkType)linkType
{
    switch (linkType)
    {
        case KILinkTypeUserHandle:
            return _userHandleClassifier;
            
        case KILinkTypeHashtag:
            return _hashtagClassifier;

        case KILinkTypeURL:
            return _urlClassifier;
    }
    
    return nil;
}

#pragma mark - Text Storage Management

- (void)updateTextStoreWithText
{
    // Now update our storage from either the attributedString or the plain text
    if (self.attributedText)
    {
        [self updateTextStoreWithAttributedString:self.attributedText];
    }
    else if (self.text)
    {
        [self updateTextStoreWithAttributedString:[[NSAttributedString alloc] initWithString:self.text attributes:[self attributesFromProperties]]];
    }
    else
    {
        [self updateTextStoreWithAttributedString:[[NSAttributedString alloc] initWithString:@"" attributes:[self attributesFromProperties]]];
    }
    
    [self setNeedsDisplay];
}

- (void)updateTextStoreWithAttributedString:(NSAttributedString *)attributedString
{
    if (attributedString.length != 0)
    {
        attributedString = [KILabel sanitizeAttributedString:attributedString];
    }
    
    if (self.isAutomaticLinkDetectionEnabled && (attributedString.length != 0))
    {
        self.linkRanges = [self getRangesForLinks:attributedString];
        attributedString = [self addLinkAttributesToAttributedString:attributedString linkRanges:self.linkRanges];
    }
    else
    {
        self.linkRanges = nil;
    }
    
    if (_textStorage)
    {
        // Set the string on the storage
        [_textStorage setAttributedString:attributedString];
    }
    else
    {
        // Create a new text storage and attach it correctly to the layout manager
        _textStorage = [[NSTextStorage alloc] initWithAttributedString:attributedString];
        [_textStorage addLayoutManager:_layoutManager];
        [_layoutManager setTextStorage:_textStorage];
    }
}

// Returns attributed string attributes based on the text properties set on the label.
// These are styles that are only applied when NOT using the attributedText directly.
- (NSDictionary *)attributesFromProperties
{
    // Setup shadow attributes
    NSShadow *shadow = shadow = [[NSShadow alloc] init];
    if (self.shadowColor)
    {
        shadow.shadowColor = self.shadowColor;
        shadow.shadowOffset = self.shadowOffset;
    }
    else
    {
        shadow.shadowOffset = CGSizeMake(0, -1);
        shadow.shadowColor = nil;
    }
    
    // Setup color attributes
    UIColor *color = self.textColor;
    if (!self.isEnabled)
    {
        color = [UIColor lightGrayColor];
    }
    else if (self.isHighlighted)
    {
        color = self.highlightedTextColor;
    }
    
    // Setup paragraph attributes
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.alignment = self.textAlignment;
    
    // Create the dictionary
    NSDictionary *attributes = @{NSFontAttributeName : self.font,
                                 NSForegroundColorAttributeName : color,
                                 NSShadowAttributeName : shadow,
                                 NSParagraphStyleAttributeName : paragraph,
                                 };
    return attributes;
}

/**
 *  Returns array of ranges for all special words, user handles, hashtags and urls in the specfied
 *  text.
 *
 *  @param text Text to parse for links
 *
 *  @return Array of dictionaries describing the links.
 */
- (NSArray *)getRangesForLinks:(NSAttributedString *)text
{
    NSMutableArray *rangesForLinks = [[NSMutableArray alloc] init];

    if (_linkClassifiers.count > 0)
    {
        [rangesForLinks addObjectsFromArray:[self getLinksFromClassifiers]];
    }
    
    return rangesForLinks;
}

- (NSArray *)getLinksFromClassifiers
{
    NSMutableArray *links = [NSMutableArray array];
    
    for (KILabelLinkClassifier *classifier in _linkClassifiers)
    {
        NSArray *classifiedLinks = classifier.classifier(self);
        
        for (NSDictionary *link in classifiedLinks)
        {
            NSMutableDictionary *mutableLink = [NSMutableDictionary dictionaryWithDictionary:link];
            mutableLink[KILabelClassifierKey] = classifier;
            
            // Make the link immutable and store it in links
            [links addObject:[NSDictionary dictionaryWithDictionary:mutableLink]];
        }
    }
    
    return links;
}

- (NSAttributedString *)addLinkAttributesToAttributedString:(NSAttributedString *)string linkRanges:(NSArray *)linkRanges
{
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:string];

    for (NSDictionary *dictionary in linkRanges)
    {
        NSRange range = [[dictionary objectForKey:KILabelRangeKey] rangeValue];
        KILabelLinkClassifier *classifier = dictionary[KILabelClassifierKey];
        
        // Get the attributes for the link from its classifier
        NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
        if (classifier.linkAttributes)
        {
            [attributes addEntriesFromDictionary:classifier.linkAttributes];
        }
        
        // Make sure the link text is colored
        if (attributes[NSForegroundColorAttributeName] == nil)
        {
            attributes[NSForegroundColorAttributeName] = self.tintColor;
        }
        
        // If we're using the URL classifier, we may want to use the system style for highlighting
        // which need link attribute to be set.
        if (_systemURLStyle && (classifier == _urlClassifier))
        {
            attributes[NSLinkAttributeName] = dictionary[KILabelLinkKey];
        }
        
        // Add our attributes
        [attributedString addAttributes:attributes range:range];
    }
    
    return attributedString;
}

#pragma mark - Layout and Rendering

- (CGRect)textRectForBounds:(CGRect)bounds limitedToNumberOfLines:(NSInteger)numberOfLines
{
    // Use our text container to calculate the bounds required. First save our
    // current text container setup
    CGSize savedTextContainerSize = _textContainer.size;
    NSInteger savedTextContainerNumberOfLines = _textContainer.maximumNumberOfLines;
    
    // Apply the new potential bounds and number of lines
    _textContainer.size = bounds.size;
    _textContainer.maximumNumberOfLines = numberOfLines;
    
    // Measure the text with the new state
    CGRect textBounds = [_layoutManager usedRectForTextContainer:_textContainer];
    
    // Position the bounds and round up the size for good measure
    textBounds.origin = bounds.origin;
    textBounds.size.width = ceil(textBounds.size.width);
    textBounds.size.height = ceil(textBounds.size.height);

    if (textBounds.size.height < bounds.size.height)
    {
        // Take verical alignment into account
        CGFloat offsetY = (bounds.size.height - textBounds.size.height) / 2.0;
        textBounds.origin.y += offsetY;
    }

    // Restore the old container state before we exit under any circumstances
    _textContainer.size = savedTextContainerSize;
    _textContainer.maximumNumberOfLines = savedTextContainerNumberOfLines;
    
    return textBounds;
}

- (void)drawTextInRect:(CGRect)rect
{
    // Don't call super implementation. Might want to uncomment this out when
    // debugging layout and rendering problems.
    // [super drawTextInRect:rect];
    
    // Calculate the offset of the text in the view
    NSRange glyphRange = [_layoutManager glyphRangeForTextContainer:_textContainer];
    CGPoint glyphsPosition = [self calcGlyphsPositionInView];
    
    // Drawing code
    [_layoutManager drawBackgroundForGlyphRange:glyphRange atPoint:glyphsPosition];
    [_layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:glyphsPosition];
}

// Returns the XY offset of the range of glyphs from the view's origin
- (CGPoint)calcGlyphsPositionInView
{
    CGPoint textOffset = CGPointZero;
    
    CGRect textBounds = [_layoutManager usedRectForTextContainer:_textContainer];
    textBounds.size.width = ceil(textBounds.size.width);
    textBounds.size.height = ceil(textBounds.size.height);
    
    if (textBounds.size.height < self.bounds.size.height)
    {
        CGFloat paddingHeight = (self.bounds.size.height - textBounds.size.height) / 2.0;
        textOffset.y = paddingHeight;
    }
    
    return textOffset;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    _textContainer.size = self.bounds.size;
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];
    
    _textContainer.size = self.bounds.size;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Update our container size when the view frame changes
    _textContainer.size = self.bounds.size;
}

- (void)setIgnoredKeywords:(NSSet *)ignoredKeywords
{
    NSMutableSet *set = [NSMutableSet setWithCapacity:ignoredKeywords.count];
    
    [ignoredKeywords enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        [set addObject:[obj lowercaseString]];
    }];
    
    _ignoredKeywords = [set copy];
}

#pragma mark - Interactions

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    _isTouchMoved = NO;
    
    // Get the info for the touched link if there is one
    NSDictionary *touchedLink;
    CGPoint touchLocation = [[touches anyObject] locationInView:self];
    touchedLink = [self linkAtPoint:touchLocation];
    
    if (touchedLink)
    {
        self.selectedRange = [[touchedLink objectForKey:KILabelRangeKey] rangeValue];
    }
    else
    {
        [super touchesBegan:touches withEvent:event];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    
    _isTouchMoved = YES;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    
    // If the user dragged their finger we ignore the touch
    if (_isTouchMoved)
    {
        self.selectedRange = NSMakeRange(0, 0);
        
        return;
    }
    
    // Get the info for the touched link if there is one
    NSDictionary *touchedLink;
    CGPoint touchLocation = [[touches anyObject] locationInView:self];
    touchedLink = [self linkAtPoint:touchLocation];
    
    if (touchedLink)
    {
        NSRange range = [[touchedLink objectForKey:KILabelRangeKey] rangeValue];
        NSString *touchedSubstring = [touchedLink objectForKey:KILabelLinkKey];
        
        // Check to see if the link is associated with a classifier
        KILabelLinkClassifier *classifier = [touchedLink objectForKey:KILabelClassifierKey];
        if (classifier && classifier.tapHandler)
        {
            classifier.tapHandler(self, touchedSubstring, range);
        }
    }
    else
    {
        [super touchesBegan:touches withEvent:event];
    }
    
    self.selectedRange = NSMakeRange(0, 0);
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    
    // Make sure we don't leave a selection when the touch is cancelled
    self.selectedRange = NSMakeRange(0, 0);
}

#pragma mark - Layout manager delegate

-(BOOL)layoutManager:(NSLayoutManager *)layoutManager shouldBreakLineByWordBeforeCharacterAtIndex:(NSUInteger)charIndex
{
    // Don't allow line breaks inside URLs
    NSRange range;
    NSURL *linkURL = [layoutManager.textStorage attribute:NSLinkAttributeName atIndex:charIndex effectiveRange:&range];
    
    return !(linkURL && (charIndex > range.location) && (charIndex <= NSMaxRange(range)));
}

+ (NSAttributedString *)sanitizeAttributedString:(NSAttributedString *)attributedString
{
    // Setup paragraph alignement properly. IB applies the line break style
    // to the attributed string. The problem is that the text container then
    // breaks at the first line of text. If we set the line break to wrapping
    // then the text container defines the break mode and it works.
    // NOTE: This is either an Apple bug or something I've misunderstood.
    
    // Get the current paragraph style. IB only allows a single paragraph so
    // getting the style of the first char is fine.
    NSRange range;
    NSParagraphStyle *paragraphStyle = [attributedString attribute:NSParagraphStyleAttributeName atIndex:0 effectiveRange:&range];
    
    if (paragraphStyle == nil)
    {
        return attributedString;
    }
    
    // Remove the line breaks
    NSMutableParagraphStyle *mutableParagraphStyle = [paragraphStyle mutableCopy];
    mutableParagraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    
    // Apply new style
    NSMutableAttributedString *restyled = [[NSMutableAttributedString alloc] initWithAttributedString:attributedString];
    [restyled addAttribute:NSParagraphStyleAttributeName value:mutableParagraphStyle range:NSMakeRange(0, restyled.length)];
    
    return restyled;
}

@end

#pragma mark - KILabelLinkClassifier
@implementation KILabelLinkClassifier

- (instancetype)initWithClassifier:(KILinkClassifier)classifier
{
    self = [super init];
    if (self)
    {
        _classifier = classifier;
    }
    
    return self;
}

+ (instancetype)linkClassifierWithLinkAndRegex:(NSRegularExpression *)regex
{
  KILabelLinkClassifier *classifier = [[KILabelLinkClassifier alloc] initWithClassifier:^NSArray *(KILabel *label) {
    NSMutableArray *rangesForUserHandles = [[NSMutableArray alloc] init];
    
    // We run the regex on the label's plain text
    NSString *text = label.text;
    
    // Run the expression and get matches
    NSArray *matches = [regex matchesInString:text options:0 range:NSMakeRange(0, text.length)];
    
    // Add all our ranges to the result
    for (NSTextCheckingResult *match in matches)
    {
      NSRange matchRange = [match range];
      NSString *matchString = [KILabelLinkClassifier linkStringFromAttributedString:label.attributedText
                                                                          withRange:matchRange];
      
      // Add the link if its not in our ignore list
      if (![label.ignoredKeywords containsObject:[matchString lowercaseString]])
      {
        [rangesForUserHandles addObject:@{KILabelRangeKey : [NSValue valueWithRange:matchRange],
                                          KILabelLinkKey : matchString
                                          }];
      }
    }
    
    // check for NSLinkAttributeName too
    
    [label.attributedText enumerateAttribute:NSLinkAttributeName
                                     inRange:NSMakeRange(0, label.attributedText.length)
                                     options:0
                                  usingBlock:^(id value, NSRange range, BOOL *stop) {
      
                                       if(!value)
                                       {
                                         return;
                                       }
                                       
                                       NSRange matchRange = range;
                                       NSString *matchString = [KILabelLinkClassifier linkStringFromAttributedString:label.attributedText
                                                                                                           withRange:matchRange];
                                       
                                       // Add the link if its not in our ignore list
                                       if (![label.ignoredKeywords containsObject:[matchString lowercaseString]])
                                       {
                                         [rangesForUserHandles addObject:@{KILabelRangeKey : [NSValue valueWithRange:matchRange],
                                                                           KILabelLinkKey : matchString
                                                                           }];
                                       }
    }];
    
    
    return rangesForUserHandles;
  }];
  
  return classifier;
}

+ (instancetype)linkClassifierWithRegex:(NSRegularExpression *)regex
{
    KILabelLinkClassifier *classifier = [[KILabelLinkClassifier alloc] initWithClassifier:^NSArray *(KILabel *label) {
        NSMutableArray *rangesForUserHandles = [[NSMutableArray alloc] init];
        
        // We run the regex on the label's plain text
        NSString *text = label.text;
        
        // Run the expression and get matches
        NSArray *matches = [regex matchesInString:text options:0 range:NSMakeRange(0, text.length)];
        
        // Add all our ranges to the result
        for (NSTextCheckingResult *match in matches)
        {
            NSRange matchRange = [match range];
            NSString *matchString = [KILabelLinkClassifier linkStringFromAttributedString:label.attributedText
                                                                                withRange:matchRange];

            // Add the link if its not in our ignore list
            if (![label.ignoredKeywords containsObject:[matchString lowercaseString]])
            {
                [rangesForUserHandles addObject:@{KILabelRangeKey : [NSValue valueWithRange:matchRange],
                                                  KILabelLinkKey : matchString
                                                  }];
            }
        }
        
        return rangesForUserHandles;
    }];
    
    return classifier;
}

+ (NSString *)linkStringFromAttributedString:(NSAttributedString *)attrStr withRange:(NSRange)range
{
    // Check to see if there's a link attribute in the text, which will be our link text. If not
    // we'll use the string in the raw text.
    id realURL = [attrStr attribute:NSLinkAttributeName atIndex:range.location effectiveRange:nil];
    if (realURL == nil)
    {
        realURL = [[attrStr string] substringWithRange:range];
    }
    else if ([realURL isKindOfClass:[NSURL class]])
    {
        // Link could be an URL, we only allow strings
        realURL = [realURL absoluteString];
    }
    
    return realURL;
}


@end
