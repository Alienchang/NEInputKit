//
//  NETextView.m
//  MeMe
//
//  Created by Chang Liu on 4/9/18.
//  Copyright © 2018 sip. All rights reserved.
//

#import "NETextView.h"

@implementation NETextView

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewTextDidChange:) name:UITextViewTextDidChangeNotification object:nil];
    }
    return self;
}

- (void)textViewTextDidChange:(NSNotification *)notification {
    if ([notification.object isKindOfClass:[UITextView class]]) {
        UITextView *textView = (UITextView *)notification.object;
        if (self != textView) {
            return;
        }
        NSString *currentText = textView.text;
        NSInteger maxLength = self.limitedNumber;
        UITextPosition *position = nil;
        if ([textView markedTextRange]) {
            position = [textView positionFromPosition:[textView markedTextRange].start offset:0];
        }
        
        if (!position) {
            BOOL flag = NO;
            if (currentText.length > maxLength) {
                textView.text = [currentText substringToIndex:maxLength];
                flag = YES;
            }
            
            if (self.selectedRange.length > 0 && self.selectedRange.length + self.selectedRange.location <= currentText.length) {
                NSString *limitedText = [currentText substringWithRange:self.selectedRange];
                textView.text = [textView.text stringByReplacingOccurrencesOfString:limitedText withString:@""];
                self.selectedRange = NSMakeRange(0, 0);
                if (limitedText.length > 0) {
                    flag = YES;
                }
            }
            if (self.textLengthChanged) {
                self.textLengthChanged(textView.text.length);
            }
        }
    }
}

@end
