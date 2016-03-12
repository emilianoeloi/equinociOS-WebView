//
//  ViewController.m
//  equinocios-Webview
//
//  Created by Emiliano Barbosa on 3/11/16.
//  Copyright © 2016 Bocamuchas. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <WKNavigationDelegate, WKUIDelegate, UIWebViewDelegate>

@property (nonatomic, strong) UIWebView *uiWebView;
@property (nonatomic, strong) WKWebView *wkWebView;

@end

@implementation ViewController

- (void)injectJavascript:(NSString *)resource {
    NSString *jsPath = [[NSBundle mainBundle] pathForResource:resource ofType:@"js"];
    NSString *js = [NSString stringWithContentsOfFile:jsPath encoding:NSUTF8StringEncoding error:NULL];
    
    [self.uiWebView stringByEvaluatingJavaScriptFromString:js];
}

#pragma mark WebView
-(void)setupUIWebView{
    self.uiWebView = [[UIWebView alloc] initWithFrame:CGRectZero];
    self.uiWebView.delegate = self;
}
-(void)layoutUIWebView{
    [self.view addSubview:_uiWebView];
    [self.uiWebView setTranslatesAutoresizingMaskIntoConstraints:NO];
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:self.uiWebView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeHeight multiplier:1 constant:0];
    NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:self.uiWebView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:1 constant:0];
    [self.view addConstraints:@[height, width]];
}
-(void)loadUIWebView{
    NSURL *url = [NSURL URLWithString:@"http://equinocios.com"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [_uiWebView loadRequest:request];
}
#pragma mark UIWebView Delegate
-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    [self injectJavascript:@"scripts"];
    NSLog(@"shoulrStart: %@",[request URL]);
    return YES;
}

#pragma mark WKWebView
-(void)setupWKWebView{
    WKWebViewConfiguration *theConfiguration = [[WKWebViewConfiguration alloc] init];
    self.wkWebView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:theConfiguration];
    self.wkWebView.navigationDelegate = self;
    self.wkWebView.UIDelegate = self;
}
-(void)layoutWKWebView{
    [self.view addSubview:_wkWebView];
    [self.wkWebView setTranslatesAutoresizingMaskIntoConstraints:NO];
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:self.wkWebView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeHeight multiplier:1 constant:0];
    NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:self.wkWebView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:1 constant:0];
    [self.view addConstraints:@[height, width]];
}
-(void)loadWKWebView{
    NSURL *url = [NSURL URLWithString:@"http://equinocios.com"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [_wkWebView loadRequest:request];
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupUIWebView];
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self layoutUIWebView];
    
    [self loadUIWebView];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
