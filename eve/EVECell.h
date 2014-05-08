//
//  EVECell.h
//  eve
//
//  Created by Teddy Moussignac on 4/16/14.
//  Copyright (c) 2014 tdp. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EVECell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *descLabel;
@property (weak, nonatomic) IBOutlet UILabel *tagsLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;
@end
