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

#import "GtInspectorItem.h"

@implementation GtInspectorItem

- (id)init
{
  self = [super init];
  if (self == nil)
    return nil;

  _subitems = @[];

  _min = -HUGE_VAL;
  _max = HUGE_VAL;
  _increment = 1;
  _sliderMin = -HUGE_VAL;
  _sliderMax = HUGE_VAL;

  return self;
}

- (BOOL)isLeaf
{
  return [self.subitems count] == 0;
}

static NSDictionary *_classesDict;
static NSDictionary *_inspectorDict;

static NSMapTable *_classTable;

+ (instancetype)inspectorTreeForClass:(Class)cls
{
  if (_classesDict == nil)
    {
      NSString *path = [[NSBundle mainBundle]
			pathForResource:@"classes" ofType:@"json"];
      if (path == nil)
	return nil;

      NSData *data = [NSData dataWithContentsOfFile:path];
      if (data == nil)
	return nil;

      _classesDict = [NSJSONSerialization
		      JSONObjectWithData:data options:0 error:nil];

      if (_classesDict == nil)
	return nil;
    }

  if (_inspectorDict == nil)
    {
      NSString *path = [[NSBundle mainBundle]
			pathForResource:@"inspector" ofType:@"json"];
      if (path == nil)
	return nil;

      NSData *data = [NSData dataWithContentsOfFile:path];
      if (data == nil)
	return nil;

      _inspectorDict = [NSJSONSerialization
			JSONObjectWithData:data options:0 error:nil];

      if (_inspectorDict == nil)
	return nil;
    }

  if (_classTable == nil)
    _classTable = [NSMapTable strongToStrongObjectsMapTable];

  if (cls == Nil)
    return nil;

  id obj = [_classTable objectForKey:cls];

  if (obj == nil)
    {
      NSMutableArray *items = [NSMutableArray array];

      [self addInspectorItemsForClass:cls toArray:items];

      if ([items count] != 0)
	{
	  GtInspectorItem *root = [[self alloc] init];
	  root.subitems = items;
	  obj = root;
	}
      else
	obj = [NSNull null];

      [_classTable setObject:obj forKey:cls];
    }

  if (![obj isKindOfClass:[GtInspectorItem class]])
    obj = nil;

  return obj;
}

static GtInspectorItem *
inspectorItem(NSDictionary *class_dict, NSDictionary *inspector_dict)
{
  GtInspectorItem *item = [[GtInspectorItem alloc] init];

  item.displayName = inspector_dict[@"displayName"];

  NSMutableArray *subitems = [NSMutableArray array];

  for (id obj in inspector_dict[@"properties"])
    {
      if ([obj isKindOfClass:[NSString class]])
	{
	  NSString *key = obj;

	  NSDictionary *key_dict = class_dict[key];
	  if (key_dict == nil)
	    continue;			/* FIXME: use objc metadata? */

	  GtInspectorItem *key_item = [[GtInspectorItem alloc] init];

	  key_item.key = key;

	  for (NSString *key in key_dict)
	    [key_item setValue:key_dict[key] forKey:key];

	  [subitems addObject:key_item];
	}
      else if ([obj isKindOfClass:[NSDictionary class]])
	{
	  [subitems addObject:inspectorItem(class_dict, obj)];
	}
    }

  item.subitems = subitems;

  return item;
}

+ (void)addInspectorItemsForClass:(Class)cls toArray:(NSMutableArray *)array
{
  if (cls == nil)
    return;

  [self addInspectorItemsForClass:[cls superclass] toArray:array];

  NSString *class_name = NSStringFromClass(cls);

  NSDictionary *class_dict = _classesDict[class_name];
  NSDictionary *inspector_dict = _inspectorDict[class_name];

  if (class_dict != nil && inspector_dict != nil)
    [array addObject:inspectorItem(class_dict, inspector_dict)];
}

@end
