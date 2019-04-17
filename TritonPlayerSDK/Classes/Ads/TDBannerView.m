//
//  TDBannerView.m
//  TritonPlayerSDK
//
//  Created by Carlos Pereira on 2014-11-26.
//  Copyright (c) 2014 Triton Digital. All rights reserved.
//

#import "TDBannerView.h"
#import "TDBannerViewDelegate.h"
#import "TDAd.h"
#import "TDAdUtils.h"
#import "TDAdLoader.h"
#import "TDCompanionBanner.h"

#import "TDAnalyticsTracker.h"

@interface TDBannerView() <UIWebViewDelegate>

@property (nonatomic, assign) NSInteger width;
@property (nonatomic, assign) NSInteger height;
@property (nonatomic, assign) NSInteger fallbackWidth;
@property (nonatomic, assign) NSInteger fallbackHeight;
@property (nonatomic, strong) UIWebView *adWebView;

@end

@implementation TDBannerView

-(instancetype)initWithWidth:(NSInteger)width
                   andHeight:(NSInteger)height {
    return [self initWithWidth:width andHeight:height andFallbackWidth:0 andFallbackHeight:0 andOrigin:CGPointZero];
}

-(instancetype)initWithWidth:(NSInteger)width
                   andHeight:(NSInteger)height
            andFallbackWidth:(NSInteger)fallbackWidth
                   andFallbackHeight:(NSInteger)fallbackHeight {
    return [self initWithWidth:width andHeight:height andFallbackWidth:fallbackWidth andFallbackHeight:fallbackHeight andOrigin:CGPointZero];
}

-(instancetype)initWithWidth:(NSInteger)width
                   andHeight:(NSInteger)height
            andFallbackWidth:(NSInteger)fallbackWidth
                   andFallbackHeight:(NSInteger)fallbackHeight
                   andOrigin:(CGPoint)origin {
    self = [super initWithFrame:CGRectMake(origin.x, origin.y, width, height)];
    
    if (self) {
        self.width = width;
        self.height = height;
        self.fallbackWidth = fallbackWidth;
        self.fallbackHeight = fallbackHeight;

        self.autoresizesSubviews = YES;
        
        self.adWebView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        self.adWebView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        self.adWebView.delegate = self;
        self.adWebView.opaque = NO;
        self.adWebView.scrollView.scrollEnabled = NO;
        self.adWebView.backgroundColor = [UIColor clearColor];
        
        [self addSubview:self.adWebView];
        self.backgroundColor = [UIColor clearColor];
        
        
         //Init Google Analytics Tracker
        [[TDAnalyticsTracker sharedTracker] initialize];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        
    }
    return self;
}

-(void)setOrigin:(CGPoint)origin {
    self.frame = CGRectMake(origin.x, origin.y, self.frame.size.width, self.frame.size.height);
}

-(void)setWidth:(NSInteger)width andHeight:(NSInteger)height {
    self.width = width;
    self.height = height;
}

-(void)setFallbackWidth:(NSInteger)fallbackWidth andHeight:(NSInteger)fallbackHeight {
    self.fallbackWidth = fallbackWidth;
    self.fallbackHeight = fallbackHeight;
}

-(void)presentAd:(TDAd *)ad {
    
    // Fail if size is not set
    if (self.width <= 0 || self.height <= 0) {
        [self failWithError:[TDAdUtils errorWithCode:TDErrorCodeUndefinedSize
                                 andDescription:@"The TDBanner width and height must be set before loading a request."]];
        return;
    }
    
    // Check if there's an ad available, otherwise clear the banner
    if (ad) {
        
        if (ad.companionBanners) {
            
            // Look for an available banner
            TDCompanionBanner *banner = [self bannerFromArray:ad.companionBanners withWidth:self.width andHeight:self.height];
            
            // Try the fallback in case the main dimensions are not found.
            if (!banner) {
                banner = [self bannerFromArray:ad.companionBanners withWidth:self.fallbackWidth andHeight:self.fallbackHeight];
            }
            
            if (banner) {
								if ( banner.contentURL ){
										
										if( [banner.contentURL.scheme isEqualToString:@"https"] ){
												[self.adWebView loadRequest:[NSURLRequest requestWithURL:banner.contentURL]];
										} else {
												[self failWithError:[TDAdUtils errorWithCode:TDErrorCodeInvalidAdURL andDescription:@"Only https is supported"]];
										}
								
								}else if ( banner.contentHTML )
                {
                    NSString *fullHTML;
                    NSRange rangeValue = [banner.contentHTML rangeOfString:@"<html>" options:NSCaseInsensitiveSearch];
                    
                    // If we find the <html> tag in the HTMLResource CDATA we do not wrap the HTMLResource, allowing for both full HTML page as well as Snippet
                    if (rangeValue.location == NSNotFound )
                        fullHTML = [NSString stringWithFormat:@"<html><head><style type=\"text/css\">html, body {width:100%; height: 100%; margin: 0px; padding: 0px;}</style></head><body>%@</body><html>",banner.contentHTML ];
                    else
                        fullHTML = [banner.contentHTML copy];
                    
                    [self.adWebView loadHTMLString:fullHTML baseURL:nil];
                    NSString *bodyStyle = @"document.getElementsByTagName('body')[0].style.textAlign = 'center';";
                    [self.adWebView  performSelectorOnMainThread:@selector(stringByEvaluatingJavaScriptFromString:)  withObject:bodyStyle waitUntilDone:NO];
                }
                
            } else {
                [self failWithError:[TDAdUtils errorWithCode:TDErrorCodeNoInventory andDescription:@"No ad to display"]];
            }
        
        } else {
            [self failWithError:[TDAdUtils errorWithCode:TDErrorCodeNoInventory andDescription:@"No ad to display"]];
        }
        
    } else {
        [self clear];
    }
    
}

-(TDCompanionBanner*)bannerFromArray:(NSArray*) array withWidth:(NSInteger)width andHeight:(NSInteger) height {
    TDCompanionBanner *banner = nil;
    
    for (banner in array) {
        if (banner.width == width && banner.height == height) {
            break;
        }
    }
    
    return banner;
}

-(void)clear {
    [self.adWebView stringByEvaluatingJavaScriptFromString:@"document.body.innerHTML = \"\";"];
}

-(CGSize)intrinsicContentSize {
    return self.frame.size;
}

#pragma mark UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSString *bodyStyleHorizontal = @"document.getElementsByTagName('body')[0].style.textAlign = 'center';";
    [webView stringByEvaluatingJavaScriptFromString:bodyStyleHorizontal];
    
    if ([self.delegate respondsToSelector:@selector(bannerViewDidPresentAd:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate bannerViewDidPresentAd:self];
        });
    }
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    
    if ([self.delegate respondsToSelector:@selector(bannerView:didFailToPresentAdWithError:)]) {
        NSError *tdError = [TDAdUtils errorWithCode:TDErrorCodeInvalidAdURL
                                    andDescription:@"TDBanner could not load the ad requested."
                                  andFailureReason:@"A network error occurred."
                             andRecoverySuggestion:@"Verify your connection or if the request is valid."
                                andUnderlyingError:error];
            
        [self failWithError:tdError];
    }
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSURL *loadURL = [request URL];
    
    if ( ( [[loadURL scheme] isEqualToString: @"http"] || [[loadURL scheme] isEqualToString: @"https"] ) && (navigationType == UIWebViewNavigationTypeLinkClicked))
    {
        if ([self.delegate respondsToSelector:@selector(bannerViewWillLeaveApplication:)]) {
            [self.delegate bannerViewWillLeaveApplication:self];
        }
        [[UIApplication sharedApplication] openURL:request.URL];
        return FALSE;
    }
    return YES;
}

#pragma mark Error handling

-(void) failWithError:(NSError *) error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(bannerView:didFailToPresentAdWithError:)]) {
            [self.delegate bannerView:self didFailToPresentAdWithError:error];
        }
    });
}

@end
