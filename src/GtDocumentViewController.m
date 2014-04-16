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

#import "GtDocumentViewController.h"

#import "GtDocument.h"
#import "GtInspectorItem.h"

@implementation GtDocumentViewController

- (NSString *)title
{
  return @"Document";
}

- (id)initWithWindowController:(GtWindowController *)windowController
{
  self = [super initWithWindowController:windowController];
  if (self == nil)
    return nil;

  [self.document addObserver:self forKeyPath:@"documentSize"
   options:0 context:NULL];

  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  self.inspectorTree = [GtInspectorItem
			inspectorTreeForClass:[GtDocument class]];
}

- (void)invalidate
{
  [self.document removeObserver:self forKeyPath:@"documentSize"];

  [super invalidate];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
    change:(NSDictionary *)change context:(void *)context
{
  if (object == self.document)
    {
      [self reloadValues];
    }
}

/** GtInspectorDelegate methods. **/

- (id)inspectedValueForKey:(NSString *)key
{
  return [self.document valueForKey:key];
}

- (void)setInspectedValue:(id)value forKey:(NSString *)key
{
  [self.document setDocumentValue:value forKey:key];
}

@end
