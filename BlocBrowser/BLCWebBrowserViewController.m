//
//  BLCWebBrowserViewController.m
//  BlocBrowser
//
//  Created by Jean Ro on 11/22/14.
//  Copyright (c) 2014 Jean Ro. All rights reserved.
//

#import "BLCWebBrowserViewController.h"
#import "BLCAwesomeFloatingToolbar.h"

#define kBLCWebBrowserBackString NSLocalizedString(@"Back", @"Back command")
#define kBLCWebBrowserForwardString NSLocalizedString(@"Forward", @"Forward command")
#define kBLCWebBrowserStopString NSLocalizedString(@"Stop", @"Stop command")
#define kBLCWebBrowserRefreshString NSLocalizedString(@"Refresh", @"Reload command")

#define kBLCInitialToolbarWidth 280
#define kBLCInitialToolbarHeight 300
#define kBLCMinToolbarWidth 80
#define kBLCMinToolbarHeight 50

@interface BLCWebBrowserViewController () <UIWebViewDelegate, UITextFieldDelegate, BLCAwesomeFloatingToolbarDelegate>

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) BLCAwesomeFloatingToolbar *awesomeToolbar;
@property (nonatomic, assign) NSUInteger frameCount;

@property (nonatomic, assign) CGFloat toolbarWidth;
@property (nonatomic, assign) CGFloat toolbarHeight;
@property (nonatomic, assign) BOOL isPanning;

@end

@implementation BLCWebBrowserViewController

#pragma mark - UIViewController

-(void)loadView {
    UIView *mainView = [UIView new];
    
    self.webView = [[UIWebView alloc] init];
    self.webView.delegate = self;
    
    self.textField = [[UITextField alloc] init];
    self.textField.keyboardType = UIKeyboardTypeWebSearch;
    self.textField.returnKeyType = UIReturnKeyDone;
    self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.textField.placeholder = NSLocalizedString(@"Website URL or Search Query", @"Placeholder text for web browser URL field");
    self.textField.backgroundColor = [UIColor colorWithWhite:220/255.0f alpha:1];
    self.textField.delegate = self;
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 20)];
    self.textField.leftView = paddingView;
    self.textField.leftViewMode = UITextFieldViewModeAlways;
    self.toolbarWidth = kBLCInitialToolbarWidth;
    self.toolbarHeight = kBLCInitialToolbarHeight;
    self.isPanning = NO;
    
    self.awesomeToolbar = [[BLCAwesomeFloatingToolbar alloc] initWithFourTitles:@[kBLCWebBrowserBackString, kBLCWebBrowserForwardString, kBLCWebBrowserRefreshString, kBLCWebBrowserStopString]];
    self.awesomeToolbar.delegate = self;
    
    for (UIView *viewToAdd in @[self.webView, self.textField, self.awesomeToolbar]) {
        [mainView addSubview:viewToAdd];
    }
    
    self.view = mainView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
   
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    static const CGFloat itemHeight = 50;
    CGFloat width = CGRectGetWidth(self.view.bounds);  //CGRectGetWidth(self.view.frame) ?
    CGFloat height = CGRectGetHeight(self.view.bounds);
    CGFloat browserHeight = CGRectGetHeight(self.view.bounds) - itemHeight;
    
    self.textField.frame = CGRectMake(0, 0, width, itemHeight);
    self.webView.frame = CGRectMake(0, CGRectGetMaxY(self.textField.frame), width, browserHeight);
    
    if(!self.isPanning) {
        CGFloat toolbarX = width/2 - self.toolbarWidth/2;
        CGFloat toolbarY = height/2 - self.toolbarHeight/2;
    
        self.awesomeToolbar.frame = CGRectMake(toolbarX, toolbarY, self.toolbarWidth, self.toolbarHeight);
    }
    self.isPanning = NO;
}

#pragma mark - UITextFieldDelegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    NSString *urlString = textField.text;
    
    NSString *trimmedString = [urlString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSRange whiteSpaceRange = [trimmedString rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]];
    if(whiteSpaceRange.location != NSNotFound) {
        //space found - do google search
        NSString *searchString = [trimmedString stringByReplacingOccurrencesOfString:@" " withString:@"+"];
        NSString *searchUrlString = [NSString stringWithFormat:@"http://www.google.com/search?q=%@", searchString];
        NSURL *url = [NSURL URLWithString:searchUrlString];
        [self makeURLRequest:url];
    }else{
        //load website
        NSURL *url = [NSURL URLWithString:trimmedString];
        
        if(url) {
            if(!url.scheme) {
                url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", trimmedString]];
            }
            [self makeURLRequest:url];
        }
    }
    return NO;
}

-(void)makeURLRequest:(NSURL *)url {
    if(url) {
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        self.frameCount = 0;
        [self.webView loadRequest:request];
    }
}

#pragma mark - UIWebViewDelegate

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if(error.code != -999) {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"error") message:[error localizedDescription] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
    [alert show];
    }
    
    [self updateButtonsAndTitle];
    self.frameCount--;
    NSLog(@"didFail framCount: %d", (int)self.frameCount);
}

-(void)webViewDidStartLoad:(UIWebView *)webView {
    self.frameCount++;
    NSLog(@"startLoad framCount: %d", (int)self.frameCount);

    [self updateButtonsAndTitle];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    self.frameCount--;
    NSLog(@"finishLoad framCount: %d", (int)self.frameCount);
    [self updateButtonsAndTitle];
}

#pragma mark - BLCAwesomeFloatingToolbarDelegate

- (void) floatingToolbar:(BLCAwesomeFloatingToolbar *)toolbar didSelectButtonWithTitle:(NSString *)title {
    if ([title isEqual:kBLCWebBrowserBackString]) {
        [self.webView goBack];
    } else if ([title isEqual:kBLCWebBrowserForwardString]) {
        [self.webView goForward];
    } else if ([title isEqual:kBLCWebBrowserStopString]) {
        [self.webView stopLoading];
    } else if ([title isEqual:kBLCWebBrowserRefreshString]) {
        [self.webView reload];
    }
}

- (void) floatingToolbar:(BLCAwesomeFloatingToolbar *)toolbar didTryToPanWithOffset:(CGPoint)offset {
    CGPoint startingPoint = toolbar.frame.origin;
    CGPoint newPoint = CGPointMake(startingPoint.x + offset.x, startingPoint.y + offset.y);
    
    CGRect potentialNewFrame = CGRectMake(newPoint.x, newPoint.y, CGRectGetWidth(toolbar.frame), CGRectGetHeight(toolbar.frame));
    
    if(CGRectContainsRect(self.view.bounds, potentialNewFrame)) {
        self.isPanning = YES;
        toolbar.frame = potentialNewFrame;
    }
}

- (void) floatingToolbar:(BLCAwesomeFloatingToolbar *)toolbar didTryToPinchWithScale:(CGFloat)scale {
    CGFloat newWidth = self.toolbarWidth *scale;
    CGFloat newHeight = self.toolbarHeight*scale;
    
    if (newWidth > kBLCMinToolbarWidth && newWidth < CGRectGetWidth(self.view.bounds) &&
        newHeight > kBLCMinToolbarHeight && newHeight < CGRectGetHeight(self.view.bounds)){
            
        self.toolbarWidth = self.toolbarWidth *scale;
        self.toolbarHeight = self.toolbarHeight*scale;
        self.awesomeToolbar.transform = CGAffineTransformScale(self.awesomeToolbar.transform, scale, scale);
    }
}

#pragma mark - Miscellaneous

-(void) updateButtonsAndTitle {
    NSString *webpageTitle = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    
    if(webpageTitle) {
        self.title = webpageTitle;
    }else{
        self.title = self.webView.request.URL.absoluteString;
    }
    
    if(self.frameCount > 0) {
         [self.activityIndicator startAnimating];
    }else{
         [self.activityIndicator stopAnimating];
    }
    
    [self.awesomeToolbar setEnabled:[self.webView canGoBack] forButtonWithTitle:kBLCWebBrowserBackString];
    [self.awesomeToolbar setEnabled:[self.webView canGoBack] forButtonWithTitle:kBLCWebBrowserBackString];
    [self.awesomeToolbar setEnabled:[self.webView canGoForward] forButtonWithTitle:kBLCWebBrowserForwardString];
    [self.awesomeToolbar setEnabled:self.frameCount > 0 forButtonWithTitle:kBLCWebBrowserStopString];
    [self.awesomeToolbar setEnabled:self.webView.request.URL && self.frameCount == 0 forButtonWithTitle:kBLCWebBrowserRefreshString];
}

-(void) resetWebView {
    [self.webView removeFromSuperview];
    
    UIWebView *newWebView = [[UIWebView alloc] init];
    newWebView.delegate = self;
    [self.view addSubview:newWebView];
    
    self.webView = newWebView;
    
    self.textField.text = nil;
    [self updateButtonsAndTitle];
}

@end
