//
//  SecondViewController.m
//  wordsleuth
//
//  Created by Brian D. Elliott on 4/14/11.
//  Copyright 2011 Sparkle Software. All rights reserved.
//

#import "HighScoresController.h"
#import "wordsleuthAppDelegate.h"

#import "ASIHTTPRequest.h"
#import "NSString+SBJSON.h"
#import "WordURL.h"


@implementation HighScoresController

@synthesize highScoresTableView;
@synthesize timeLeftLabel;

+ (UIColor*) highlightColor {
    return [UIColor colorWithRed:.91f green:.67f blue:.15f alpha:1.0f];
}

-(id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (!self)
        return nil;
    
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.title = @"Best Scores";

    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateTimeLeft) userInfo:nil repeats:YES];
    
    return self;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"FullBackground.png"]];
    self.highScoresTableView.backgroundColor = [UIColor clearColor];
    
    self.highScoresTableView.rowHeight = 34.0f;

    NSLog(@"Loading high scores");
    
    // load the high scores of the day
    NSURL *url = [WordURL getHighScoresURL];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request startSynchronous];
    NSError *error = [request error];
    
    if (error) {
        // TODO failed to get word.  implement a disconnected mode from a limited set of words?
        NSLog(@"high scores load failed, error=%@", error);
        
    } else {
        NSString *response = [request responseString];
        NSDictionary *d = [response JSONValue];
        scores = (NSArray *)[d objectForKey:@"scores"];
        [scores retain];
    }  
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}


- (void)viewDidUnload
{
    [highScoresTableView release];
    highScoresTableView = nil;
    [self setTimeLeftLabel:nil];
    [super viewDidUnload];

    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc
{
    [highScoresTableView release];
    [timeLeftLabel release];
    [super dealloc];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *cellId = @"ScoreCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellId];        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = [UIColor clearColor];        
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.detailTextLabel.textColor = [HighScoresController highlightColor];
        cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:cell.detailTextLabel.font.pointSize];
    }
    
    NSDictionary *score = [scores objectAtIndex:indexPath.row];
    NSString *playerName = [score objectForKey:@"user_name"];
    NSDecimalNumber *numGuesses = [score objectForKey:@"num_guesses"];
    cell.textLabel.text = playerName;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", numGuesses];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSLog(@"numberOfRowsInSection, %d rows", [scores count]);
    return [scores count];
}

+ (void)goToHighScores {
    
    wordsleuthAppDelegate *delegate = (wordsleuthAppDelegate *)[[UIApplication sharedApplication] delegate];
    HighScoresController *highScoresController = [[HighScoresController alloc] initWithNibName:@"HighScores" bundle:nil];
    
    [delegate.navigationController pushViewController:highScoresController animated:TRUE];
    [delegate.navigationController popToViewController:highScoresController animated:TRUE];
    
}

- (void)updateTimeLeft {
    // iphone date/time library is the poo.. the steaming kind
    
    NSDate *now = [NSDate date];
    
    NSDateComponents *offset = [[NSDateComponents alloc] init];
    [offset setDay:1];
    
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *tomorrow = [cal dateByAddingComponents:offset toDate:now options:0];
    
    [offset release];
    
    unsigned flags = (NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit);
    NSDateComponents *comps = [cal components:flags fromDate:tomorrow];
    NSInteger d = [comps day];
    NSInteger m = [comps month];
    NSInteger y = [comps year];

    // now build tomorrow with hour set to 12am when the word rolls over
    comps = [[NSDateComponents alloc] init];
    [comps setYear:y];
    [comps setMonth:m];
    [comps setDay:d];
    [comps setHour:0];
    
    NSDate *midnight = [cal dateFromComponents:comps];
    [comps release];
    
    NSTimeInterval diff = [midnight timeIntervalSinceDate:now];
    int secsuntilmidnight = (int)diff;
    
    int hours = secsuntilmidnight / 3600;
    int remainder = secsuntilmidnight % 3600;
    int minutes = remainder / 60;
    int seconds = remainder % 60;
    
    NSString *timeLeft = [NSString stringWithFormat:@"%d:%d:%d", hours, minutes, seconds];
    
    self.timeLeftLabel.text = timeLeft;
}



@end
