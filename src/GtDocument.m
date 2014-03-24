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
#import "MgCoreGraphics.h"

#import "FoundationExtensions.h"

NSString *const GtDocumentGraphDidChange = @"GtDocumentGraphDidChange";
NSString *const GtDocumentNodeDidChange = @"GtDocumentNodeDidChange";

@implementation GtDocument
{
  GtWindowController *_windowController;
  CGSize _documentSize;
  MgModuleLayer *_documentNode;
  int _undoDisable;
}

@synthesize windowController = _windowController;

- (id)init
{
  self = [super init];
  if (self == nil)
    return nil;

  _windowController = [[GtWindowController alloc] init];

  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

  CGFloat width = [defaults doubleForKey:@"GtDefaultDocumentWidth"];
  CGFloat height = [defaults doubleForKey:@"GtDefaultDocumentHeight"];

  MgModuleLayer *root = [MgModuleLayer node];

  root.name = @"Root";
  root.size = CGSizeMake(width, height);
  root.position = CGPointMake(width * .5, height * .5);

  self.documentSize = CGSizeMake(width, height);
  self.documentNode = root;

  return self;
}

- (void)makeWindowControllers
{
  [self addWindowController:_windowController];
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

- (CGPoint)documentCenter
{
  return CGPointMake(_documentSize.width * .5,
		     _documentSize.height * .5);
}

+ (BOOL)automaticallyNotifiesObserversOfDocumentNode
{
  return NO;
}

- (MgModuleLayer *)documentNode
{
  return _documentNode;
}

- (void)setDocumentNode:(MgModuleLayer *)node
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
			   [MgModuleLayer class]
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

- (IBAction)export:(id)sender
{
  NSSavePanel *panel = [NSSavePanel savePanel];

  [panel setAllowedFileTypes:@[(id)kUTTypePNG, (id)kUTTypeJPEG]];
  [panel setCanCreateDirectories:YES];
  [panel setCanSelectHiddenExtension:YES];
  [panel setExtensionHidden:NO];
  [panel setPrompt:@"Export"];
  [panel setNameFieldLabel:@"Export As:"];

  [panel beginSheetModalForWindow:self.windowController.window
   completionHandler:^(NSInteger result)
    {
      if (result != NSFileHandlingPanelOKButton)
	return;

      NSURL *url = [panel URL];

      CFStringRef type = UTTypeCreatePreferredIdentifierForTag(
			kUTTagClassFilenameExtension,
		 	(__bridge CFStringRef)[[url path] pathExtension],
			kUTTypeImage);
      if (type == NULL)
	return;

      CGImageRef im
        = [(MgLayer *)self.windowController.tree.node copyImage];

      if (im != NULL)
	{
	  CFDataRef data = MgImageCreateData(im, type);

	  if (data != NULL)
	    {
	      [(__bridge NSData *)data writeToURL:url atomically:YES];

	      CFRelease(data);
	    }

	  CGImageRelease(im);
	}

      CFRelease(type);
    }];
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
initializeLayerFromContainer(MgLayer *layer, MgLayer *container)
{
  CGSize size = container != nil ? container.size : CGSizeMake(512, 512);

  layer.size = size;
  layer.position = CGPointMake(size.width * .5, size.height * .5);
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

/* ADDED is map from MgNode -> GtTreeNode<MgGroupLayer>. */

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

- (IBAction)selectAll:(id)sender
{
  NSMutableSet *set = [NSMutableSet set];

  [self.windowController.tree foreachNode:^(GtTreeNode *node, BOOL *stop)
    {
      [set addObject:node];
    }];

  self.windowController.selection = [set allObjects];
}

- (IBAction)selectNone:(id)sender
{
  self.windowController.selection = @[];
}

- (IBAction)delete:(id)sender
{
  NSMutableSet *set = [NSMutableSet set];

  for (GtTreeNode *tn in self.windowController.selection)
    {
      if ([set containsObject:tn.node])
	continue;
      if (tn.parent == nil)
	continue;

      [self removeTreeNodeFromParent:tn];
      [set addObject:tn.node];
    }

  self.windowController.selection = @[];
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
  [pboard writeObjects:[self.windowController.selection
			mappedArray:^id(id obj) {
			  return ((GtTreeNode *)obj).node;}]];
}

- (IBAction)copyDocument:(id)sender
{
  NSPasteboard *pboard = [NSPasteboard generalPasteboard];

  [pboard clearContents];
  [pboard writeObjects:@[self.windowController.tree.node]];
}

- (NSArray *)pasteboardClassesAsImage:(BOOL)flag
{
  return (!flag
	  ? @[[MgNode class], [NSURL class], [NSImage class]]
	  : @[[NSImage class]]);
}

static CGFloat
fract(CGFloat x)
{
  return x - floor(x);
}

- (BOOL)addObjectsFromPasteboard:(NSPasteboard *)pboard
    asImages:(BOOL)flag atDocumentPoint:(CGPoint)p
{
  GtTreeNode *parent = nil;
  NSInteger idx = [parent.children count];

  for (GtTreeNode *tn in self.windowController.selection)
    {
      GtTreeNode *pn = tn;
      NSInteger pn_idx = NSNotFound;
      while (pn != nil && ![pn.node isKindOfClass:[MgGroupLayer class]])
	{
	  pn_idx = pn.parentIndex;
	  pn = pn.parent;
	}

      if (pn != nil)
	{
	  if (parent == nil)
	    {
	      parent = pn;
	      idx = pn_idx;
	    }
	  else
	    {
	      parent = [parent ancestorSharedWith:pn];
	      idx = [parent.children count];
	    }
	}
    }

  if (parent == nil)
    parent = self.windowController.tree;

  return [self addObjectsFromPasteboard:pboard asImages:flag
	  atDocumentPoint:p intoNode:parent atIndex:idx];
}

- (BOOL)addObjectsFromPasteboard:(NSPasteboard *)pboard
    asImages:(BOOL)flag atDocumentPoint:(CGPoint)p
    intoNode:(GtTreeNode *)parent atIndex:(NSInteger)idx_
{
  NSArray *classes = [self pasteboardClassesAsImage:flag];
  NSArray *objects = [pboard readObjectsForClasses:classes options:nil];

  NSMapTable *added = [NSMapTable strongToStrongObjectsMapTable];

  __block NSInteger idx = idx_;

  void (^paste_image)(MgImageProvider *) = ^(MgImageProvider *image_provider)
    {
      if (image_provider == nil)
	return;

      MgImageLayer *layer = [MgImageLayer node];
      layer.imageProvider = image_provider;
      NSURL *url = [image_provider URL];
      if (url != nil)
	layer.name = [[[url path] lastPathComponent] stringByDeletingPathExtension];
      else
	layer.name = @"Pasted Image";
      makeNameUnique(layer, parent.node);

      CGImageRef im = [image_provider mg_providedImage];

      CGSize size = CGSizeMake(512, 512);
      if (im != NULL)
	size = CGSizeMake(CGImageGetWidth(im), CGImageGetHeight(im));

      layer.size = size;
      layer.position = CGPointMake(round(p.x) + fract(size.width*.5),
				   round(p.y) + fract(size.height*.5));

      [self node:parent insertObject:layer atIndex:idx++
       forKey:@"sublayers"];

      [added setObject:parent forKey:layer];
    };

  for (id object in objects)
    {
      if ([object isKindOfClass:[MgLayer class]])
	{
	  [self node:parent insertObject:object atIndex:idx++
	   forKey:@"sublayers"];

	  [added setObject:parent forKey:object];
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

  self.windowController.selection = makeSelectionArray(added);

  return [added count] != 0;
}

- (BOOL)canAddObjectsFromPasteboard:(NSPasteboard *)pboard
    asImages:(BOOL)flag
{
  NSArray *classes = [self pasteboardClassesAsImage:flag];

  return [pboard canReadObjectForClasses:classes options:nil];
}

- (IBAction)pasteAsImage:(id)sender
{
  [self addObjectsFromPasteboard:[NSPasteboard generalPasteboard]
   asImages:YES atDocumentPoint:self.documentCenter];
}

- (BOOL)canPasteAsImage
{
  return [self canAddObjectsFromPasteboard:
	  [NSPasteboard generalPasteboard] asImages:YES];
}

- (IBAction)paste:(id)sender
{
  [self addObjectsFromPasteboard:[NSPasteboard generalPasteboard]
   asImages:NO atDocumentPoint:self.documentCenter];
}

- (BOOL)canPaste
{
  return [self canAddObjectsFromPasteboard:
	  [NSPasteboard generalPasteboard] asImages:YES];
}

- (void)addSublayer:(MgLayer *(^)(MgGroupLayer *parent_group))block
{
  NSMapTable *groups = [NSMapTable strongToStrongObjectsMapTable];
  NSMutableSet *nodes = [NSMutableSet set];

  for (GtTreeNode *tn in self.windowController.selection)
    {
      if (![tn.node isKindOfClass:[MgLayer class]])
	continue;

      GtTreeNode *n = tn;
      NSInteger idx = NSNotFound;
      while (n != nil)
	{
	  if ([n.node isKindOfClass:[MgGroupLayer class]])
	    break;
	  GtTreeNode *p = n.parent;
	  if ([n.parentKey isEqualToString:@"sublayers"])
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
    [groups setObject:@(NSNotFound) forKey:self.windowController.tree];

  NSMapTable *added = [NSMapTable strongToStrongObjectsMapTable];

  for (GtTreeNode *parent in groups)
    {
      MgGroupLayer *parent_group = (MgGroupLayer *)parent.node;

      MgLayer *content = block(parent_group);

      if (content != nil)
	{
	  NSInteger idx = [[groups objectForKey:parent] integerValue];
	  if (idx == NSNotFound)
	    idx = [parent_group.sublayers count];

	  [self node:parent insertObject:content atIndex:idx
	   forKey:@"sublayers"];

	  [added setObject:parent forKey:content];
	}
    }

  self.windowController.selection = makeSelectionArray(added);
}

- (IBAction)addLayer:(id)sender
{
  NSInteger tag = [sender tag];

  MgLayer *root_layer = _documentNode;

  [self addSublayer:^MgLayer * (MgGroupLayer *parent_group)
    {
      MgLayer *layer = nil;

      if (tag == 0)
	{
	  layer = [[MgGroupLayer alloc] init];
	  layer.name = @"Group";
	}
      else if (tag == 1)
	{
	  layer = [[MgImageLayer alloc] init];
	  layer.name = @"Image";
	}
      else if (tag == 2)
	{
	  layer = [[MgGradientLayer alloc] init];
	  layer.name = @"Gradient";
	}
      else if (tag == 3 || tag == 4)
	{
	  layer = [[MgRectLayer alloc] init];
	  layer.name = @"Rect";
	  if (tag == 4)
	    ((MgRectLayer *)layer).drawingMode = kCGPathStroke;
	}
      else if (tag == 5 || tag == 6)
	{
	  layer = [[MgPathLayer alloc] init];
	  layer.name = @"Path";
	  if (tag == 6)
	    ((MgPathLayer *)layer).drawingMode = kCGPathStroke;
	}
      else
	return nil;

      makeNameUnique(layer, parent_group);
      MgLayer *container = parent_group != root_layer ? parent_group : nil;
      initializeLayerFromContainer(layer, container);

      return layer;
    }];
}

- (IBAction)addImage:(id)sender
{
  NSOpenPanel *panel = [NSOpenPanel openPanel];

  /* FIXME: allow insertion of multiple images. */

  [panel setAllowedFileTypes:@[(id)kUTTypeImage]];
  [panel setAllowsMultipleSelection:NO];
  [panel setPrompt:@"Add"];
  [panel setNameFieldLabel:@"Add Image:"];

  [panel beginWithCompletionHandler:^(NSInteger result)
    {
      if (result != NSFileHandlingPanelOKButton)
	return;

      MgImageProvider *p = [MgImageProvider imageProviderWithURL:[panel URL]];
      if (p == nil)
	return;

      [self addSublayer:^MgLayer * (MgGroupLayer *parent_group)
        {
	  MgImageLayer *layer = [MgImageLayer node];
	  layer.imageProvider = p;

	  layer.name = [[[[panel URL] path] lastPathComponent]
			stringByDeletingPathExtension];

	  CGImageRef im = [p mg_providedImage];

	  CGSize size = CGSizeMake(512, 512);
	  if (im != NULL)
	    size = CGSizeMake(CGImageGetWidth(im), CGImageGetHeight(im));

	  layer.size = size;

	  CGRect r = parent_group.bounds;
	  layer.position = CGPointMake(CGRectGetMidX(r), CGRectGetMidY(r));

	  return layer;
	}];
    }];
}

- (IBAction)group:(id)sender
{
  GtTreeNode *master = nil;

  NSMutableArray *group = [NSMutableArray array];
  NSMutableSet *nodes = [NSMutableSet set];

  for (GtTreeNode *tn in self.windowController.selection)
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

  MgGroupLayer *container_group = (MgGroupLayer *)container.node;

  MgGroupLayer *layer = [MgGroupLayer node];
  layer.name = @"Group";
  if (container == master)
    makeNameUnique(layer, container_group);

  initializeLayerFromContainer(layer, container_group);

  for (GtTreeNode *tn in group)
    {
      if (tn != master)
	[self removeTreeNodeFromParent:tn];

      MgLayer *node = (MgLayer *)tn.node;
      [layer addSublayer:node];
    }

  GtTreeNode *parent = master.parent;

  [self replaceTreeNode:master with:layer];

  self.windowController.selection = makeSelectionArray1(parent, layer);
}

- (IBAction)ungroup:(id)sender
{
  NSMutableSet *set = [NSMutableSet set];

  NSMapTable *added = [NSMapTable strongToStrongObjectsMapTable];

  for (GtTreeNode *tn in self.windowController.selection)
    {
      MgGroupLayer *group = (MgGroupLayer *)tn.node;
      if (![group isKindOfClass:[MgGroupLayer class]])
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
	  if ([group.sublayers count] > 1)
	    continue;
	}

      if ([set containsObject:group])
	continue;

      [self removeTreeNodeFromParent:tn];

      for (MgLayer *child in group.sublayers)
	{
	  [self node:parent insertObject:child atIndex:idx++
	   forKey:@"sublayers"];

	  [added setObject:parent forKey:child];
	}

      [set addObject:group];
    }

  self.windowController.selection = makeSelectionArray(added);
}

- (IBAction)raiseObject:(id)sender
{
  NSInteger delta = [sender tag];

  NSMutableSet *nodes = [NSMutableSet set];

  NSArray *selection = self.windowController.selection;

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

      [self node:parent moveObject:tn.node atIndex:idx by:delta forKey:key];

      [nodes addObject:tn.node];
    }

  self.windowController.selection = selection;
}

- (IBAction)toggleEnabled:(id)sender
{
  NSMutableSet *nodes = [NSMutableSet set];

  for (GtTreeNode *tn in self.windowController.selection)
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

  for (GtTreeNode *tn in self.windowController.selection)
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

  for (GtTreeNode *tn in self.windowController.selection)
    {
      MgGroupLayer *layer = (MgGroupLayer *)tn.node;
      if (![layer isKindOfClass:[MgGroupLayer class]])
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

  for (GtTreeNode *tn in self.windowController.selection)
    {
      MgGroupLayer *layer = (MgGroupLayer *)tn.node;
      if (![layer isKindOfClass:[MgGroupLayer class]])
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

  for (GtTreeNode *tn in self.windowController.selection)
    {
      MgLayer *layer = (MgLayer *)tn.node;
      if (![layer isKindOfClass:[MgLayer class]])
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

  for (GtTreeNode *tn in self.windowController.selection)
    {
      MgLayer *layer = (MgLayer *)tn.node;
      if (![layer isKindOfClass:[MgLayer class]])
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

  for (GtTreeNode *tn in self.windowController.selection)
    {
      MgLayer *layer = (MgLayer *)tn.node;
      if (![layer isKindOfClass:[MgLayer class]])
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

  for (GtTreeNode *tn in self.windowController.selection)
    {
      MgLayer *layer = (MgLayer *)tn.node;
      if (![layer isKindOfClass:[MgLayer class]])
	continue;

      if (fabsf(layer.alpha - alpha) < 1e-4f)
	on++;
      else
	off++;
    }

  return on && off ? NSMixedState : on ? NSOnState : NSOffState;
}

- (IBAction)addModuleState:(id)sender
{
  GtTreeNode *module = self.windowController.currentModule;
  MgModuleLayer *layer = (MgModuleLayer *)module.node;

  MgModuleState *state = [MgModuleState moduleState];

  for (int i = 1;; i++)
    {
      NSString *name = [NSString stringWithFormat:@"State %d", i];

      BOOL unique = YES;

      for (MgModuleState *state in layer.moduleStates)
	{
	  if ([state.name isEqualToString:name])
	    {
	      unique = NO;
	      break;
	    }
	}

      if (unique)
	{
	  state.name = name;
	  break;
	}
    }

  [self node:module insertObject:state
   atIndex:NSIntegerMax forKey:@"moduleStates"];

  [self node:module setValue:state forKey:@"moduleState"];
}

- (IBAction)removeModuleState:(id)sender
{
  GtTreeNode *module = self.windowController.currentModule;
  MgModuleLayer *layer = (MgModuleLayer *)module.node;

  MgModuleState *state = layer.moduleState;
  if (state == nil)
      return;

  NSInteger idx = [layer.moduleStates indexOfObjectIdenticalTo:state];
  if (idx == NSNotFound)
    return;

  MgModuleState *new_state = idx == 0 ? nil : layer.moduleStates[idx-1];
  [self node:module setValue:new_state forKey:@"moduleState"];

  [self node:module removeObject:state atIndex:idx forKey:@"moduleStates"];

  [module foreachNode:^(GtTreeNode *node, BOOL *stop)
    {
      NSInteger idx = 0;
      for (MgNodeState *node_state in node.node.states)
	{
	  if (node_state.moduleState != state)
	    {
	      idx++;
	      continue;
	    }

	  [self node:node removeObject:node_state
	   atIndex:idx forKey:@"states"];
	  break;
	}
    }];
}

- (BOOL)canRemoveModuleState
{
  GtTreeNode *module = self.windowController.currentModule;
  MgModuleLayer *layer = (MgModuleLayer *)module.node;

  return layer.moduleState != nil;
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

      [self node:parent removeObject:tn.node atIndex:idx forKey:key];
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

      [self node:parent replaceObject:tn.node atIndex:idx
       withObject:node forKey:key];
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

- (void)node:(GtTreeNode *)tn addNodeState:(MgNodeState *)state
{
  MgNode *node = tn.node;

  [self registerUndo:^
    {
      [self node:tn removeNodeState:state];
    }];

  NSMutableArray *array = [NSMutableArray arrayWithArray:node.states];
  [array addObject:state];
  node.states = array;
}

- (void)node:(GtTreeNode *)tn removeNodeState:(MgNodeState *)state
{
  MgNode *node = tn.node;

  NSInteger idx = [node.states indexOfObjectIdenticalTo:state];

  if (idx != NSNotFound)
    {
      [self registerUndo:^
        {
	  [self node:tn addNodeState:state];
	}];

      NSMutableArray *array = [NSMutableArray arrayWithArray:node.states];
      [array removeObjectAtIndex:idx];
      node.states = array;
    }
}

- (MgNodeState *)node:(GtTreeNode *)tn addModuleState:(MgModuleState *)
    module_state inModule:(GtTreeNode *)module
{
  MgNode *node = tn.node;

  for (MgNodeState *state in node.states)
    {
      if (state.moduleState == module_state)
	return state;
    }

  MgNodeState *state = [[[node class] stateClass] state];

  /* Recursively builds the superstate chain on demand. */

  state.moduleState = module_state;
  state.superstate = [self node:tn addModuleState:module_state.superstate
		      inModule:module];

  [self node:tn addNodeState:state];

  return state;
}

- (void)nodeState:(MgNodeState *)state
    setDefinesValue:(BOOL)flag forKey:(NSString *)key
{
  BOOL oldFlag = [state definesValueForKey:key];

  if (flag != oldFlag)
    {
      [self registerUndo:^
	{
	  [self nodeState:state setDefinesValue:oldFlag forKey:key];
	}];

      /* Preserve superstate's value if necessary. */

      id oldValue = nil;
      if (flag)
	oldValue = [state valueForKey:key];

      [state setDefinesValue:flag forKey:key];

      if (flag)
	[state setValue:oldValue forKey:key];
    }
}

- (void)node:(GtTreeNode *)tn ensureNodeStateForKey:(NSString *)key
{
  MgNode *node = tn.node;

  if ([[[[node class] stateClass] allProperties] containsObject:key])
    {
      /* State-managed property. */

      GtTreeNode *module = [tn containingModule];

      if (module != nil)
	{
	  MgModuleLayer *module_layer = (MgModuleLayer *)module.node;

	  MgNodeState *state = [self node:tn addModuleState:
				module_layer.moduleState inModule:module];

	  node.state = state;

	  [self nodeState:state setDefinesValue:YES forKey:key];
	}
    }
}

- (void)node:(GtTreeNode *)tn setValue:(id)value forKey:(NSString *)key
{
  MgNode *node = tn.node;

  id oldValue = [node valueForKey:key];

  if (oldValue != value && ![oldValue isEqual:value])
    {
      [self node:tn ensureNodeStateForKey:key];

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

  [self node:tn ensureNodeStateForKey:key];

  NSArray *array = [node valueForKey:key];

  if (idx > [array count])
    idx = [array count];

  [self registerUndo:^
   {
     [self node:tn removeObject:value atIndex:idx forKey:key];
   }];

  NSMutableArray *m_array = [NSMutableArray arrayWithArray:array];
  [m_array insertObject:value atIndex:idx];
  [node setValue:m_array forKey:key];

  documentGraphChanged(self);
}

static NSInteger
indexOfObjectInArray(NSArray *array, id value, NSInteger idx)
{
  if (array == nil)
    return NSNotFound;

  if (idx == NSNotFound)
    return [array indexOfObjectIdenticalTo:value];

  NSInteger count = [array count];

  if (idx < 0)
    idx = 0;
  else if (idx >= count)
    idx = count - 1;

  if (array[idx] != value)
    {
      NSInteger before, after;

      for (before = idx - 1; before >= 0; before--)
	{
	  if (array[before] == value)
	    break;
	}
      for (after = idx + 1; after < count; after++)
	{
	  if (array[after] == value)
	    break;
	}

      if (before >= 0 && after < count)
	idx = (idx - before) < (after - idx) ? before : after;
      else if (before >= 0)
	idx = before;
      else if (after < count)
	idx = count;
      else
	idx = NSNotFound;
    }

  return idx;
}

- (void)node:(GtTreeNode *)tn replaceObject:(id)oldValue
    atIndex:(NSInteger)idx withObject:(id)value forKey:(NSString *)key
{
  assert(value != nil);

  MgNode *node = tn.node;

  NSArray *array = [node valueForKey:key];

  idx = indexOfObjectInArray(array, oldValue, idx);
  if (idx == NSNotFound)
    return;

  [self node:tn ensureNodeStateForKey:key];

  [self registerUndo:^
    {
      [self node:tn replaceObject:value atIndex:idx
       withObject:oldValue forKey:key];
    }];

  NSMutableArray *m_array = [NSMutableArray arrayWithArray:array];
  [m_array replaceObjectAtIndex:idx withObject:value];
  [node setValue:m_array forKey:key];

  documentGraphChanged(self);
}

- (void)node:(GtTreeNode *)tn removeObject:(id)oldValue
    atIndex:(NSInteger)idx forKey:(NSString *)key
{
  MgNode *node = tn.node;

  NSArray *array = [node valueForKey:key];

  idx = indexOfObjectInArray(array, oldValue, idx);
  if (idx == NSNotFound)
    return;

  [self node:tn ensureNodeStateForKey:key];

  [self registerUndo:^
    {
      [self node:tn insertObject:oldValue atIndex:idx forKey:key];
    }];

  NSMutableArray *m_array = [NSMutableArray arrayWithArray:array];
  [m_array removeObjectAtIndex:idx];
  [node setValue:m_array forKey:key];

  documentGraphChanged(self);
}

- (void)node:(GtTreeNode *)tn moveObject:(id)value atIndex:(NSInteger)idx
    by:(NSInteger)delta forKey:(NSString *)key
{
  MgNode *node = tn.node;

  NSArray *array = [node valueForKey:key];

  idx = indexOfObjectInArray(array, value, idx);
  if (idx == NSNotFound)
    return;

  [self node:tn ensureNodeStateForKey:key];

  NSInteger count = [array count];

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
	  [self node:tn moveObject:value atIndex:idx
	   by:inverse_delta forKey:key];
	}];

      [node setValue:m_array forKey:key];
    }

  documentGraphChanged(self);
}

- (void)module:(MgModuleLayer *)node state:(MgModuleState *)state
    setValue:(id)value forKey:(NSString *)key
{
  id oldValue = [state valueForKey:key];

  if (oldValue != value && ![oldValue isEqual:value])
    {
      [self registerUndo:^
        {
	  [self module:node state:state setValue:oldValue forKey:key];
	}];

      [state setValue:value forKey:key];
    }
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
      return [self.windowController.selection count] != 0;
    }

  if (action == @selector(embedIn:)
      || action == @selector(group:)
      || action == @selector(setBlendMode:)
      || action == @selector(setAlpha:))
    {
      for (GtTreeNode *tn in self.windowController.selection)
	{
	  if (action == @selector(setBlendMode:)
	      && [tn.node isKindOfClass:[MgGroupLayer class]]
	      && !((MgGroupLayer *)tn.node).group)
	    continue;

	  if ([tn.node isKindOfClass:[MgLayer class]])
	    return YES;
	}

      return NO;
    }

  if (action == @selector(ungroup:)
      || action == @selector(toggleLayerGroup:))
    {
      for (GtTreeNode *tn in self.windowController.selection)
	{
	  if ([tn.node isKindOfClass:[MgGroupLayer class]])
	    return YES;
	}

      return NO;
    }

  if (action == @selector(raiseObject:))
    {
      for (GtTreeNode *tn in self.windowController.selection)
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

  if (action == @selector(removeModuleState:))
    {
      return [self canRemoveModuleState];
    }

  return YES;
}

@end
