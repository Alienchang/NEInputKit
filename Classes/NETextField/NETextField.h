//
//  NETextField.h
//  MeMe
//
//  Created by Chang Liu on 4/6/18.
//  Copyright © 2018 sip. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    NETextFieldContentTypeDefault,
    NETextFieldContentTypeNumber,
} NETextFieldContentType;

@interface NETextField : UITextField
@property (nonatomic ,assign) CGFloat placeholderTopOffset;
@property (nonatomic ,assign) NSInteger limitedNumber;
@property (nonatomic ,copy)   void(^textDidChanged)(NSString *);
@property (nonatomic ,assign) NETextFieldContentType contentType;
@property (nonatomic ,assign) BOOL deleteBlankSpace;
@property (nonatomic ,assign) BOOL canPaste;
@end
