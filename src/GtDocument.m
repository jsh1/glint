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

#import "GtDocument.h"

#import "GtTreeNode.h"
#import "GtWindowController.h"

#import "MgCoderExtensions.h"

#import "FoundationExtensions.h"

NSString *const GtDocumentGraphDidChange = @"GtDocumentGraphDidChange";
NSString *const GtDocumentNodeDidChange = @"GtDocumentNodeDidChange";

@implementation GtDocument
{
  GtWindowController *_controller;
  CGSize _documentSize;
  MgLayerNode *_documentNode;
  int _undoDisable;
}

@synthesize controller = _controller;

- (id)init
{
  self = [super init];
  if (self == nil)
    return nil;

  _controller = [[GtWindowController alloc] init];

  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  CGFloat width = [defaults doubleForKey:@"GtDefaultDocumentWidth"];
  CGFloat height = [defaults doubleForKey:@"GtDefaultDocumentHeight"];

  MgGroupNode *root = [MgGroupNode node];

  root.name = @"Root Layer";
  root.bounds = CGRectMake(0, 0, width, height);
  root.position = CGPointMake(width * .5, height * .5);

  self.documentSize = CGSizeMake(width, height);
  self.documentNode = root;

#if 1
  MgRectNode *bg_rect = [MgRectNode node];
  bg_rect.fillColor = [[NSColor lightGrayColor] CGColor];
  bg_rect.name = @"BG Fill";
  bg_rect.bounds = root.bounds;
  bg_rect.position = root.position;
  [root addContent:bg_rect];

  MgImageNode *image_layer = [MgImageNode node];
  image_layer.position = CGPointMake(700, 400);
  image_layer.bounds = CGRectMake(0, 0, 512, 512);
  image_layer.rotation = -10 * (M_PI / 180);
  image_layer.name = @"Image Layer";
  image_layer.imageProvider = [MgImageProvider imageProviderWithURL:
			       [NSURL fileURLWithPath:
				@"/Library/User Pictures/Animals/Parrot.tif"]];
  [root addContent:image_layer];

#if 1
  MgGroupNode *image_group = [MgGroupNode node];
  image_group.position = CGPointMake(-200, 300);
  image_group.bounds = CGRectMake(0, 0, 512, 512);
  image_group.alpha = .25;
  image_group.name = @"Image Group";
  [image_group addContent:image_layer];
  [root addContent:image_group];
#endif

  MgRectNode *rect_layer = [MgRectNode node];
  rect_layer.position = CGPointMake(350, 300);
  rect_layer.bounds = CGRectMake(0, 0, 400, 250);
  rect_layer.cornerRadius = 8;
  rect_layer.alpha = .5;
  rect_layer.name = @"Layer 3";
  rect_layer.fillColor = [[NSColor blueColor] CGColor];
  rect_layer.name = @"Rect Fill";
  [root addContent:rect_layer];
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

- (MgLayerNode *)documentNode
{
  return _documentNode;
}

- (void)setDocumentNode:(MgLayerNode *)node
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
      [archiver encodeObject:_documentNode forKey:NSKeyedArchiveRootObjectKey];
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
			   [MgLayerNode class]
			   forKey:NSKeyedArchiveRootObjectKey];

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
makeSelectionArray1(GtTreeNode *parent, MgNode *node)
{
  NSMutableArray *selection = [NSMutableArray array];

  for (GtTreeNode *tn in parent.children)
    {
      if (tn.node == node)
	[selection addObject:tn];
    }

  return selection;
}

/* ADDED is map from MgNode -> GtTreeNode<MgGroupNode>. */

static NSArray *
makeSelectionArray(NSMapTable *added)
{
  NSMutableArray *selection = [NSMutableArray array];

  for (MgNode *node in added)
    {
      GtTreeNode *parent = [added objectForKey:node];

      for (GtTreeNode *tn in parent.children)
	{
	  if (tn.node == node)
	    [selection addObject:tn];
	}
    }

  return selection;
}

- (IBAction)selectNone:(id)sender
{
  self.controller.selection = @[];
}

- (IBAction)delete:(id)sender
{
  NSMutableSet *set = [NSMutableSet set];

  for (GtTreeNode *tn in self.controller.selection)
    {
      if ([set containsObject:tn.node])
	continue;
      if (tn.parent == nil)
	continue;

      [self removeTreeNodeFromParent:tn];
      [set addObject:tn.node];
    }

  self.controller.selection = @[];
}

- (IBAction)cut:(id)sender
{
  [self copy:sender];
  [self delete:sender];
}

- (IBAction)copy:(id)sender
{
  NSPasteboard *pboard = [NSPasteboard generalPasteboard];

  [pboard clearContents];
  [pboard writeObjects:[self.controller.selection mappedArray:
			^id(id obj) {return ((GtTreeNode *)obj).node;}]];
}

- (void)pasteObjects:(NSArray *)objects
{
  GtTreeNode *parent_group = nil;
  GtTreeNode *parent_layer = nil;

  for (GtTreeNode *tn in self.controller.selection)
    {
      GtTreeNode *ln = [tn containingLayer];
      if (ln != nil)
	{
	  if (parent_layer == nil)
	    parent_layer = ln;
	  else
	    parent_layer = [parent_layer ancestorSharedWith:ln];
	}

      GtTreeNode *pn = [tn containingGroup];
      if (pn != nil)
	{
	  if (parent_group == nil)
	    parent_group = pn;
	  else
	    parent_group = [parent_group ancestorSharedWith:pn];
	}
    }

  if (parent_layer == nil)
    parent_layer = self.controller.tree;
  if (parent_group == nil)
    parent_group = self.controller.tree;

  NSMapTable *added = [NSMapTable strongToStrongObjectsMapTable];

  void (^paste_image)(MgImageProvider *) = ^(MgImageProvider *image_provider)
    {
      if (image_provider == nil)
	return;

      MgImageNode *layer = [MgImageNode node];
      layer.imageProvider = image_provider;
      layer.name = @"Pasted Image";
      makeNameUnique(layer, parent_group.node);

      CGImageRef im = [image_provider mg_providedImage];

      CGSize size = CGSizeMake(512, 512);
      if (im != NULL)
	size = CGSizeMake(CGImageGetWidth(im), CGImageGetHeight(im));

      layer.bounds = CGRectMake(0, 0, size.width, size.height);
      layer.position = CGPointMake(size.width*.5, size.height*.5);

      [self node:parent_group insertObject:layer atIndex:NSIntegerMax
       forKey:@"contents"];

      [added setObject:parent_group forKey:layer];
    };

  for (id object in objects)
    {
      if ([object isKindOfClass:[MgLayerNode class]])
	{
	  [self node:parent_group insertObject:object atIndex:NSIntegerMax
	   forKey:@"contents"];

	  [added setObject:parent_group forKey:object];
	}
      else if ([object isKindOfClass:[MgAnimationNode class]])
	{
	  [self node:parent_layer insertObject:object atIndex:NSIntegerMax
	   forKey:@"animations"];

	  [added setObject:parent_layer forKey:object];
	}
      else if ([object isKindOfClass:[NSImage class]])
	{
	  CGImageRef im = [(NSImage *)object CGImageForProposedRect:NULL
			   context:nil hints:nil];
	  if (im != nil)
	    {
	      paste_image([MgImageProvider imageProviderWithImage:im]);
	    }
	}
      else if ([object isKindOfClass:[NSURL class]])
	{
	  paste_image([MgImageProvider imageProviderWithURL:object]);
	}
      else if ([object isKindOfClass:[NSData class]])
	{
	  paste_image([MgImageProvider imageProviderWithData:object]);
	}
    }

  self.controller.selection = makeSelectionArray(added);
}

- (IBAction)pasteAsImage:(id)sender
{
  NSPasteboard *pboard = [NSPasteboard generalPasteboard];

  NSArray *objects = [pboard readObjectsForClasses:
		      @[[NSImage class]] options:nil];

  [self pasteObjects:objects];
}

- (BOOL)canPasteAsImage
{
  NSPasteboard *pboard = [NSPasteboard generalPasteboard];

  return [pboard canReadObjectForClasses:@[[NSImage class]] options:nil];
}

- (IBAction)paste:(id)sender
{
  NSPasteboard *pboard = [NSPasteboard generalPasteboard];

  /* FIXME: shouldn't be using NSImage here (and above)? Reading the
     data directly would let us avoid recompressing the data when
     saving the document. */

  NSArray *classes = @[[MgNode class], [NSURL class], [NSImage class]];

  NSArray *objects = [pboard readObjectsForClasses:classes options:nil];

  [self pasteObjects:objects];
}

- (BOOL)canPaste
{
  NSPasteboard *pboard = [NSPasteboard generalPasteboard];

  NSArray *classes = @[[MgNode class], [NSURL class], [NSImage class]];

  return [pboard canReadObjectForClasses:classes options:nil];
}

- (void)addLayerContent:(MgLayerNode *(^)(MgGroupNode *parent_group))block
{
  NSMapTable *groups = [NSMapTable strongToStrongObjectsMapTable];
  NSMutableSet *nodes = [NSMutableSet set];

  for (GtTreeNode *tn in self.controller.selection)
    {
      if (![tn.node isKindOfClass:[MgLayerNode class]])
	continue;

      GtTreeNode *n = tn;
      NSInteger idx = NSNotFound;
      while (n != nil)
	{
	  if ([n.node isKindOfClass:[MgGroupNode class]])
	    break;
	  GtTreeNode *p = n.parent;
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

      [groups setObject:@(idx) forKey:n];
      [nodes addObject:n.node];
    }

  if ([groups count] == 0)
    [groups setObject:@(NSNotFound) forKey:self.controller.tree];

  NSMapTable *added = [NSMapTable strongToStrongObjectsMapTable];

  for (GtTreeNode *parent in groups)
    {
      MgGroupNode *parent_group = (MgGroupNode *)parent.node;

      MgLayerNode *content = block(parent_group);

      if (content != nil)
	{
	  NSInteger idx = [[groups objectForKey:parent] integerValue];
	  if (idx == NSNotFound)
	    idx = [parent_group.contents count];

	  [self node:parent insertObject:content atIndex:idx
	   forKey:@"contents"];

	  [added setObject:parent forKey:content];
	}
    }

  self.controller.selection = makeSelectionArray(added);
}

- (IBAction)insertLayer:(id)sender
{
  [self addLayerContent:^MgLayerNode * (MgGroupNode *parent_group)
    {
      MgLayerNode *layer = [MgLayerNode node];
      initializeLayerFromContainer(layer, parent_group);
      layer.name = @"Layer";
      makeNameUnique(layer, parent_group);
      return layer;
    }];
}

- (IBAction)addContent:(id)sender
{
  NSInteger tag = [sender tag];

  [self addLayerContent:^MgLayerNode * (MgGroupNode *parent_group)
    {
      MgLayerNode *node = nil;

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

      makeNameUnique(node, parent_group);
      return node;
    }];
}

- (IBAction)addAnimation:(id)sender
{
  /* FIXME: implement this. */
}

- (IBAction)group:(id)sender
{
  GtTreeNode *master = nil;

  NSMutableArray *group = [NSMutableArray array];
  NSMutableSet *nodes = [NSMutableSet set];

  for (GtTreeNode *tn in self.controller.selection)
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

  GtTreeNode *container = [master containingGroup];
  if (container == nil)
    return;

  MgGroupNode *container_group = (MgGroupNode *)container.node;

  MgGroupNode *layer = [MgGroupNode node];
  layer.name = @"Group";
  if (container == master)
    makeNameUnique(layer, container_group);

  initializeLayerFromContainer(layer, container_group);

  for (GtTreeNode *tn in group)
    {
      if (tn != master)
	[self removeTreeNodeFromParent:tn];

      MgLayerNode *node = (MgLayerNode *)tn.node;
      [layer addContent:node];
    }

  GtTreeNode *parent = master.parent;

  [self replaceTreeNode:master with:layer];

  self.controller.selection = makeSelectionArray1(parent, layer);
}

- (IBAction)ungroup:(id)sender
{
  NSMutableSet *set = [NSMutableSet set];

  NSMapTable *added = [NSMapTable strongToStrongObjectsMapTable];

  for (GtTreeNode *tn in self.controller.selection)
    {
      MgGroupNode *group = (MgGroupNode *)tn.node;
      if (![group isKindOfClass:[MgGroupNode class]])
	continue;
      if (group.mask != nil)
	continue;

      GtTreeNode *parent = tn.parent;
      if (parent == nil)
	continue;

      NSInteger idx = tn.parentIndex;
      if (idx == NSNotFound)
	{
	  idx = NSIntegerMax;
	  if ([group.contents count] > 1)
	    continue;
	}

      if ([set containsObject:group])
	continue;

      [self removeTreeNodeFromParent:tn];

      for (MgLayerNode *child in group.contents)
	{
	  [self node:parent insertObject:child atIndex:idx++
	   forKey:@"contents"];

	  [added setObject:parent forKey:child];
	}

      [set addObject:group];
    }

  self.controller.selection = makeSelectionArray(added);
}

- (IBAction)raiseObject:(id)sender
{
  NSInteger delta = [sender tag];

  NSMutableSet *nodes = [NSMutableSet set];

  NSArray *selection = self.controller.selection;

  for (GtTreeNode *tn in selection)
    {
      if ([nodes containsObject:tn.node])
	continue;

      GtTreeNode *parent = tn.parent;
      if (parent == nil)
	continue;

      NSInteger idx = tn.parentIndex;
      NSString *key = tn.parentKey;

      if (idx == NSNotFound)
	continue;

      [self node:parent moveObjectAtIndex:idx by:delta forKey:key];

      [nodes addObject:tn.node];
    }

  self.controller.selection = selection;
}

- (IBAction)toggleEnabled:(id)sender
{
  NSMutableSet *nodes = [NSMutableSet set];

  for (GtTreeNode *tn in self.controller.selection)
    {
      if ([nodes containsObject:tn.node])
	continue;

      [self node:tn setValue:@(!tn.node.enabled) forKey:@"enabled"];

      [nodes addObject:tn.node];
    }
}

- (NSInteger)toggleEnabledState
{
  NSInteger on = 0, off = 0;

  for (GtTreeNode *tn in self.controller.selection)
    {
      if (tn.node.enabled)
	on++;
      else
	off++;
    }

  return on && off ? NSMixedState : on ? NSOnState : NSOffState;
}

- (IBAction)toggleLayerGroup:(id)sender
{
  NSMutableSet *nodes = [NSMutableSet set];

  for (GtTreeNode *tn in self.controller.selection)
    {
      MgGroupNode *layer = (MgGroupNode *)tn.node;
      if (![layer isKindOfClass:[MgGroupNode class]])
	continue;

      if ([nodes containsObject:layer])
	continue;

      [self node:tn setValue:@(!layer.group) forKey:@"group"];

      [nodes addObject:layer];
    }
}

- (NSInteger)toggleLayerGroupState
{
  NSInteger on = 0, off = 0;

  for (GtTreeNode *tn in self.controller.selection)
    {
      MgGroupNode *layer = (MgGroupNode *)tn.node;
      if (![layer isKindOfClass:[MgGroupNode class]])
	continue;

      if (layer.group)
	on++;
      else
	off++;
    }

  return on && off ? NSMixedState : on ? NSOnState : NSOffState;
}

- (IBAction)setBlendMode:(id)sender
{
  CGBlendMode mode = (CGBlendMode)[sender tag];
  NSMutableSet *nodes = [NSMutableSet set];

  for (GtTreeNode *tn in self.controller.selection)
    {
      MgLayerNode *layer = (MgLayerNode *)tn.node;
      if (![layer isKindOfClass:[MgLayerNode class]])
	continue;

      if ([nodes containsObject:layer])
	continue;

      [self node:tn setValue:@(mode) forKey:@"blendMode"];

      [nodes addObject:layer];
    }
}

- (NSInteger)setBlendModeState:(id)sender
{
  CGBlendMode mode = (CGBlendMode)[sender tag];
  NSInteger on = 0, off = 0;

  for (GtTreeNode *tn in self.controller.selection)
    {
      MgLayerNode *layer = (MgLayerNode *)tn.node;
      if (![layer isKindOfClass:[MgLayerNode class]])
	continue;

      if (layer.blendMode == mode)
	on++;
      else
	off++;
    }

  return on && off ? NSMixedState : on ? NSOnState : NSOffState;
}

- (IBAction)setAlpha:(id)sender
{
  float alpha = [sender tag] * .01f;
  NSMutableSet *nodes = [NSMutableSet set];

  for (GtTreeNode *tn in self.controller.selection)
    {
      MgLayerNode *layer = (MgLayerNode *)tn.node;
      if (![layer isKindOfClass:[MgLayerNode class]])
	continue;

      if ([nodes containsObject:layer])
	continue;

      [self node:tn setValue:@(alpha) forKey:@"alpha"];

      [nodes addObject:layer];
    }
}

- (NSInteger)setAlphaState:(id)sender
{
  float alpha = [sender tag] * .01f;
  NSInteger on = 0, off = 0;

  for (GtTreeNode *tn in self.controller.selection)
    {
      MgLayerNode *layer = (MgLayerNode *)tn.node;
      if (![layer isKindOfClass:[MgLayerNode class]])
	continue;

      if (fabsf(layer.alpha - alpha) < 1e-4f)
	on++;
      else
	off++;
    }

  return on && off ? NSMixedState : on ? NSOnState : NSOffState;
}

- (void)removeTreeNodeFromParent:(GtTreeNode *)tn
{
  GtTreeNode *parent = tn.parent;
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

- (void)replaceTreeNode:(GtTreeNode *)tn with:(MgNode *)node
{
  GtTreeNode *parent = tn.parent;
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
documentGraphChanged(GtDocument *self)
{
  [[NSNotificationCenter defaultCenter]
   postNotificationName:GtDocumentGraphDidChange object:self];
}

static void
documentNodeChanged(GtDocument *self, GtTreeNode *tn)
{
  [[NSNotificationCenter defaultCenter]
   postNotificationName:GtDocumentNodeDidChange object:self
   userInfo:@{@"treeItem": tn}];
}

- (void)node:(GtTreeNode *)tn setValue:(id)value forKey:(NSString *)key
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
      else
	{
	  documentNodeChanged(self, tn);
	}
    }
}

- (void)node:(GtTreeNode *)tn insertObject:(id)value atIndex:(NSInteger)idx
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

- (void)node:(GtTreeNode *)tn replaceObjectAtIndex:(NSInteger)idx
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

- (void)node:(GtTreeNode *)tn removeObjectAtIndex:(NSInteger)idx
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

- (void)node:(GtTreeNode *)tn moveObjectAtIndex:(NSInteger)idx
    by:(NSInteger)delta forKey:(NSString *)key
{
  MgNode *node = tn.node;

  NSArray *array = [node valueForKey:key];
  NSInteger count = [array count];

  assert(array != nil);

  NSInteger inverse_delta = 0;
  id object = array[idx];

  NSMutableArray *m_array = [NSMutableArray arrayWithArray:array];

  while (delta > 0 && idx < count - 1)
    {
      [m_array removeObjectAtIndex:idx];
      idx++;
      [m_array insertObject:object atIndex:idx];
      inverse_delta--;
      delta--;
    }

  while (delta < 0 && idx > 0)
    {
      [m_array removeObjectAtIndex:idx];
      idx--;
      [m_array insertObject:object atIndex:idx];
      inverse_delta++;
      delta++;
    }

  if (inverse_delta != 0)
    {
      [self registerUndo:^
	{
	  [self node:tn moveObjectAtIndex:idx by:inverse_delta forKey:key];
	}];

      [node setValue:m_array forKey:key];
    }

  documentGraphChanged(self);
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item
{
  SEL action = [item action];

  if (action == @selector(selectNone:)
      || action == @selector(delete:)
      || action == @selector(copy:)
      || action == @selector(cut:)
      || action == @selector(toggleEnabled:))
    {
      return [self.controller.selection count] != 0;
    }

  if (action == @selector(embedIn:)
      || action == @selector(group:)
      || action == @selector(setBlendMode:)
      || action == @selector(setAlpha:))
    {
      for (GtTreeNode *tn in self.controller.selection)
	{
	  if (action == @selector(setBlendMode:)
	      && [tn.node isKindOfClass:[MgGroupNode class]]
	      && !((MgGroupNode *)tn.node).group)
	    continue;

	  if ([tn.node isKindOfClass:[MgLayerNode class]])
	    return YES;
	}

      return NO;
    }

  if (action == @selector(ungroup:)
      || action == @selector(toggleLayerGroup:))
    {
      for (GtTreeNode *tn in self.controller.selection)
	{
	  if ([tn.node isKindOfClass:[MgGroupNode class]])
	    return YES;
	}

      return NO;
    }

  if (action == @selector(raiseObject:))
    {
      for (GtTreeNode *tn in self.controller.selection)
	{
	  if (tn.parent != nil && tn.parentIndex != NSNotFound
	      && [[tn.parent.node valueForKey:tn.parentKey] count] > 1)
	    return YES;
	}

      return NO;
    }

  if (action == @selector(paste:))
    {
      return [self canPaste];
    }

  if (action == @selector(pasteAsImage:))
    {
      return [self canPasteAsImage];
    }

  return YES;
}

@end
