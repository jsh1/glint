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

#import "GtPropertiesViewController.h"

#import "GtDocument.h"
#import "GtInspectorItem.h"
#import "GtTreeNode.h"
#import "GtWindowController.h"

@implementation GtPropertiesViewController
{
  NSArray *_selection;			/* NSArray<GtTreeNode> */
}

- (NSString *)title
{
  return @"Selection";
}

- (id)initWithWindowController:(GtWindowController *)windowController
{
  self = [super initWithWindowController:windowController];
  if (self == nil)
    return nil;

  [self.windowController addObserver:self forKeyPath:@"selection" options:0
   context:NULL];

  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  [self reloadSelection];
}

- (void)invalidate
{
  [self.windowController removeObserver:self forKeyPath:@"selection"];

  for (GtTreeNode *tn in _selection)
    [tn.node removeObserver:self forKeyPath:@"version"];

  _selection = nil;

  [super invalidate];
}

static size_t
class_depth(Class c)
{
  size_t depth = 0;
  while (c != Nil)
    {
      c = [c superclass];
      depth++;
    }
  return depth;
}

static Class
common_superclass(Class c1, Class c2)
{
  if (c1 == Nil)
    return c2;
  if (c2 == Nil)
    return c1;
  if (c1 == c2)
    return c1;

  size_t c1_depth = class_depth(c1);
  size_t c2_depth = class_depth(c2);

  while (c1_depth > c2_depth)
    c1 = [c1 superclass], c1_depth--;
  while (c2_depth > c1_depth)
    c2 = [c2 superclass], c2_depth--;

  while (c1 != c2)
    {
      c1 = [c1 superclass];
      c2 = [c2 superclass];
    }

  return c1;
}

- (void)reloadSelection
{
  NSArray *selection = self.windowController.selection;

  if ([_selection isEqual:selection])
    return;

  for (GtTreeNode *tn in _selection)
    [tn.node removeObserver:self forKeyPath:@"version"];

  _selection = [selection copy];

  for (GtTreeNode *tn in _selection)
    [tn.node addObserver:self forKeyPath:@"version" options:0 context:NULL];

  Class cls = Nil;

  for (GtTreeNode *tn in _selection)
    {
      Class tn_class = [tn.node class];

      if (cls == Nil)
	cls = tn_class;
      else
	cls = common_superclass(cls, tn_class);
    }

  if (![cls isSubclassOfClass:[MgNode class]])
    cls = Nil;

  self.inspectorTree = [GtInspectorItem inspectorTreeForClass:cls];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
    change:(NSDictionary *)change context:(void *)context
{
  if ([keyPath isEqualToString:@"selection"])
    {
      [self reloadSelection];
    }
  else if ([keyPath isEqualToString:@"version"])
    {
      [self reloadValues];
    }
}

/** GtInspectorDelegate methods. **/

- (id)inspectedValueForKey:(NSString *)key
{
  NSInteger count = [_selection count];

  if (count == 0)
    return nil;

  id value = [((GtTreeNode *)_selection[0]).node valueForKey:key];

  if (count > 1)
    {
      for (NSInteger i = 1; i < count; i++)
	{
	  id value_i = [((GtTreeNode *)_selection[i]).node valueForKey:key];

	  if (value != value_i && ![value isEqual:value_i])
	    return nil;
	}
    }

  return value;
}

- (void)setInspectedValue:(id)value forKey:(NSString *)key
{
  GtDocument *document = self.document;

  for (GtTreeNode *tn in _selection)
    {
      [document node:tn setValue:value forKey:key];
    }
}

@end
