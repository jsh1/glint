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

static void
makeNameUnique(MgNode *node, MgNode *parent)
{
  for (NSInteger i = 1;; i++)
    {
      NSString *name = node.name;
      if (i > 1)
	name = [NSString stringWithFormat:@"%@ %ld", name, (long)i];

      __block BOOL unique = YES;

      [parent foreachNode:^(MgNode *node)
        {
	  if ([node.name isEqualToString:name])
	    unique = NO;
	}];

      if (unique)
	{
	  node.name = name;
	  return;
	}
    }
}

static void
initializeLayerFromContainer(MgLayerNode *layer, MgLayerNode *container)
{
  CGRect bounds = (container != nil ? container.bounds
		   : CGRectMake(0, 0, 512, 512));

  layer.bounds = bounds;
  layer.position = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
}

static NSArray *
makeSelectionArray1(YuTreeNode *parent, MgNode *node)
{
  NSMutableArray *selection = [NSMutableArray array];

  for (YuTreeNode *tn in parent.children)
    {
      if (tn.node == node)
	[selection addObject:tn];
    }

  return selection;
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

- (void)addLayerContent:(MgDrawableNode *(^)(MgLayerNode *parent_layer))block
{
  NSMapTable *layers = [NSMapTable strongToStrongObjectsMapTable];
  NSMutableSet *nodes = [NSMutableSet set];

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
	  if ([n.parentKey isEqualToString:@"contents"])
	    idx = n.parentIndex;
	  else
	    idx = NSNotFound;
	  if (idx != NSNotFound)
	    idx = idx + 1;
	  n = p;
	}
      if (n == nil)
	continue;

      if ([nodes containsObject:n.node])
	continue;

      [layers setObject:@(idx) forKey:n];
      [nodes addObject:n.node];
    }

  if ([layers count] == 0)
    [layers setObject:@(NSNotFound) forKey:self.controller.tree];

  NSMapTable *added = [NSMapTable strongToStrongObjectsMapTable];

  for (YuTreeNode *parent in layers)
    {
      MgLayerNode *parent_layer = (MgLayerNode *)parent.node;

      MgDrawableNode *content = block(parent_layer);

      if (content != nil)
	{
	  NSInteger idx = [[layers objectForKey:parent] integerValue];
	  if (idx == NSNotFound)
	    idx = [parent_layer.contents count];

	  [self node:parent insertObject:content atIndex:idx
	   forKey:@"contents"];

	  [added setObject:parent forKey:content];
	}
    }

  self.controller.selection = makeSelectionArray(added);
}

- (IBAction)insertLayer:(id)sender
{
  [self addLayerContent:^MgDrawableNode * (MgLayerNode *parent_layer)
    {
      MgLayerNode *layer = [MgLayerNode node];
      initializeLayerFromContainer(layer, parent_layer);
      layer.name = @"Layer";
      makeNameUnique(layer, parent_layer);
      return layer;
    }];
}

- (IBAction)addContent:(id)sender
{
  NSInteger tag = [sender tag];

  [self addLayerContent:^MgDrawableNode * (MgLayerNode *parent_layer)
    {
      MgDrawableNode *node = nil;

      if (tag == 0)
	{
	  node = [[MgImageNode alloc] init];
	  node.name = @"Image";
	}
      else if (tag == 1)
	{
	  node = [[MgGradientNode alloc] init];
	  node.name = @"Gradient";
	}
      else if (tag == 2 || tag == 3)
	{
	  node = [[MgRectNode alloc] init];
	  node.name = @"Rect";
	  if (tag == 3)
	    ((MgRectNode *)node).drawingMode = kCGPathStroke;
	}
      else if (tag == 4 || tag == 5)
	{
	  node = [[MgPathNode alloc] init];
	  node.name = @"Path";
	  if (tag == 5)
	    ((MgPathNode *)node).drawingMode = kCGPathStroke;
	}
      else
	return nil;

      makeNameUnique(node, parent_layer);
      return node;
    }];
}

- (IBAction)addAnimation:(id)sender
{
  /* FIXME: implement this. */
}

- (IBAction)embedIn:(id)sender
{
  NSInteger tag = [sender tag];

  NSMutableSet *nodes = [NSMutableSet set];
  NSMapTable *added = [NSMapTable strongToStrongObjectsMapTable];

  for (YuTreeNode *tn in self.controller.selection)
    {
      YuTreeNode *parent = tn.parent;
      if (parent == nil)
	continue;
      if ([nodes containsObject:tn.node])
	continue;
      if (![tn.node isKindOfClass:[MgDrawableNode class]])
	continue;

      MgDrawableNode *node = nil;

      switch (tag)
	{
	case 0: {
	  MgLayerNode *layer = [MgLayerNode node];
	  layer.name = @"Layer";
	  initializeLayerFromContainer(layer, (MgLayerNode *)
				       [tn containingLayer].node);
	  [layer addContent:(MgDrawableNode *)tn.node];
	  node = layer;
	  break; }

	case 1: {
	  MgTimelineNode *timeline = [MgTimelineNode node];
	  timeline.name = @"Timeline";
	  timeline.node = (MgDrawableNode *)tn.node;
	  node = timeline;
	  break; }
	}

      if (node == nil)
	continue;

      makeNameUnique(node, parent.node);

      [self replaceTreeNode:tn with:node];

      [added setObject:parent forKey:node];
    }

  self.controller.selection = makeSelectionArray(added);
}

- (IBAction)group:(id)sender
{
  YuTreeNode *master = nil;

  NSMutableArray *group = [NSMutableArray array];
  NSMutableSet *nodes = [NSMutableSet set];

  for (YuTreeNode *tn in self.controller.selection)
    {
      if ([nodes containsObject:tn.node])
	continue;

      if (master == nil || [master isDescendantOf:tn])
	master = tn;

      [group addObject:tn];
      [nodes addObject:tn.node];
    }

  if (master == nil)
    return;

  YuTreeNode *container = [master containingLayer];
  if (container == nil)
    return;

  MgLayerNode *container_layer = (MgLayerNode *)container.node;

  MgLayerNode *layer = [MgLayerNode node];
  layer.name = @"Group";
  if (container == master)
    makeNameUnique(layer, container_layer);

  initializeLayerFromContainer(layer, container_layer);

  for (YuTreeNode *tn in group)
    {
      if (tn != master)
	[self removeTreeNodeFromParent:tn];

      MgDrawableNode *node = (MgDrawableNode *)tn.node;
      [layer addContent:node];
    }

  YuTreeNode *parent = master.parent;

  [self replaceTreeNode:master with:layer];

  self.controller.selection = makeSelectionArray1(parent, layer);
}

- (IBAction)ungroup:(id)sender
{
  NSMutableSet *set = [NSMutableSet set];

  NSMapTable *added = [NSMapTable strongToStrongObjectsMapTable];

  for (YuTreeNode *tn in self.controller.selection)
    {
      MgLayerNode *layer = (MgLayerNode *)tn.node;
      if (![layer isKindOfClass:[MgLayerNode class]])
	continue;
      if (layer.mask != nil)
	continue;

      YuTreeNode *parent = tn.parent;
      if (parent == nil)
	continue;

      NSInteger idx = tn.parentIndex;
      if (idx == NSNotFound)
	{
	  idx = NSIntegerMax;
	  if ([layer.contents count] > 1)
	    continue;
	}

      if ([set containsObject:layer])
	continue;

      [self removeTreeNodeFromParent:tn];

      for (MgDrawableNode *child in layer.contents)
	{
	  [self node:parent insertObject:child atIndex:idx++
	   forKey:@"contents"];

	  [added setObject:parent forKey:child];
	}

      [set addObject:layer];
    }

  self.controller.selection = makeSelectionArray(added);
}

- (void)removeTreeNodeFromParent:(YuTreeNode *)tn
{
  YuTreeNode *parent = tn.parent;
  if (parent == nil)
    return;

  NSString *key = tn.parentKey;
  NSInteger idx = tn.parentIndex;

  if (idx != NSNotFound)
    {
      /* Array key. */

      [self node:parent removeObjectAtIndex:idx forKey:key];
    }
  else
    {
      [self node:parent setValue:nil forKey:key];
    }
}

- (void)replaceTreeNode:(YuTreeNode *)tn with:(MgNode *)node
{
  YuTreeNode *parent = tn.parent;
  if (parent == nil)
    return;

  NSString *key = tn.parentKey;
  NSInteger idx = tn.parentIndex;

  if (idx != NSNotFound)
    {
      /* Array key. */

      [self node:parent replaceObjectAtIndex:idx withObject:node forKey:key];
    }
  else
    {
      [self node:parent setValue:node forKey:key];
    }
}

static void
documentGraphChanged(YuDocument *self)
{
  [[NSNotificationCenter defaultCenter]
   postNotificationName:YuDocumentGraphDidChange object:self];
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

      /* FIXME: heinous. */

      if ([key isEqualToString:@"mask"]
	  || [key isEqualToString:@"node"])
	{
	  documentGraphChanged(self);
	}
    }
}

- (void)node:(YuTreeNode *)tn insertObject:(id)value atIndex:(NSInteger)idx
    forKey:(NSString *)key
{
  assert(value != nil);
  assert(idx >= 0);

  MgNode *node = tn.node;

  NSArray *array = [node valueForKey:key];

  if (idx > [array count])
    idx = [array count];

  [self registerUndo:^
   {
     [self node:tn removeObjectAtIndex:idx forKey:key];
   }];

  NSMutableArray *m_array = [NSMutableArray arrayWithArray:array];
  [m_array insertObject:value atIndex:idx];
  [node setValue:m_array forKey:key];

  documentGraphChanged(self);
}

- (void)node:(YuTreeNode *)tn replaceObjectAtIndex:(NSInteger)idx
    withObject:(id)value forKey:(NSString *)key
{
  assert(value != nil);

  MgNode *node = tn.node;

  NSArray *array = [node valueForKey:key];

  assert(array != nil);
  assert(idx >= 0 && idx < [array count]);

  id oldValue = array[idx];

  [self registerUndo:^
    {
      [self node:tn replaceObjectAtIndex:idx withObject:oldValue forKey:key];
    }];

  NSMutableArray *m_array = [NSMutableArray arrayWithArray:array];
  [m_array replaceObjectAtIndex:idx withObject:value];
  [node setValue:m_array forKey:key];

  documentGraphChanged(self);
}

- (void)node:(YuTreeNode *)tn removeObjectAtIndex:(NSInteger)idx
    forKey:(NSString *)key
{
  MgNode *node = tn.node;

  NSArray *array = [node valueForKey:key];

  assert(array != nil);
  assert(idx >= 0 && idx < [array count]);

  id oldValue = array[idx];

  [self registerUndo:^
    {
      [self node:tn insertObject:oldValue atIndex:idx forKey:key];
    }];

  NSMutableArray *m_array = [NSMutableArray arrayWithArray:array];
  [m_array removeObjectAtIndex:idx];
  [node setValue:m_array forKey:key];

  documentGraphChanged(self);
}

@end
