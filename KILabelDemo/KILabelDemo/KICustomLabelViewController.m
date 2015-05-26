//
//  KICustomLabelViewController.m
//  KILabelDemo
//
//  Created by Matt Styles on 11/05/2015.
//  Copyright (c) 2015 Matthew Styles. All rights reserved.
//

#import "KICustomLabelViewController.h"

#import "KILabel.h"

@interface KICustomLabelViewController ()

@end

@implementation KICustomLabelViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Disable regular link detection. You don't need to do this if you want to kee
    _label.linkDetectionTypes = KILinkTypeOptionNone;
    
    // Create a message with today's date and a phone number
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"dd MMM yyyy";
    NSString *dateStr = [formatter stringFromDate:[NSDate date]];
    _label.text = [NSString stringWithFormat:@"Custom #KILabel created on %@. Call 555-2368 for help!", dateStr];
    
    [_label addLinkClassifier:[self createDateClassifier]];
    [_label addLinkClassifier:[self createPhoneNumberClassifier]];
}

// Create a KILabelLinkClassifier that highlights dates with custom highlighting. Does not handle taps!
- (KILabelLinkClassifier *)createDateClassifier
{
    NSDataDetector *dateDetector = [[NSDataDetector alloc] initWithTypes:NSTextCheckingTypeDate error:nil];
    KILabelLinkClassifier *classifier = [KILabelLinkClassifier linkClassifierWithRegex:dateDetector];
    
    // Apply link attributes to the classifier to make fancy looking links
    classifier.linkAttributes = @{NSForegroundColorAttributeName: [UIColor redColor],
                                  NSFontAttributeName: [UIFont fontWithName:@"Marker Felt" size:20]};
    
    return classifier;
}

// Create KILabelLinkClassifier that highlights phone numbers and alerts when tapped.
- (KILabelLinkClassifier *)createPhoneNumberClassifier
{
    // Create a link classifier for detector phone numbers
    NSDataDetector *phoneDetector = [[NSDataDetector alloc] initWithTypes:NSTextCheckingTypePhoneNumber error:nil];
    KILabelLinkClassifier *classifier = [KILabelLinkClassifier linkClassifierWithRegex:phoneDetector];
    
    // Handler for tapping a phone number. Don't worry it doesn't really call anyone!
    classifier.tapHandler = ^(KILabel *label, NSString *string, NSRange range) {
        NSString *message = [NSString stringWithFormat:@"Calling %@...", string];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Phone Number"
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:nil]];
        
        [self presentViewController:alert animated:YES completion:nil];
    };
    
    return classifier;
}

@end
