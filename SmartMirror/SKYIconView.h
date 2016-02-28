//
//  SKYView.h
//  Skycons
//
//  Created by Zach Waugh on 6/17/13.
//  Copyright (c) 2013 Zach Waugh. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, SKYIconType) {
  SKYClearDay,
  SKYClearNight,
  SKYPartlyCloudyDay,
  SKYPartlyCloudyNight,
  SKYCloudy,
  SKYRain,
  SKYSleet,
  SKYSnow,
  SKYWind,
  SKYFog
};

#if TARGET_OS_IPHONE
@interface SKYIconView : UIView

@property (strong, nonatomic) UIColor *color;
#else
@interface SKYIconView : NSView

@property (strong, nonatomic) NSColor *color;
#endif

@property (assign, nonatomic) SKYIconType type;

- (void)play;
- (void)pause;
- (BOOL)isAnimating;

@end
