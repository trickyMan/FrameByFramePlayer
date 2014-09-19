//
//  CustomMoviePlayerController.m
//  FrameByFrameVideoPlayer
//
//  Created by mac on 13-10-27.
//  Copyright (c) 2013年 philip. All rights reserved.
//

#import "CustomMoviePlayerController.h"
#define CLEAR_BUTTON_ADJUST_VERTICAL (16)

@interface CustomMoviePlayerController()
{
    BOOL isFull;
}

-(void)initPlayer;
-(void)monitorMovieProgress;
-(NSString*)convertMovieTimeToFrameNumber:(CGFloat)time;
-(void) respondFullScreen:(id)sender;

@end

@implementation CustomMoviePlayerController

@synthesize movieURL;
@synthesize delegate;
@synthesize observe;

#pragma mark - View lifecycle

- (void)dealloc {
    /* release all the resource */
    [moviePlayeView release];
    [playButton release];
    [movieProgressSlider release];
    [playControllerView release];
    
    [currentTimeLabel release];
    [totalTimeLabel release];
    [PlayControlView release];
    delegate = nil;
    [movieURL release];
	
    [super dealloc];
}

- (void)displayRightButton:(NSString *)bg_pic response:(id)response selector:(SEL)action
{
    UIButton *btnBack = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 24, 24)];
    [btnBack setBackgroundImage:[UIImage imageNamed:bg_pic] forState:UIControlStateNormal];
    [btnBack addTarget:response action:action forControlEvents:UIControlEventTouchUpInside];
    
	/* back button */
    UIBarButtonItem *bbiBack = [[UIBarButtonItem alloc]initWithCustomView:btnBack];
    [btnBack release];
    
    self.navigationItem.rightBarButtonItem = bbiBack;
    [bbiBack release];
}


- (void)viewDidLoad 
{
    [super viewDidLoad];
    isFull = FALSE;
    [self displayRightButton:@"fullScreen" response:self selector:@selector(respondFullScreen:)];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.barTintColor = [UIColor blackColor];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
}



-(void)viewWillDisappear:(BOOL)animated
{
    /* if the screen is locked , remember the position current playing. */
    [super viewWillDisappear:animated];
    [moviePlayeView.player pause];
    playButton.tag = 100;
    [playButton setBackgroundImage:[UIImage imageNamed:@"play"]  forState:UIControlStateNormal];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	/* replay current movie */
	[self initPlayer];
	[self.view bringSubviewToFront:playControllerView];
	[self monitorMovieProgress];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
	/* release movie playing resource */
    [self releaseMovieResource];
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
}

-(void) respondFullScreen:(id)sender
{
    AVPlayerLayer *layer = (AVPlayerLayer *)[moviePlayeView layer];

	if (isFull) {
        NSLog(@"should un full");
        [self displayRightButton:@"fullScreen" response:self selector:@selector(respondFullScreen:)];
		layer.videoGravity = AVLayerVideoGravityResizeAspect;
        isFull = NO;
    }
    else
    {
        isFull = YES;
        NSLog(@"should full");        
        layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        [self displayRightButton:@"partScreen" response:self selector:@selector(respondFullScreen:)];
    }
}

-(void)monitorMovieProgress{
    //use movieProgressSlider display the progress of movie playing.
    // the first parameter indicate the frequency of the call back.
    movieProgressSlider.value = 0.0;
    currentTimeLabel.text = @"0";
    observe = [moviePlayeView.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 100) queue:NULL usingBlock:^(CMTime time){
        // get current time.
        CMTime currentTime = moviePlayeView.player.currentItem.currentTime;
        // convert to second.
        CGFloat currentPlayTime = (CGFloat)currentTime.value/currentTime.timescale;
        movieProgressSlider.value = currentPlayTime/totalMovieDuration;
		
		/* convert time to frame number & display current playing frame index */
        currentTimeLabel.text = [self convertMovieTimeToFrameNumber:currentPlayTime];
    }];
}

-(void) releaseMovieResource
{
    [moviePlayeView.player removeTimeObserver:observe];
    [moviePlayeView.player pause];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:moviePlayeView.player.currentItem];
    // release the observer. no need the monitor the movie playing state.
    [moviePlayeView.player.currentItem removeObserver:self
                                           forKeyPath:@"status"
                                              context:nil];
    [moviePlayeView setPlayer:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return interfaceOrientation!=UIInterfaceOrientationPortraitUpsideDown;
}


-(void)initPlayer{
    NSString * urlString = [self.movieURL path];
    
    NSLog(@"%@" , [urlString lastPathComponent]);
    
	/* init player item using URL */
    AVPlayerItem *playerItem  = [[AVPlayerItem alloc]initWithURL:movieURL];
    AVAssetTrack * videoATrack = [[playerItem.asset tracksWithMediaType:AVMediaTypeVideo] lastObject];
	
    if(videoATrack)
    {
		/* get all the frame number per second */
        fps = videoATrack.nominalFrameRate;
        NSLog(@"%f,%f" , videoATrack.naturalSize.height , videoATrack.naturalSize.width);
    }
    
	/* alloc a player */
    AVPlayer *player = [[AVPlayer alloc]initWithPlayerItem:playerItem];
    [playerItem release];
    
    [moviePlayeView setPlayer:player];
    [player release];
 
    [moviePlayeView setFrame:self.view.frame];
	
	/* play ! */
    [moviePlayeView.player play];
    [self resetPlayButton:YES];
    
    // calc the duration of this movie.
    CMTime totalTime = playerItem.asset.duration;
    // convert the result to CGFloat , because 5/10 = 0.
    totalMovieDuration = (CGFloat)totalTime.value/totalTime.timescale;
	
    // display total frame number in the right.
    totalTimeLabel.text = [self convertMovieTimeToFrameNumber:totalMovieDuration];
    
    // monitor the status of movie playing.
    [moviePlayeView.player.currentItem addObserver:self
                                        forKeyPath:@"status" 
                                           options:NSKeyValueObservingOptionNew
                                           context:nil];
    // notify when movie is end.
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:moviePlayeView.player.currentItem];
	/* notify when the app will locked. */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appHasGoneInBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItem *playerItem = (AVPlayerItem*)object;
        if (playerItem.status==AVPlayerStatusReadyToPlay) {
            /* nothing */
        }
    }
}

-(NSString*)convertMovieTimeToFrameNumber:(CGFloat)time{
    // convert the time to frame numbers.
    return [NSString stringWithFormat:@"%.0f" , time * fps];
}

-(void)moviePlayDidEnd:(NSNotification*)notification{
    // replay :)
    CMTime time = CMTimeMake(0, 1);
    [moviePlayeView.player seekToTime:time completionHandler:^(BOOL finish){
        [moviePlayeView.player play];
        [self resetPlayButton:YES];
    }];
}

-(void)appHasGoneInBackground:(NSNotification*)notification{
    // stop first to avoid exception.
    [moviePlayeView.player pause];
    playButton.tag = 100;
    [playButton setBackgroundImage:[UIImage imageNamed:@"play"]  forState:UIControlStateNormal];
}

-(IBAction)playClick:(id)sender{
    // play/pause control.
	
    UIButton * Button = (UIButton *)sender;
    if(Button.tag == 100)
    {
		/* pause to play */
        [moviePlayeView.player play];
        Button.tag = 101;
        [Button setBackgroundImage:[UIImage imageNamed:@"stop"]  forState:UIControlStateNormal];
    }
    else{
		/* play to pause */
        [moviePlayeView.player pause];
        Button.tag = 100;
        [Button setBackgroundImage:[UIImage imageNamed:@"play"]  forState:UIControlStateNormal];
    }
}

- (void) resetPlayButton:(BOOL)isPlaying
{
	/* reset the play/pause button */
    if(!isPlaying)
    {
		/* shoud pause */
        if (playButton.tag == 101) {
            [moviePlayeView.player pause];
            playButton.tag = 100;
            [playButton setBackgroundImage:[UIImage imageNamed:@"play"]  forState:UIControlStateNormal];
        }
    }
    else
    {
		/* should play */
        if (playButton.tag == 100) {
            [moviePlayeView.player play];
            playButton.tag = 101;
            [playButton setBackgroundImage:[UIImage imageNamed:@"stop"]  forState:UIControlStateNormal];
        }

    }
}

-(IBAction)nextFileClick:(id)sender
{
    NSLog(@"next file clicked");
    if (self.delegate && [self.delegate respondsToSelector:@selector(GetNextPlayURL)]) {
		/* get the next play URL */
        NSURL *URL = [self.delegate GetNextPlayURL];
        if(URL)
        {
            self.movieURL = URL;
		}
		
		/* release play source & play the new URL */
        [self releaseMovieResource];
        [self initPlayer];
        [self monitorMovieProgress];
    }
}

-(IBAction)NextFrameClick:(id)sender
{
    NSLog(@"next frame clicked");
    [moviePlayeView.player.currentItem stepByCount:1];
    [self resetPlayButton:NO];
}
-(IBAction)PreviousFrameClick:(id)sender
{
    NSLog(@"previous frame clicked");
    [moviePlayeView.player.currentItem stepByCount:-1];
    [self resetPlayButton:NO];
    
}
-(IBAction)previousFileClick:(id)sender
{
    NSLog(@"previous file clicked");
    if (self.delegate && [self.delegate respondsToSelector:@selector(GetPreviousPlayURL)]) {
        NSURL *URL = [self.delegate GetPreviousPlayURL];
        if(URL)
        {
            self.movieURL = URL;
            
        }
        
		/* just like the next file */
        [self releaseMovieResource];
        [self initPlayer];
        [self monitorMovieProgress];
    }
}

-(IBAction)movieProgressDragged:(id)sender{
    /* get the position should jump to */
    float dragedSeconds = (totalMovieDuration*movieProgressSlider.value);
    NSLog(@"dragedSeconds:%f :::: %f",dragedSeconds , movieProgressSlider.value);
    
    // get current time.
    CMTime currentTime = moviePlayeView.player.currentItem.currentTime;
    // convert to second.
    CGFloat currentPlayTime = (CGFloat)currentTime.value/currentTime.timescale;
	
	/* calc the frame position in this movie. */
    int step = (dragedSeconds - currentPlayTime) * fps;
    NSLog(@"%d" , step);
	
	/* jump. */
    [moviePlayeView.player.currentItem stepByCount:step];
    UIButton * Button = playButton;
    if(Button.tag == 100)
    {
        /* stoped */
    }
    else{
        /* playing  */
        /* do nothing */
        [moviePlayeView.player play];
    }
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController{
    [popoverController release];
}

@end
