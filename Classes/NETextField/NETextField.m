//
//  NETextField.m
//  MeMe
//
//  Created by Chang Liu on 4/6/18.
//  Copyright © 2018 sip. All rights reserved.
//

#import "NETextField.h"

@implementation NETextField

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldTextDidChange:) name:UITextFieldTextDidChangeNotification object:nil];
        self.limitedNumber = 2147483647;
        self.canPaste = YES;
    }
    return self;
}
// 返回placeholderLabel的bounds，改变返回值，是调整placeholderLabel的位置
- (CGRect)placeholderRectForBounds:(CGRect)bounds {
    return CGRectMake(5, self.placeholderTopOffset , self.bounds.size.width - 5, self.bounds.size.height);
}
// 这个函数是调整placeholder在placeholderLabel中绘制的位置以及范围
- (void)drawPlaceholderInRect:(CGRect)rect {
    [super drawPlaceholderInRect:CGRectMake(0, 0 , self.bounds.size.width, self.bounds.size.height)];
}


#pragma mark -- observer
- (void)textFieldTextDidChange:(NSNotification *)notification {
    if ([notification.object isMemberOfClass:[NETextField class]]) {
        UITextField *textField = notification.object;
        NSString *currentText  = textField.text;
        NSInteger maxLength    = self.limitedNumber;
        NSString *lang = [textField.textInputMode primaryLanguage];
        
        if (self.deleteBlankSpace) {
            currentText = [currentText stringByReplacingOccurrencesOfString:@" " withString:@""];
        }
        
        if (self.contentType == NETextFieldContentTypeNumber) {
            if (![self isPureInt:currentText]) {
                textField.text = nil;
                return;
            }
        }
        
        // 简体中文输入
        if ([lang isEqualToString:@"zh-Hans"]) {
            // 获取高亮部分
            UITextRange *selectedRange = [textField markedTextRange];
            UITextPosition *position = [textField positionFromPosition:selectedRange.start offset:0];
            
            // 没有高亮选择的字，则对已输入的文字进行字数统计和限制
            if (!position) {
                if (currentText.length > maxLength) {
                    textField.text = [currentText substringToIndex:maxLength];
                } else {
                    textField.text = currentText;
                }
            }
            
        }
        // 中文输入法以外的直接对其统计限制即可，不考虑其他语种情况
        else {
            if (currentText.length > maxLength) {
                NSRange rangeIndex = [currentText rangeOfComposedCharacterSequenceAtIndex:maxLength];
                if (rangeIndex.length == 1) {
                    textField.text = [currentText substringToIndex:maxLength];
                } else {
                    NSRange rangeRange = [currentText rangeOfComposedCharacterSequencesForRange:NSMakeRange(0, maxLength)];
                    textField.text = [currentText substringWithRange:rangeRange];
                }
            }
        }
        if (self.textDidChanged) {
            self.textDidChanged(textField.text);
        }
    }
}

// 判断字符串是否全为数字
- (BOOL)isPureInt:(NSString*)string{
    NSScanner* scan = [NSScanner scannerWithString:string];
    int val;
    return[scan scanInt:&val] && [scan isAtEnd];
}

- (void)setContentType:(NETextFieldContentType)contentType {
    _contentType = contentType;
    if (contentType == NETextFieldContentTypeNumber) {
        [self setKeyboardType:UIKeyboardTypeNumberPad];
    }
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(copy:) || action == @selector(paste:)) {
        if (self.canPaste) {
            return YES;
        } else {
            return NO;
        }
    }
    return YES;
}

// 解决iOS 11.2 textfield内存泄漏问题
- (void)didMoveToWindow {
    [super didMoveToWindow];
    if (@available(iOS 11.2, *)) {
        NSString *keyPath = @"textContentView.provider";
        @try {
            if (self.window) {
                id provider = [self valueForKeyPath:keyPath];
                if (!provider && self) {
                    [self setValue:self forKeyPath:keyPath];
                }
            } else {
                [self setValue:nil forKeyPath:keyPath];
            }
        } @catch (NSException *exception) {
            NSLog(@"%@", exception);
        }
    }
}

@end
