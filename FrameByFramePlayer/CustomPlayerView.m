//
//  CustomPlayerView.m
//  FrameByFrameVideoPlayer
//
//  Created by mac on 13-10-27.
//  Copyright (c) 2013年 philip. All rights reserved.
//

#import "CustomPlayerView.h"

@implementation CustomPlayerView

@synthesize player;

+(Class)layerClass{
    return [AVPlayerLayer class];
}

-(AVPlayer*)player{
    return [(AVPlayerLayer*)[self layer]player];
}

-(void)setPlayer:(AVPlayer *)thePlayer{
    return [(AVPlayerLayer*)[self layer]setPlayer:thePlayer];
}
@end
