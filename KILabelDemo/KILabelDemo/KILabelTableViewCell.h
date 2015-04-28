//
//  KILabelTableViewCell.h
//  KILabelDemo
//
//  Created by Matt Styles on 27/04/2015.
//  Copyright (c) 2015 Matthew Styles. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "KILabel.h"

/**
 *  Table cell containing a single KILabel. There's no magic here, it just provides a convenient
 *  way to access the label object.
 */
@interface KILabelTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet KILabel *label;

@end
