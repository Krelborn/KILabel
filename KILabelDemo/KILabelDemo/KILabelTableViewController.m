//
//  KILabelTableViewController.m
//  KILabelDemo
//
//  Created by Matt Styles on 27/04/2015.
//  Copyright (c) 2015 Matthew Styles. All rights reserved.
//

#import "KILabelTableViewController.h"

#import "KILabelTableViewCell.h"

NSString * const KILabelCellIdentifier = @"labelCell";

@implementation KILabelTableViewController

/**
 *  When the view loads we set the estimated row height to a non-zero value. This will mean
 * that the row height will be calculated for us by auto-layout when each row comes into view.
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
        
    self.tableView.estimatedRowHeight = 44;
}

#pragma mark - Table view data source

/**
 *  Just one section in our table.
 */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

/**
 *  Hard coded the number of rows to keep things simple
 */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 20;
}

/**
 *  Get KILabelTableViewCell and configure its content.
 *
 *  @discussion All of the sizing is handled by auto-layout and configured through the cell 
 *  prototype in the storyboard. The KILabel is set to have unlimited number of lines and word-wrap. 
 *  It then has constraints to the edges of the superview (Cell content view). To make the resize 
 *  behaviour correct the Label's Content Hugging and Compression priorities have to be set high,
 *  >= 751 seems to work in this case (I've set it to 1000).
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    KILabelTableViewCell *cell = (KILabelTableViewCell *)[tableView dequeueReusableCellWithIdentifier:KILabelCellIdentifier forIndexPath:indexPath];
    
    switch (indexPath.row)
    {
        case 0:
            cell.label.text = @"This is a really long @string. It should appear across multiple lines "
                              @"as long as #autolayout is configured #correctly. There's very little "
                              @"code to @required to make this work just set the constraints on all "
                              @"sides of the label, and a high content hugging and compression "
                              @"resistence priority. Oh and make sure to configure the table with "
                              @"automatic row heights and a non-zero estimated row height.";
            break;
            
        case 1:
            cell.label.text = @"Here's an #emoji, one of the joys of unicode strings! 😈";
            break;
            
        case 2:
            cell.label.text = @"The length of a #KILabel is unrestricted, unlike the length of a "
                              @"tweet. Tweets are limited to 140 characters, here's long link to "
                              @"explain why this is the case http://www.adweek.com/socialtimes/the-reason-for-the-160-character-text-message-and-140-character-twitter-length-limits/4914.";
            break;
            
        default:
            cell.label.text = @"This row has no content!";
            break;
    }
    
    // Block to handle all our taps, we attach this to all the label's handlers
    KILinkTapHandler tapHandler = ^(KILabel *label, NSString *string, NSRange range) {
        [self tappedLink:string cellForRowAtIndexPath:indexPath];
    };
    
    cell.label.userHandleLinkTapHandler = tapHandler;
    cell.label.urlLinkTapHandler = tapHandler;
    cell.label.hashtagLinkTapHandler = tapHandler;
    
    return cell;
}

/**
 *  Called when a link is tapped.
 *
 *  @param link    The link that was tapped
 *  @param indexPath Index path of the cell containing the link that was tapped.
 */
- (void)tappedLink:(NSString *)link cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *title = [NSString stringWithFormat:@"Tapped %@", link];
    NSString *message = [NSString stringWithFormat:@"You tapped %@ in section %@, row %@.",
                         link,
                         @(indexPath.section),
                         @(indexPath.row)];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleDefault handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

@end
