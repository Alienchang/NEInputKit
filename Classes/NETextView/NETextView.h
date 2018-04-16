//
//  NETextView.h
//  MeMe
//
//  Created by Chang Liu on 4/9/18.
//  Copyright © 2018 sip. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NETextView : UITextView
@property (nonatomic ,copy)   void(^textLengthChanged)(NSInteger);
@property (nonatomic ,assign) NSInteger limitedNumber;
@end
