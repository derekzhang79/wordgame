//
//  SecondViewController.h
//  wordsleuth
//
//  Created by Brian D. Elliott on 4/14/11.
//  Copyright 2011 Sparkle Software. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface HighScoresController : UIViewController {
    
    IBOutlet UITableView *highScoresTableView;
}

@property (nonatomic, retain) IBOutlet UITableView *highScoresTableView;
@property (nonatomic, readonly) NSMutableArray *highScores;

@end
