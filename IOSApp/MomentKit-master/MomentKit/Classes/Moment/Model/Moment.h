//
//  Moment.h
//  MomentKit
//
//  Created by LEA on 2017/12/12.
//  Copyright © 2017年 LEA. All rights reserved.
//
//  动态Model
//

#import <Foundation/Foundation.h>

@interface Moment : NSObject

// 正文
@property (nonatomic,copy) NSString *text;
// 发布位置
@property (nonatomic,copy) NSString *location;
// 发布者名字
@property (nonatomic,copy) NSString *userName;
// 发布者头像路径[本地路径]
@property (nonatomic,copy) NSString *userThumbPath;
// 赞的人[逗号隔开的字符串]
@property (nonatomic,copy) NSString *praiseNameList;
// 单张图片的宽度
@property (nonatomic,assign) CGFloat singleWidth;
// 单张图片的高度
@property (nonatomic,assign) CGFloat singleHeight;
// 图片数量
@property (nonatomic,assign) NSInteger fileCount;
// 发布时间戳
@property (nonatomic,assign) long long time;
// 显示'全文'/'收起'
@property (nonatomic,assign) BOOL isFullText;
// 是否已经点赞
@property (nonatomic,assign) BOOL isPraise;
// 评论集合
@property (nonatomic,strong) NSArray *commentList;
// Moment对应cell高度
@property (nonatomic,assign) CGFloat rowHeight;

@end