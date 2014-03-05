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

#import "YuTreeViewController.h"

#import "YuDocument.h"
#import "YuWindowController.h"

@implementation YuTreeViewController

+ (NSString *)viewNibName
{
  return @"YuTreeView";
}

- (void)viewDidLoad
{
  [[NSNotificationCenter defaultCenter]
   addObserver:self selector:@selector(documentNodeChanged:)
   name:YuDocumentNodeDidChange object:self.controller.document];

  [[NSNotificationCenter defaultCenter]
   addObserver:self selector:@selector(selectionChanged:)
   name:YuWindowControllerSelectionDidChange object:self.controller];
}

- (void)documentNodeChanged:(NSNotification *)note
{
}

- (void)selectionChanged:(NSNotification *)note
{
}

/** NSOutlineViewDataSource methods. **/

- (NSInteger)outlineView:(NSOutlineView *)ov numberOfChildrenOfItem:(id)item
{
  return 0;
}

- (id)outlineView:(NSOutlineView *)ov child:(NSInteger)index ofItem:(id)item
{
  return nil;
}

- (BOOL)outlineView:(NSOutlineView *)ov isItemExpandable:(id)item
{
  return NO;
}

- (id)outlineView:(NSOutlineView *)ov objectValueForTableColumn:
    (NSTableColumn *)col byItem:(id)item
{
  return nil;
}

/** NSOutlineViewDelegate methods. **/

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
}

@end
