//
//  ViewController.h
//  FrameByFrameVideoPlayer
//
//  Created by mac on 13-10-27.
//  Copyright (c) 2013年 philip. All rights reserved.//

#import <UIKit/UIKit.h>
#import "CustomMoviePlayerController.h"


@interface ViewController :UIViewController <UITableViewDataSource,UITableViewDelegate , CostomMovieGetResourceDelegate>{
    UITableView *DataTable;
    NSMutableArray *linkArray;
    NSInteger currentPlayRow;
}
@end
