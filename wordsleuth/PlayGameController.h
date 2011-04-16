//
//  FirstViewController.h
//  wordsleuth
//
//  Created by Brian D. Elliott on 4/14/11.
//  Copyright 2011 Sparkle Software. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PlayGameController : UIViewController {
    
    NSMutableArray *guesses;
    NSString *closestBeforeGuess;
    NSString *closestAfterGuess;
    
    UITextField *guessTextField;
    UILabel *beforeTextField;
    UILabel *afterTextField;
}

@property (assign) NSInteger numGuesses;
@property (nonatomic, readonly) NSMutableArray *guesses;

@property (nonatomic, retain) NSString *word;

@property (nonatomic, retain) IBOutlet UITextField *guessTextField;
@property (nonatomic, retain) IBOutlet UILabel *numGuessesLabel;

@property (nonatomic, retain) IBOutlet UILabel *beforeTextField;
@property (nonatomic, retain) IBOutlet UILabel *afterTextField;

- (IBAction)guessMade:(id)sender;


- (void)checkGuess:(NSString *)guess;

- (void)guessBeforeWord:(NSString *)guess;
- (void)guessAfterWord:(NSString *)guess;
- (void)guessIsCorrect;

@end
