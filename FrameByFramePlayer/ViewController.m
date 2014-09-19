//
//  ViewController.m
//  FrameByFrameVideoPlayer
//
//  Created by philip on 13-10-27.
//  Copyright (c) 2013年 philip. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <MediaPlayer/MediaPlayer.h>
#import "CustomMoviePlayerController.h"

@implementation ViewController
#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    DataTable = [[UITableView alloc] initWithFrame:self.view.frame];
    
    currentPlayRow = 0;
	// Do any additional setup after loading the view, typically from a nib.
    linkArray = [[NSMutableArray alloc]initWithObjects:@"test2.mp4" , @"test1.m4v"  , nil];
}

- (void)dealloc {
    [DataTable release];
    [linkArray release];
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return interfaceOrientation!=UIInterfaceOrientationPortraitUpsideDown;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return linkArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *movieCell = [DataTable dequeueReusableCellWithIdentifier:@"movieCell"];
    if (movieCell==nil) {
        movieCell = [[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"movieCell"]autorelease];
    }
    NSString *linkStr = [linkArray objectAtIndex:indexPath.row];
    movieCell.textLabel.text = linkStr;
    MPMoviePlayerController *movieController = [[MPMoviePlayerController alloc]initWithContentURL:[NSURL URLWithString:linkStr]];
    [movieController requestThumbnailImagesAtTimes:[NSArray arrayWithObject:[NSNumber numberWithDouble:0]] timeOption:MPMovieTimeOptionNearestKeyFrame];
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(movieThumbnailLoadComplete:) name:MPMoviePlayerThumbnailImageRequestDidFinishNotification object:movieController];
    return movieCell;
}

- (NSURL *)movieUrl
{
    NSArray *name = [((NSString *)[linkArray objectAtIndex:currentPlayRow]) componentsSeparatedByString:@"."];
    
    NSString *moviePath = [[NSBundle mainBundle] pathForResource:[name objectAtIndex:0] ofType:[name objectAtIndex:1]];
    if (moviePath)
        return [NSURL fileURLWithPath:moviePath];
    
    return nil;
}


-(void)movieThumbnailLoadComplete:(NSNotification*)notification{
    NSDictionary *userInfo = [notification userInfo];
    NSLog(@"userInfo:%@",userInfo);
}
     
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    currentPlayRow = indexPath.row;
    NSURL *linkURL = [self movieUrl];
    CustomMoviePlayerController *movieController = [[CustomMoviePlayerController alloc]init];
    movieController.movieURL = linkURL;
    
    movieController.delegate = self;
    [self.navigationController pushViewController:movieController animated:YES];
    [movieController release];
}

#pragma mark - custom movie delegate
- (NSURL *)GetNextPlayURL
{
    if(currentPlayRow + 1  >= [linkArray count] )
    {
        currentPlayRow = 0;
    }
    else{
        currentPlayRow ++;
    }
    
    return [self movieUrl];
}

- (NSURL *)GetPreviousPlayURL
{
    if(currentPlayRow  == 0 )
    {
        currentPlayRow = [linkArray count] - 1;
    }
    else{
        currentPlayRow --;
    }
    
    return [self movieUrl];
}

@end
