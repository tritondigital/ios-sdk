//
//  TDCloseButton.m
//  TritonPlayerSDK
//
//  Created by Carlos Pereira on 2015-01-22.
//  Copyright (c) 2015 Triton Digital. All rights reserved.
//

#import "TDCloseButton.h"

@implementation TDCloseButton

-(void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 2.0);
    
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    
    CGFloat blackComponents[] = {0.0, 0.0, 0.0, 1.0};
    CGColorRef blackColor = CGColorCreate(colorspace, blackComponents);
    
    CGFloat whiteComponents[] = {1.0, 1.0, 1.0, 1.0};
    CGColorRef whiteColor = CGColorCreate(colorspace, whiteComponents);
    
    // Fill rounded black circle as the button background
    CGContextSetFillColorWithColor(context, blackColor);
    CGContextFillEllipseInRect(context, rect);
    
    // Draw a white circle as the button's outline
    CGContextSetStrokeColorWithColor(context, whiteColor);
    CGContextAddEllipseInRect(context, CGRectInset(rect, 1, 1));
    CGContextStrokePath(context);
    
    // Draw a white X
    CGContextSetLineWidth(context, 4.0);
    
    CGFloat quarterWidth = rect.size.width / 4;
    CGFloat quarterHeight = rect.size.height / 4;
    
    CGContextMoveToPoint(context, quarterWidth, quarterHeight);
    CGContextAddLineToPoint(context, 3 * quarterWidth, 3 * quarterHeight);
    CGContextStrokePath(context);
    
    CGContextMoveToPoint(context, quarterWidth, 3 * quarterHeight);
    CGContextAddLineToPoint(context, 3 * quarterWidth, quarterHeight);
    CGContextStrokePath(context);
    
    CGColorSpaceRelease(colorspace);
    CGColorRelease(whiteColor);
    CGColorRelease(blackColor);
}

@end
