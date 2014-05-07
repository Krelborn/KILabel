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

@property NSDictionary *selectedLink;

@property (weak, nonatomic) IBOutlet KILabel *label;

- (IBAction)toggleDetectLinks:(UISwitch *)sender;
- (IBAction)toggleDetectURLs:(UISwitch *)sender;
- (IBAction)toggleDetectUsernames:(UISwitch *)sender;
- (IBAction)toggleDetectHashtags:(UISwitch *)sender;
- (IBAction)longPressLabel:(UILongPressGestureRecognizer *)sender;

@end

@implementation KIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Attach a simple tap handler to the label. This is a quick and dirty way
    // to respond to links being touched by the user.
    
    _label.systemURLStyle = YES;

    _label.linkUserHandleTapHandler = ^(KILabel *label, NSString *string, NSRange range) {
        NSString *linkTypeString = @"Username";
        NSString *message = [NSString stringWithFormat:@"You tapped %@ which is a %@", string, linkTypeString];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Hello"
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"Dismiss"
                                              otherButtonTitles:nil];
        [alert show];
    };

    _label.linkHashtagTapHandler = ^(KILabel *label, NSString *string, NSRange range) {
        NSString *linkTypeString = @"Hashtag";
        NSString *message = [NSString stringWithFormat:@"You tapped %@ which is a %@", string, linkTypeString];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Hello"
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"Dismiss"
                                              otherButtonTitles:nil];
        [alert show];

    };
    
    _label.linkURLTapHandler = ^(KILabel *label, NSString *string, NSRange range) {
        // Open URLs
        [self attemptOpenURL:[NSURL URLWithString:string]];
    };
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Action Targets

// Handler for the user doing a "Long Press" gesture. This is configured in the
// storyboard by a gesture handler attached to the label.
- (IBAction)longPressLabel:(UILongPressGestureRecognizer *)recognizer
{
    // Only accept gestures on our label and only in the begin state
    if ((recognizer.view != self.label) || (recognizer.state != UIGestureRecognizerStateBegan))
        return;
    
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
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@""
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:@"Copy link", @"Mail link", @"Open in Safari", nil];
    
    // We need to save the link so we can access it from our delegate method
    self.selectedLink = link;
    
    // Show the action sheet
    [sheet showInView:self.view];
}

- (IBAction)toggleDetectLinks:(UISwitch *)sender
{
    // Toggle the link detection on and off
    self.label.automaticLinkDetectionEnabled = sender.isOn;
}

- (IBAction)toggleDetectURLs:(UISwitch *)sender
{
    if (sender.isOn)
        self.label.linkDetectionTypes |= KILinkTypeURL;
    else
        self.label.linkDetectionTypes ^= KILinkTypeURL;
}

- (IBAction)toggleDetectUsernames:(UISwitch *)sender
{
    if (sender.isOn)
        self.label.linkDetectionTypes |= KILinkTypeUserHandle;
    else
        self.label.linkDetectionTypes ^= KILinkTypeUserHandle;
}

- (IBAction)toggleDetectHashtags:(UISwitch *)sender
{
    if (sender.isOn)
        self.label.linkDetectionTypes |= KILinkTypeHashtag;
    else
        self.label.linkDetectionTypes ^= KILinkTypeHashtag;
}

#pragma mark - Action Sheet Delegate

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // Constants for our button indexes
    enum
    {
        kActionCopyLink,
        kActionMailLink,
        kActionOpenInSafari
    };
    
    switch (buttonIndex)
    {
        case kActionCopyLink:
            // Copy straight to the pasteboard
            [UIPasteboard generalPasteboard].string = self.selectedLink[@"link"];
            break;
            
        case kActionMailLink:
        {
            if ([MFMailComposeViewController canSendMail])
            {
                // Create a mail controller with a default subject
                MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
                controller.mailComposeDelegate = self;
                [controller setSubject:@"Link from my App"];
                
                // Create the body for the mail. We use HTML format because its nice
                NSString *link = self.selectedLink[KILabelLinkKey];
                NSString *message = [NSString stringWithFormat:@"<!DOCTYPE html><html><a href=\"%@\">%@</a><body></body></html>", link, link];
                [controller setMessageBody:message isHTML:YES];
                
                // Show the mail controller
                [self presentViewController:controller animated:YES completion:NULL];
            }
            else
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Problem"
                                                                message:@"Cannot send mail."
                                                               delegate:nil
                                                      cancelButtonTitle:@"Dismiss"
                                                      otherButtonTitles:nil];
                [alert show];
            }
            break;
        }
            
        case kActionOpenInSafari:
        {
            NSURL *url = [NSURL URLWithString:self.selectedLink[KILabelLinkKey]];
            [self attemptOpenURL:url];
            break;
        }
    }
}

#pragma mark - Mail Compose View Controller Delegate

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Helper methods

// Checks to see if its an URL that we can open in safari. If we can then open it,
// otherwise put up an alert to the user.
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

@end
