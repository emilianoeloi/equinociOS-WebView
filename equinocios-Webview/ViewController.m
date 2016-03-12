//
//  ViewController.m
//  equinocios-Webview
//
//  Created by Emiliano Barbosa on 3/11/16.
//  Copyright © 2016 Bocamuchas. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <WKNavigationDelegate, WKUIDelegate, UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *goAbout;
@property (nonatomic, strong) UIWebView *uiWebView;
@property (nonatomic, strong) WKWebView *wkWebView;

@end

@implementation ViewController

- (void)injectJavascript:(NSString *)resource {
    NSString *jsPath = [[NSBundle mainBundle] pathForResource:resource ofType:@"js"];
    NSString *js = [NSString stringWithContentsOfFile:jsPath encoding:NSUTF8StringEncoding error:NULL];
    
    [self.uiWebView stringByEvaluatingJavaScriptFromString:js];
}
-(BOOL)isJStoObjcSchema:(NSString *)url{
    return [url rangeOfString:@"JStoObjC://"].location != NSNotFound;
}
-(NSString *) titleWithUrl:(NSString *)url{
    NSString *title;
    NSArray *urlParts = [url componentsSeparatedByString:@"="];
    if (urlParts) {
        title = urlParts[1];
        title = [title stringByRemovingPercentEncoding];
        
    }
    return title;
}
#pragma mark WebView
-(void)setupUIWebView{
    self.uiWebView = [[UIWebView alloc] initWithFrame:CGRectZero];
    self.uiWebView.delegate = self;
}
-(void)layoutUIWebView{
    [self.view addSubview:_uiWebView];
    [self.uiWebView setTranslatesAutoresizingMaskIntoConstraints:NO];
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:self.uiWebView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeHeight multiplier:1 constant:-40];
    NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:self.uiWebView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:1 constant:0];
    [self.view addConstraints:@[height, width]];
}
-(void)loadUIWebViewWithUrl:(NSString *)absoluteUrl{
    NSURL *url = [NSURL URLWithString:absoluteUrl];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [_uiWebView loadRequest:request];
}
#pragma mark UIWebView Delegate
-(void)webViewDidStartLoad:(UIWebView *)webView{
    self.navigationItem.title = @"Carregando...";
}
-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    
    NSString *absoluteUrl = [request URL].absoluteString;
    
    if([self isJStoObjcSchema:absoluteUrl]){
        self.navigationItem.title = [self titleWithUrl:absoluteUrl];
        return NO;
    }
    
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
-(void)loadWKWebViewWithUrl:(NSString *)absoluteUrl{
    NSURL *url = [NSURL URLWithString:absoluteUrl];
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
    
    [self loadUIWebViewWithUrl:@"http://equinocios.com"];
    
}

- (IBAction)goAbout:(id)sender {
    [self loadUIWebViewWithUrl:@"http://equinocios.com/about"];
}
- (IBAction)goBack:(id)sender {
    [self.uiWebView goBack];
}
- (IBAction)refresh:(id)sender {
    [self.uiWebView reload];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
