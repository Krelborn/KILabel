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
    return 3;
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
            cell.label.text = @"Lorem ipsum @dolor sit #amet, consectetur adipiscing elit. In sit amet arcu velit. Nam in enim nibh. http://Etiam.sollicitudin.com turpis vel ipsum.";
            break;
            
        case 1:
            cell.label.text = @"Short #tweet";
            break;
            
        case 2:
            cell.label.text = @"This just contains an url http://compiledcreations.com";
            break;
            
        default:
            break;
    }
    
    return cell;
}

@end
