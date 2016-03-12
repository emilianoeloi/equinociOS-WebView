//
//  ViewController.m
//  equinocios-Webview
//
//  Created by Emiliano Barbosa on 3/11/16.
//  Copyright © 2016 Bocamuchas. All rights reserved.
//

#import "ViewController.h"
static NSString *ABSOLUTE_URL=@"http://equinocios.com";

@interface ViewController () <WKNavigationDelegate, WKUIDelegate, UIWebViewDelegate, WKScriptMessageHandler>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *username;
@property (nonatomic, strong) UIWebView *uiWebView;
@property (nonatomic, strong) WKWebView *wkWebView;

@end

@implementation ViewController

#pragma mark Cookies
-(void)saveCookie:(NSString *)key value:(NSString *)value{
    NSMutableDictionary *cookieProperties = [NSMutableDictionary dictionary];
    [cookieProperties setObject:key forKey:NSHTTPCookieName];
    [cookieProperties setObject:value forKey:NSHTTPCookieValue];
    [cookieProperties setObject:@"equinocios.com" forKey:NSHTTPCookieDomain];
    [cookieProperties setObject:@"equinocios.com" forKey:NSHTTPCookieOriginURL];
    [cookieProperties setObject:@"/" forKey:NSHTTPCookiePath];
    [cookieProperties setObject:@"0" forKey:NSHTTPCookieVersion];
    
    NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:cookieProperties];
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
    
}
-(void)deleteCookie:(NSString *)key{
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in [storage cookies]) {
        if ([cookie.name isEqualToString:key]) {
            [storage deleteCookie:cookie];
        }
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}
-(NSString *)cookie:(NSString *)key{
    NSArray *httpCookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
    for (NSHTTPCookie *cookie in httpCookies) {
        if([[cookie name] isEqualToString:key]){
            return [cookie value];
        }
    }
    return nil;
}


- (void)injectJavascript:(NSString *)resource {
    NSString *jsPath = [[NSBundle mainBundle] pathForResource:resource ofType:@"js"];
    NSString *js = [NSString stringWithContentsOfFile:jsPath encoding:NSUTF8StringEncoding error:NULL];
    
    [self.uiWebView stringByEvaluatingJavaScriptFromString:js];
}
-(BOOL)isJStoObjcSchema:(NSString *)url{
    return [url rangeOfString:@"JStoObjC://"].location != NSNotFound;
}
-(BOOL)isInnerURL:(NSString *)url{
    NSLog(@"\n\n --> %@ \n\n", url);
    return [url rangeOfString:ABSOLUTE_URL].location != NSNotFound;
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
-(void)loadUIWebViewWithLocalData{
    NSString *htmlFile = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
    NSString* htmlString = [NSString stringWithContentsOfFile:htmlFile encoding:NSUTF8StringEncoding error:nil];
    [self.uiWebView loadHTMLString:htmlString baseURL:[NSURL URLWithString:ABSOLUTE_URL]];
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
    
    if (![self isInnerURL:absoluteUrl] && navigationType == UIWebViewNavigationTypeLinkClicked) {
        SFSafariViewController *svc = [[SFSafariViewController alloc]initWithURL:request.URL];
        [self presentViewController:svc animated:YES completion:^{
            
        }];
        return NO;
    }
    
    [self injectJavascript:@"ui_script"];
    return YES;
}
-(void)webViewDidFinishLoad:(UIWebView *)webView{
    self.username.title = [self cookie:@"userName"]?:@"Login";
}
#pragma mark UIWebView navigation
-(void)uiWebViewGoBack{
    [self.uiWebView goBack];
}
-(void)uiWebViewReload{
    [self.uiWebView reload];
}

#pragma mark WKWebView
-(void)setupWKWebView{
    WKWebViewConfiguration *theConfiguration = [[WKWebViewConfiguration alloc] init];
    WKUserContentController *controller = [[WKUserContentController alloc]init];
    [controller addScriptMessageHandler:self name:@"observe"];
    
    [theConfiguration setUserContentController:controller];
    self.wkWebView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:theConfiguration];
    
    self.wkWebView.navigationDelegate = self;
    self.wkWebView.UIDelegate = self;
}
-(void)layoutWKWebView{
    [self.view addSubview:_wkWebView];
    [self.wkWebView setTranslatesAutoresizingMaskIntoConstraints:NO];
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:self.wkWebView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeHeight multiplier:1 constant:-40];
    NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:self.wkWebView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:1 constant:0];
    [self.view addConstraints:@[height, width]];
}
-(void)loadWKWebViewWithUrl:(NSString *)absoluteUrl{
    NSURL *url = [NSURL URLWithString:absoluteUrl];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:1.0];
    [_wkWebView loadRequest:request];
}
#pragma mark WKWebView Delegates
-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    
    NSString *jsPath = [[NSBundle mainBundle] pathForResource:@"wk_script" ofType:@"js"];
    NSString *js = [NSString stringWithContentsOfFile:jsPath encoding:NSUTF8StringEncoding error:NULL];
    [self.wkWebView evaluateJavaScript:js completionHandler:nil];
    
}
-(void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    self.navigationItem.title = message.body;
}
#pragma mark UIWebView navigation
-(void)wkWebViewGoBack{
    [self.wkWebView goBack];
}
-(void)wkWebViewReload{
    [self.wkWebView reload];
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupWKWebView];
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self layoutWKWebView];
    
    [self loadWKWebViewWithUrl:ABSOLUTE_URL];
    
//    [self loadUIWebViewWithLocalData];
    
    
}

- (IBAction)goAbout:(id)sender {
    NSString *aboutUrl = [NSString stringWithFormat:@"%@/about",ABSOLUTE_URL];
    [self loadWKWebViewWithUrl:aboutUrl];
}
- (IBAction)goBack:(id)sender {
    [self wkWebViewGoBack];
}
- (IBAction)refresh:(id)sender {
    [self wkWebViewReload];
}
- (IBAction)login:(id)sender {
    
    NSString *username = @"Matilda";
    NSString *cookieKey = @"userName";
    
    [self saveCookie:cookieKey value:username];
    
    self.username.title = username;
    
}
- (IBAction)logout:(id)sender {
    NSString *cookieKey = @"userName";
    [self deleteCookie:cookieKey];
    self.username.title = @"Login";
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    [[NSURLCache sharedURLCache] setDiskCapacity:0];
    [[NSURLCache sharedURLCache] setMemoryCapacity:0];
}

@end
