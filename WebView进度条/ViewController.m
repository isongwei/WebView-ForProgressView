//
//  ViewController.m
//  WebView进度条
//
//  Created by iSongWei on 2017/2/22.
//  Copyright © 2017年 iSong. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>

@interface ViewController ()<UIWebViewDelegate,WKNavigationDelegate,WKUIDelegate>


@property (weak, nonatomic) IBOutlet UIWebView *webView;

@property (nonatomic, strong) UIProgressView *progressView;//进度条
@property (nonatomic, strong) NSTimer *progressTimer;//定时器



@property (strong, nonatomic)  WKWebView *wkWebView;
@property (nonatomic, strong) UIProgressView *wkProgressView;//进度条

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.baidu.com"]]];
    
    //进度条的创建
    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    [self.progressView setTrackTintColor:[UIColor clearColor]];
    [self.progressView setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.progressView.frame.size.height)];
    [self.view addSubview:self.progressView];
    
    
    
    

    [self addWKWebView];
    
    
}

#pragma mark - UIDelegate 页面跳转
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    NSLog(@"%@",[[request URL] absoluteString]);
    [self progressViewStartLoading];

    return YES;
}
- (void)webViewDidStartLoad:(UIWebView *)webView{
    [self progressViewStartLoading];
}
- (void)webViewDidFinishLoad:(UIWebView *)webView{

    [self progressBarStopLoading];
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    [self progressBarStopLoading];
}

#pragma mark - Progress Bar Control
//进度条
- (void)progressViewStartLoading {
    
    //网页加载进度,在导航栏底部
    [self.progressView setProgress:0.0f animated:NO];
    [self.progressView setAlpha:1.0f];
    [self.progressView setHidden:NO];
    
    if(!self.progressTimer) {
        self.progressTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f/60.f target:self selector:@selector(timerDidFire:) userInfo:nil repeats:YES];
    }
    [self.progressTimer setFireDate:[NSDate distantPast]];
}

- (void)progressBarStopLoading {
    
    if(self.progressTimer) {
        [self.progressTimer invalidate];
        self.progressTimer = nil;
    }
    if(self.progressView) {
        [self.progressView setProgress:1.0f animated:YES];
        [UIView animateWithDuration:0.3 delay:0.3 options:UIViewAnimationOptionCurveEaseOut animations:^{
            [self.progressView setAlpha:0.0f];
        } completion:^(BOOL finished) {
            [self.progressView setHidden:YES];
        }];
    }
}
- (void)timerDidFire:(id)sender {
    CGFloat increment = 0.005/(self.progressView.progress + 0.2);
    if([_webView isLoading]) {
        CGFloat progress = (self.progressView.progress < 0.75f) ? self.progressView.progress + increment : self.progressView.progress + 0.0005;
        if(self.progressView.progress < 0.95) {
            [self.progressView setProgress:progress animated:YES];
        }
    }
}
#pragma mark - wkwebView


-(void)addWKWebView{
    
    
    self.wkWebView = [[WKWebView alloc]initWithFrame:CGRectMake(0,self.view.frame.size.height*0.5+10, self.view.frame.size.width, self.view.frame.size.height-CGRectGetMaxY(_webView.bounds)-6)];
    [self.wkWebView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [self.wkWebView setNavigationDelegate:self];
    [self.wkWebView setUIDelegate:self];
    [self.wkWebView setMultipleTouchEnabled:YES];
    [self.wkWebView setAutoresizesSubviews:YES];
    [self.wkWebView.scrollView setAlwaysBounceVertical:YES];
    [self.view addSubview:self.wkWebView];

    
    
    self.wkProgressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    [self.wkProgressView setTrackTintColor:[UIColor clearColor]];
    [self.wkProgressView setProgressTintColor:[UIColor blueColor]];
    [self.wkProgressView setFrame:CGRectMake(0, self.view.frame.size.width-5, self.view.frame.size.width, 5)];
    [self.view addSubview:self.wkProgressView];
    
    [self.wkWebView addObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) options:0 context:nil];
    [self.wkWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.baidu.com"]]];
}
#pragma mark - Estimated Progress KVO (WKWebView)

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(estimatedProgress))] && object == self.wkWebView) {
        [self.wkProgressView setAlpha:1.0f];
        BOOL animated = self.wkWebView.estimatedProgress > self.wkProgressView.progress;
        
        NSLog(@"%f",self.wkWebView.estimatedProgress);
        [self.wkProgressView setProgress:self.wkWebView.estimatedProgress animated:animated];
        
        // Once complete, fade out UIProgressView
        if(self.wkWebView.estimatedProgress >= 1.0f) {
            [UIView animateWithDuration:0.3f delay:0.3f options:UIViewAnimationOptionCurveEaseOut animations:^{
                [self.wkProgressView setAlpha:0.0f];
            } completion:^(BOOL finished) {
                [self.wkProgressView setProgress:0.0f animated:NO];
            }];
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    if(webView == self.wkWebView) {
        [self updateToolbarState];
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if(webView == self.wkWebView) {
        [self updateToolbarState];

    }
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation
      withError:(NSError *)error {
    if(webView == self.wkWebView) {
        [self updateToolbarState];

    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation
      withError:(NSError *)error {
    if(webView == self.wkWebView) {
        [self updateToolbarState];

    }
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if(webView == self.wkWebView) {

    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

#pragma mark - WKUIDelegate

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures{
    if (!navigationAction.targetFrame.isMainFrame) {
        [webView loadRequest:navigationAction.request];
    }
    return nil;
}
#pragma mark - Toolbar State

- (void)updateToolbarState {}
#pragma mark - Dealloc

- (void)dealloc {
    [self.wkWebView setNavigationDelegate:nil];
    [self.wkWebView setUIDelegate:nil];
    if ([self isViewLoaded]) {
        [self.wkWebView removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress))];
    }
}


@end
