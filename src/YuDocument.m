/* -*- c-style: gnu -*-

   Copyright (c) 2014 John Harper <jsh@unfactored.org>

   Permission is hereby granted, free of charge, to any person
   obtaining a copy of this software and associated documentation files
   (the "Software"), to deal in the Software without restriction,
   including without limitation the rights to use, copy, modify, merge,
   publish, distribute, sublicense, and/or sell copies of the Software,
   and to permit persons to whom the Software is furnished to do so,
   subject to the following conditions:

   The above copyright notice and this permission notice shall be
   included in all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
   NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
   BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
   ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
   CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
   SOFTWARE. */

#import "YuDocument.h"

#import "YuWindowController.h"

#import "MgCoderExtensions.h"

NSString *const YuDocumentNodeDidChange = @"YuDocumentNodeDidChange";
NSString *const YuDocumentSizeDidChange = @"YuDocumentSizeDidChange";

@implementation YuDocument
{
  YuWindowController *_controller;
  CGSize _documentSize;
  MgDrawableNode *_documentNode;
}

@synthesize controller = _controller;

- (id)init
{
  self = [super init];
  if (self == nil)
    return nil;

  _controller = [[YuWindowController alloc] init];

  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  CGFloat width = [defaults doubleForKey:@"YuDefaultDocumentWidth"];
  CGFloat height = [defaults doubleForKey:@"YuDefaultDocumentHeight"];

  MgLayerNode *node = [MgLayerNode node];

  node.name = @"Root Layer";
  node.bounds = CGRectMake(0, 0, width, height);
  node.position = CGPointMake(width * .5, height * .5);

  self.documentSize = CGSizeMake(width, height);
  self.documentNode = node;

#if 1
  MgRectNode *bg_rect = [MgRectNode node];
  bg_rect.fillColor = [[NSColor lightGrayColor] CGColor];
  [node addContentNode:bg_rect];

  MgLayerNode *image_layer = [MgLayerNode node];
  image_layer.position = CGPointMake(700, 400);
  image_layer.bounds = CGRectMake(0, 0, 512, 512);
  image_layer.rotation = -10 * (M_PI / 180);
  [node addContentNode:image_layer];
  MgImageNode *image_node = [MgImageNode node];
  image_node.imageProvider = [MgImageProvider imageProviderWithURL:
			      [NSURL fileURLWithPath:
			       @"/Library/User Pictures/Animals/Parrot.tif"]];
  [image_layer addContentNode:image_node];

  MgLayerNode *rect_layer = [MgLayerNode node];
  rect_layer.position = CGPointMake(350, 300);
  rect_layer.bounds = CGRectMake(0, 0, 400, 250);
  rect_layer.cornerRadius = 8;
  rect_layer.alpha = .5;
  [node addContentNode:rect_layer];
  MgRectNode *rect_node = [MgRectNode node];
  rect_node.fillColor = [[NSColor blueColor] CGColor];
  [rect_layer addContentNode:rect_node];
#endif

  return self;
}

- (void)makeWindowControllers
{
  [self addWindowController:_controller];
}

- (CGSize)documentSize
{
  return _documentSize;
}

- (void)setDocumentSize:(CGSize)s
{
  if (!CGSizeEqualToSize(_documentSize, s))
    {
      _documentSize = s;

      [[NSNotificationCenter defaultCenter]
       postNotificationName:YuDocumentSizeDidChange object:self];
    }
}

- (MgDrawableNode *)documentNode
{
  return _documentNode;
}

- (void)setDocumentNode:(MgDrawableNode *)node
{
  if (_documentNode != node)
    {
      _documentNode = node;

      [[NSNotificationCenter defaultCenter]
       postNotificationName:YuDocumentNodeDidChange object:self];
    }
}

+ (BOOL)autosavesInPlace
{
  return NO;
}

- (NSData *)dataOfType:(NSString *)type error:(NSError **)err
{
  if ([type isEqualToString:@"org.unfactored.mg-archive"])
    {
      NSMutableData *data = [NSMutableData data];

      NSKeyedArchiver *archiver
	= [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];

      [archiver setDelegate:self];
      [archiver mg_encodeCGSize:_documentSize forKey:@"documentSize"];
      [archiver encodeObject:_documentNode forKey:@"documentNode"];
      [archiver finishEncoding];

      return data;
    }
  else
    return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)type
    error:(NSError **)err
{
  if ([type isEqualToString:@"org.unfactored.mg-archive"])
    {
      NSKeyedUnarchiver *unarchiver
        = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];

      [unarchiver setDelegate:self];

      _documentSize = [unarchiver mg_decodeCGSizeForKey:@"documentSize"];
      _documentNode = [unarchiver decodeObjectOfClass:
		       [MgDrawableNode class] forKey:@"documentNode"];

      [unarchiver finishDecoding];

      return YES;
    }

  return NO;
}

@end
