#import "HighriseAccount.h"

@implementation HighriseAccount

+ (void)load { [Account registerClass:self]; }
+ (BOOL)requiresDomain { return YES; }
+ (BOOL)requiresUsername { return YES; }
+ (BOOL)requiresPassword { return YES; }
+ (NSString *)domainSuffix { return @".highrisehq.com"; }

- (void)validateWithPassword:(NSString *)password {
    
    NSString *URL = [NSString stringWithFormat:@"https://%@.highrisehq.com/me.xml", self.domain];
    
    self.request = [SMWebRequest requestWithURLRequest:[NSURLRequest requestWithURLString:URL username:self.username password:password] delegate:nil context:NULL];
    [self.request addTarget:self action:@selector(meRequestComplete:) forRequestEvents:SMWebRequestEventComplete];
    [self.request addTarget:self action:@selector(meRequestError:) forRequestEvents:SMWebRequestEventError];
    [self.request start];
}

- (void)meRequestComplete:(NSData *)data {
    
    SMXMLDocument *document = [SMXMLDocument documentWithData:data error:NULL];
    //NSLog(@"Document: %@", document);

    NSString *myName = [document.root valueWithPath:@"name"];
    NSString *token = [document.root valueWithPath:@"token"];

    NSString *firstName = nil, *lastName = nil;
    NSArray *parts = [myName componentsSeparatedByString:@" "];
    
    if ([parts count] == 2) {
        firstName = parts[0];
        lastName = parts[1];
    }
    
    NSString *mainFeedString = [NSString stringWithFormat:@"https://%@:%@@%@.highrisehq.com/recordings.atom", token, token, self.domain];
    Feed *mainFeed = [Feed feedWithURLString:mainFeedString title:@"Latest Activity" account:self];
    
    if ([firstName length] > 0 && [lastName length] > 0)
        mainFeed.author = [NSString stringWithFormat:@"%@ %@.", firstName, [lastName substringToIndex:1]];
    
    self.feeds = @[mainFeed];
    
    [self.delegate account:self validationDidCompleteWithNewPassword:nil];
}

- (void)meRequestError:(NSError *)error {
    if (error.code == 404)
        [self.delegate account:self validationDidFailWithMessage:@"Could not log in to the given Highrise account. Please check your domain, username, and password." field:0];
    else
        [self.delegate account:self validationDidFailWithMessage:error.localizedDescription field:AccountFailingFieldUnknown];
}

@end
