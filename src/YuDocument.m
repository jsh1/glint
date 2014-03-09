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

#import "YuTreeNode.h"
#import "YuWindowController.h"

#import "MgCoderExtensions.h"

NSString *const YuDocumentGraphDidChange = @"YuDocumentGraphDidChange";

@implementation YuDocument
{
  YuWindowController *_controller;
  CGSize _documentSize;
  MgDrawableNode *_documentNode;
  int _undoDisable;
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
  bg_rect.name = @"BG Fill";
  [node addContent:bg_rect];

  MgLayerNode *image_layer = [MgLayerNode node];
  image_layer.position = CGPointMake(700, 400);
  image_layer.bounds = CGRectMake(0, 0, 512, 512);
  image_layer.rotation = -10 * (M_PI / 180);
  image_layer.name = @"Image Layer";
  [node addContent:image_layer];
  MgImageNode *image_node = [MgImageNode node];
  image_node.imageProvider = [MgImageProvider imageProviderWithURL:
			      [NSURL fileURLWithPath:
			       @"/Library/User Pictures/Animals/Parrot.tif"]];
  image_node.name = @"Image";
  [image_layer addContent:image_node];

#if 1
  MgLayerNode *image_layer2 = [MgLayerNode node];
  image_layer2.position = CGPointMake(-200, 300);
  image_layer2.bounds = CGRectMake(0, 0, 512, 512);
  image_layer2.alpha = .25;
  image_layer2.name = @"Image Link";
  [image_layer2 addContent:image_layer];
  [node addContent:image_layer2];
#endif

  MgLayerNode *rect_layer = [MgLayerNode node];
  rect_layer.position = CGPointMake(350, 300);
  rect_layer.bounds = CGRectMake(0, 0, 400, 250);
  rect_layer.cornerRadius = 8;
  rect_layer.alpha = .5;
  rect_layer.name = @"Rect Layer";
  [node addContent:rect_layer];
  MgRectNode *rect_node = [MgRectNode node];
  rect_node.fillColor = [[NSColor blueColor] CGColor];
  rect_node.name = @"Rect Fill";
  [rect_layer addContent:rect_node];
#endif

  return self;
}

- (void)makeWindowControllers
{
  [self addWindowController:_controller];
}

+ (BOOL)automaticallyNotifiesObserversOfDocumentSize
{
  return NO;
}

- (CGSize)documentSize
{
  return _documentSize;
}

- (void)setDocumentSize:(CGSize)s
{
  if (!CGSizeEqualToSize(_documentSize, s))
    {
      [self willChangeValueForKey:@"documentSize"];
      _documentSize = s;
      [self didChangeValueForKey:@"documentSize"];
    }
}

+ (BOOL)automaticallyNotifiesObserversOfDocumentNode
{
  return NO;
}

- (MgDrawableNode *)documentNode
{
  return _documentNode;
}

- (void)setDocumentNode:(MgDrawableNode *)node
{
  if (_documentNode != node)
    {
      [self willChangeValueForKey:@"documentNode"];
      _documentNode = node;
      [self didChangeValueForKey:@"documentNode"];
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

      self.documentSize = [unarchiver mg_decodeCGSizeForKey:@"documentSize"];
      self.documentNode = [unarchiver decodeObjectOfClass:
			   [MgDrawableNode class] forKey:@"documentNode"];

      [unarchiver finishDecoding];

      return YES;
    }

  return NO;
}

- (void)disableUndo
{
  _undoDisable++;
}

- (void)reenableUndo
{
  _undoDisable--;
}

- (BOOL)isUndoEnabled
{
  return _undoDisable == 0;
}

- (void)registerUndo:(void (^)())thunk
{
  if (_undoDisable == 0)
    {
      [[self undoManager] registerUndoWithTarget:self
       selector:@selector(_runUndo:) object:[thunk copy]];
    }
}

- (void)_runUndo:(void (^)())thunk
{
  thunk();
}

static NSString *
makeUniqueName(NSArray *nodes, NSString *stem)
{
  for (NSInteger i = 1;; i++)
    {
      NSString *name = stem;
      if (i > 1)
	name = [NSString stringWithFormat:@"%@ %ld", name, (long)i];

      BOOL unique = YES;
      for (MgNode *node in nodes)
	{
	  if ([node.name isEqualToString:name])
	    {
	      unique = NO;
	      break;
	    }
	}

      if (unique)
	return name;
    }
}

/* Returns map from YuTreeNode<MgLayerNode> -> @(index-in-parent). */

static NSMapTable *
findInsertionLayers(YuDocument *self)
{
  NSMapTable *layers = [NSMapTable strongToStrongObjectsMapTable];

  for (YuTreeNode *tn in self.controller.selection)
    {
      if (![tn.node isKindOfClass:[MgDrawableNode class]])
	continue;

      YuTreeNode *n = tn;
      NSInteger idx = NSNotFound;
      while (n != nil)
	{
	  if ([n.node isKindOfClass:[MgLayerNode class]])
	    break;
	  YuTreeNode *p = n.parent;
	  idx = [p.children indexOfObjectIdenticalTo:n];
	  if (idx != NSNotFound)
	    idx = idx + 1;
	  n = p;
	}
      if (n != nil)
	[layers setObject:@(idx) forKey:n];
    }

  if ([layers count] == 0)
    [layers setObject:@(NSNotFound) forKey:self.controller.tree];

  return layers;
}

/* ADDED is map from MgNode -> YuTreeNode<MgLayerNode>. */

static NSArray *
makeSelectionArray(NSMapTable *added)
{
  NSMutableArray *selection = [NSMutableArray array];

  for (MgNode *node in added)
    {
      YuTreeNode *parent = [added objectForKey:node];

      for (YuTreeNode *tn in parent.children)
	{
	  if (tn.node == node)
	    [selection addObject:tn];
	}
    }

  return selection;
}

- (IBAction)insertLayer:(id)sender
{
  NSMapTable *layers = findInsertionLayers(self);

  NSMapTable *added = [NSMapTable strongToStrongObjectsMapTable];

  for (YuTreeNode *parent in layers)
    {
      MgLayerNode *parent_layer = (MgLayerNode *)parent.node;
      MgLayerNode *layer = [MgLayerNode node];
      layer.name = makeUniqueName(parent_layer.contents, @"Layer");
      CGRect bounds = parent_layer.bounds;
      layer.bounds = bounds;
      layer.position = CGPointMake(CGRectGetMidX(bounds),
				   CGRectGetMidY(bounds));

      NSInteger idx = [[layers objectForKey:parent] integerValue];
      if (idx == NSNotFound)
	idx = [parent_layer.contents count];

      [self insertContent:layer intoLayer:parent_layer atIndex:idx];

      [added setObject:parent forKey:layer];
    }

  self.controller.selection = makeSelectionArray(added);
}

- (IBAction)insertTimeline:(id)sender
{
  /* FIXME: implement this. */
}

- (IBAction)addContent:(id)sender
{
  NSMapTable *layers = findInsertionLayers(self);
  NSInteger tag = [sender tag];

  NSMapTable *added = [NSMapTable strongToStrongObjectsMapTable];

  for (YuTreeNode *parent in layers)
    {
      MgLayerNode *parent_layer = (MgLayerNode *)parent.node;
      
      MgDrawableNode *node = nil;
      NSString *name = nil;

      if (tag == 0)
	{
	  node = [[MgImageNode alloc] init];
	  name = @"Image";
	}
      else if (tag == 1)
	{
	  node = [[MgGradientNode alloc] init];
	  name = @"Gradient";
	}
      else if (tag == 2 || tag == 3)
	{
	  node = [[MgRectNode alloc] init];
	  name = @"Rect";
	  if (tag == 3)
	    ((MgRectNode *)node).drawingMode = kCGPathStroke;
	}
      else if (tag == 4 || tag == 5)
	{
	  node = [[MgPathNode alloc] init];
	  name = @"Path";
	  if (tag == 5)
	    ((MgPathNode *)node).drawingMode = kCGPathStroke;
	}
      else
	return;

      node.name = makeUniqueName(parent_layer.contents, name);

      NSInteger idx = [[layers objectForKey:parent] integerValue];
      if (idx == NSNotFound)
	idx = [parent_layer.contents count];

      [self insertContent:node intoLayer:parent_layer atIndex:idx];

      [added setObject:parent forKey:node];
    }

  self.controller.selection = makeSelectionArray(added);
}

- (IBAction)addAnimation:(id)sender
{
  /* FIXME: implement this. */
}

- (IBAction)embedInLayer:(id)sender
{
  /* FIXME: implement this. */
}

- (IBAction)unembed:(id)sender
{
  /* FIXME: implement this. */
}

static void
documentGraphChanged(YuDocument *self)
{
  [[NSNotificationCenter defaultCenter]
   postNotificationName:YuDocumentGraphDidChange object:self];
}

- (void)insertContent:(MgDrawableNode *)node intoLayer:(MgLayerNode *)parent
    atIndex:(NSInteger)idx
{
  if (idx < 0)
    return;

  NSInteger count = [parent.contents count];
  if (idx > count)
    idx = count;

  [self registerUndo:^
    {
      [self removeContentFromLayer:parent atIndex:idx];
    }];

  [parent insertContent:node atIndex:idx];

  documentGraphChanged(self);
}

- (void)removeContentFromLayer:(MgLayerNode *)parent atIndex:(NSInteger)idx
{
  if (idx < 0 || idx >= [parent.contents count])
    return;

  MgDrawableNode *node = parent.contents[idx];

  [self registerUndo:^
    {
      [self insertContent:node intoLayer:parent atIndex:idx];
    }];

  [parent removeContentAtIndex:idx];

  documentGraphChanged(self);
}

- (void)node:(YuTreeNode *)tn setValue:(id)value forKey:(NSString *)key
{
  MgNode *node = tn.node;

  id oldValue = [node valueForKey:key];

  if (oldValue != value && ![oldValue isEqual:value])
    {
      [self registerUndo:^
        {
	  [self node:tn setValue:oldValue forKey:key];
	}];

      [node setValue:value forKey:key];
    }
}

@end
