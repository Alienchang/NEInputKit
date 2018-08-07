//
//  NETextView.m
//  MeMe
//
//  Created by Chang Liu on 4/9/18.
//  Copyright © 2018 sip. All rights reserved.
//

#import "NETextView.h"
#import <objc/runtime.h>

@implementation NETextView

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

#pragma mark - Swizzle Dealloc
+ (void)load {
    // is this the best solution?
    if ([self isMemberOfClass:[NETextView class]]) {
        method_exchangeImplementations(class_getInstanceMethod(self.class, NSSelectorFromString(@"dealloc")),
                                       class_getInstanceMethod(self.class, @selector(swizzledDealloc)));
    }
}

- (void)swizzledDealloc {
    if ([self isMemberOfClass:[NETextView class]]) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        UILabel *label = objc_getAssociatedObject(self, @selector(placeholderLabel));
        if (label) {
            for (NSString *key in self.class.observingKeys) {
                @try {
                    [self removeObserver:self forKeyPath:key];
                }
                @catch (NSException *exception) {
                    // Do nothing
                }
            }
        }
        [self swizzledDealloc];
    }
}


#pragma mark - Class Methods
#pragma mark `defaultPlaceholderColor`

+ (UIColor *)defaultPlaceholderColor {
    static UIColor *color = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UITextField *textField = [[UITextField alloc] init];
        textField.placeholder = @" ";
        [textField setTintColor:[UIColor lightGrayColor]];
        color = [textField valueForKeyPath:@"_placeholderLabel.textColor"];
    });
    return color;
}


#pragma mark - `observingKeys`

+ (NSArray *)observingKeys {
    return @[@"attributedText",
             @"bounds",
             @"font",
             @"frame",
             @"text",
             @"textAlignment",
             @"textContainerInset"];
}


#pragma mark - Properties
#pragma mark `placeholderLabel`

- (UILabel *)placeholderLabel {
    if (!_placeholderLabel) {
        NSAttributedString *originalText = self.attributedText;
        self.text = @" "; // lazily set font of `UITextView`.
        self.attributedText = originalText;
        
        _placeholderLabel = [[UILabel alloc] init];
        _placeholderLabel.textColor = [self.class defaultPlaceholderColor];
        _placeholderLabel.numberOfLines = 0;
        _placeholderLabel.userInteractionEnabled = NO;
        self.needsUpdateFont = YES;
        [self updatePlaceholderLabel];
        self.needsUpdateFont = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updatePlaceholderLabel)
                                                     name:UITextViewTextDidChangeNotification
                                                   object:self];
        
        for (NSString *key in self.class.observingKeys) {
            [self addObserver:self forKeyPath:key options:NSKeyValueObservingOptionNew context:nil];
        }
    }
    return _placeholderLabel;
}


#pragma mark `placeholder`

- (NSString *)placeholder {
    return self.placeholderLabel.text;
}

- (void)setPlaceholder:(NSString *)placeholder {
    self.placeholderLabel.text = placeholder;
    [self updatePlaceholderLabel];
}

- (NSAttributedString *)attributedPlaceholder {
    return self.placeholderLabel.attributedText;
}

- (void)setAttributedPlaceholder:(NSAttributedString *)attributedPlaceholder {
    self.placeholderLabel.attributedText = attributedPlaceholder;
    [self updatePlaceholderLabel];
}

#pragma mark `placeholderColor`

- (UIColor *)placeholderColor {
    return self.placeholderLabel.textColor;
}

- (void)setPlaceholderColor:(UIColor *)placeholderColor {
    self.placeholderLabel.textColor = placeholderColor;
}


#pragma mark `needsUpdateFont`

- (BOOL)needsUpdateFont {
    return [objc_getAssociatedObject(self, @selector(needsUpdateFont)) boolValue];
}

- (void)setNeedsUpdateFont:(BOOL)needsUpdate {
    objc_setAssociatedObject(self, @selector(needsUpdateFont), @(needsUpdate), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:@"font"]) {
        self.needsUpdateFont = (change[NSKeyValueChangeNewKey] != nil);
    }
    [self updatePlaceholderLabel];
}


#pragma mark - Update

- (void)updatePlaceholderLabel {
    if (self.text.length) {
        [self.placeholderLabel removeFromSuperview];
        return;
    }
    
    [self insertSubview:self.placeholderLabel atIndex:0];
    
    if (self.needsUpdateFont) {
        self.placeholderLabel.font = self.font;
        self.needsUpdateFont = NO;
    }
    self.placeholderLabel.textAlignment = self.textAlignment;
    
    // `NSTextContainer` is available since iOS 7
    CGFloat lineFragmentPadding;
    UIEdgeInsets textContainerInset;
    
#pragma deploymate push "ignored-api-availability"
    // iOS 7+
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        lineFragmentPadding = self.textContainer.lineFragmentPadding;
        textContainerInset = self.textContainerInset;
    }
#pragma deploymate pop
    
    // iOS 6
    else {
        lineFragmentPadding = 5;
        textContainerInset = UIEdgeInsetsMake(8, 0, 8, 0);
    }
    
    CGFloat x = lineFragmentPadding + textContainerInset.left;
    CGFloat y = textContainerInset.top;
    CGFloat width = CGRectGetWidth(self.bounds) - x - lineFragmentPadding - textContainerInset.right;
    CGFloat height = [self.placeholderLabel sizeThatFits:CGSizeMake(width, 0)].height;
    self.placeholderLabel.frame = CGRectMake(x, y, width, height);
}

@end
