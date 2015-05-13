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

#import "KIViewController.h"
#import "KILabel.h"


@interface KIViewController ()

@property (weak, nonatomic) IBOutlet KILabel *label;

- (IBAction)toggleDetectLinks:(UISwitch *)sender;
- (IBAction)toggleDetectURLs:(UISwitch *)sender;
- (IBAction)toggleDetectUsernames:(UISwitch *)sender;
- (IBAction)toggleDetectHashtags:(UISwitch *)sender;
- (IBAction)longPressLabel:(UILongPressGestureRecognizer *)sender;

@end

@implementation KIViewController

/**
 *  When the view loads we attach handlers for the events we're interested in. KILabel differenciates
 *  between taps on different types of link.
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _label.systemURLStyle = YES;

    // Attach block for handling taps on usenames
    _label.userHandleLinkTapHandler = ^(KILabel *label, NSString *string, NSRange range) {
        NSString *message = [NSString stringWithFormat:@"You tapped %@", string];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Username"
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:nil]];
        
        [self presentViewController:alert animated:YES completion:nil];
    };

    _label.hashtagLinkTapHandler = ^(KILabel *label, NSString *string, NSRange range) {
        NSString *message = [NSString stringWithFormat:@"You tapped %@", string];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Hashtag"
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:nil]];
        
        [self presentViewController:alert animated:YES completion:nil];
    };
    
    _label.urlLinkTapHandler = ^(KILabel *label, NSString *string, NSRange range) {
        // Open URLs
        [self attemptOpenURL:[NSURL URLWithString:string]];
    };
}

#pragma mark - Action Targets

/**
 *  Handler for the user doing a "Long Press" gesture. This is configured in the
 *  storyboard by a gesture handler attached to the label.
 *
 *  @param recognizer The gestrure recognizer
 */
- (IBAction)longPressLabel:(UILongPressGestureRecognizer *)recognizer
{
    // Only accept gestures on our label and only in the begin state
    if ((recognizer.view != self.label) || (recognizer.state != UIGestureRecognizerStateBegan))
    {
        return;
    }
    
    // Get the position of the touch in the label
    CGPoint location = [recognizer locationInView:self.label];
    
    // Get the link under the location from the label
    NSDictionary *link = [self.label linkAtPoint:location];
    
    if (!link)
    {
        // No link was touched
        return;
    }
    
    // Put up an action sheet to let the user do something with the link
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];

    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Copy link" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        // Copy straight to the pasteboard
        [UIPasteboard generalPasteboard].string = link[KILabelLinkKey];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Mail link" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self mailLink:link[KILabelLinkKey]];
    }]];

    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Open in Safari" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSURL *url = [NSURL URLWithString:link[KILabelLinkKey]];
        [self attemptOpenURL:url];
    }]];
    
    // Show the action sheet
    [self presentViewController:actionSheet animated:YES completion:nil];
}

/**
 *  Action method for toggling all link detection.
 *
 *  @param sender Switch action is bound to
 */
- (IBAction)toggleDetectLinks:(UISwitch *)sender
{
    self.label.automaticLinkDetectionEnabled = sender.isOn;
}

/**
 *  Action method to demonstrate toggling of URL hilighting and hit detection.
 *
 *  @param sender Switch action is bound to
 */
- (IBAction)toggleDetectURLs:(UISwitch *)sender
{
    if (sender.isOn)
    {
        self.label.linkDetectionTypes |= KILinkTypeOptionURL;
    }
    else
    {
        self.label.linkDetectionTypes ^= KILinkTypeOptionURL;
    }
}

/**
 *  Action method to demonstrate toggling of Username (Handle) hilighting and hit detection.
 *
 *  @param sender Switch action is bound to
 */
- (IBAction)toggleDetectUsernames:(UISwitch *)sender
{
    if (sender.isOn)
    {
        self.label.linkDetectionTypes |= KILinkTypeOptionUserHandle;
    }
    else
    {
        self.label.linkDetectionTypes ^= KILinkTypeOptionUserHandle;
    }
}

/**
 *  Action method to demonstrate toggling of Hashtag hilighting and hit detection.
 *
 *  @param sender Switch action is bound to
 */
- (IBAction)toggleDetectHashtags:(UISwitch *)sender
{
    if (sender.isOn)
    {
        self.label.linkDetectionTypes |= KILinkTypeOptionHashtag;
    }
    else
    {
        self.label.linkDetectionTypes ^= KILinkTypeOptionHashtag;
    }
}


#pragma mark - Helper methods

/**
 *  Checks to see if its an URL that we can open in safari. If we can then open it,
 *  otherwise put up an alert to the user.
 *
 *  @param url URL to open in Safari
 */
- (void)attemptOpenURL:(NSURL *)url
{
    BOOL safariCompatible = [url.scheme isEqualToString:@"http"] || [url.scheme isEqualToString:@"https"];
    
    if (safariCompatible && [[UIApplication sharedApplication] canOpenURL:url])
    {
        [[UIApplication sharedApplication] openURL:url];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Problem"
                                                        message:@"The selected link cannot be opened."
                                                       delegate:nil
                                              cancelButtonTitle:@"Dismiss"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

/**
 *  Create an email containing the specified link. Will put up an alert if we can't send mail.
 *
 *  @param link The link to use as content of the email.
 */
- (void)mailLink:(NSString *)link
{
    if ([MFMailComposeViewController canSendMail])
    {
        // Create a mail controller with a default subject
        MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
        controller.mailComposeDelegate = self;
        [controller setSubject:@"Link from my App"];
        
        // Create the body for the mail. We use HTML format because its nice
        NSString *message = [NSString stringWithFormat:@"<!DOCTYPE html><html><a href=\"%@\">%@</a><body></body></html>", link, link];
        [controller setMessageBody:message isHTML:YES];
        
        // Show the mail controller
        [self presentViewController:controller animated:YES completion:NULL];
    }
    else
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Problem"
                                                                       message:@"Cannot send mail."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:nil]];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

@end


#pragma mark - MFMailComposeViewControllerDelegate
@implementation KIViewController (MFMailComposeViewControllerDelegate)

/**
 *  Just dismiss the controller. Don't do anything else.
 */
-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end