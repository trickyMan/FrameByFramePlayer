//
//  CustomMoviePlayerController.h
//  FrameByFrameVideoPlayer
//
//  Created by mac on 13-10-27.
//  Copyright (c) 2013年 philip. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomPlayerView.h"

@protocol CostomMovieGetResourceDelegate  <NSObject>
@required

- (NSURL *)GetNextPlayURL;
- (NSURL *)GetPreviousPlayURL;

@end

@interface CustomMoviePlayerController : UIViewController<UIPopoverControllerDelegate>{
    IBOutlet CustomPlayerView *moviePlayeView;
    IBOutlet UIButton *playButton;
    IBOutlet UISlider *movieProgressSlider;
    
    IBOutlet UIView *playControllerView;
    
    //movie total duration 
    CGFloat totalMovieDuration;
    NSInteger fps;
    IBOutlet UILabel *currentTimeLabel;
    IBOutlet UILabel *totalTimeLabel;
    
    UIView *PlayControlView;
}

@property (assign) id<CostomMovieGetResourceDelegate> delegate;
@property (assign) id observe;

@property(nonatomic,retain) NSURL *movieURL;

-(IBAction)nextFileClick:(id)sender;
-(IBAction)movieProgressDragged:(id)sender;
-(IBAction)NextFrameClick:(id)sender;
-(IBAction)PreviousFrameClick:(id)sender;
-(IBAction)previousFileClick:(id)sender;
-(IBAction)playClick:(id)sender;
@end
