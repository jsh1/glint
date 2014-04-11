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

#import "GtStateListItemView.h"

#import "GtAppDelegate.h"
#import "GtColor.h"
#import "GtStateListViewController.h"

@implementation GtStateListItemView
{
  MgModuleState *_state;
  NSBackgroundStyle _backgroundStyle;

  NSOperation *_thumbnailOp;
  NSImage *_thumbnailImage;
  BOOL _pendingThumbnail;
}

- (void)dealloc
{
  [_state removeObserver:self forKeyPath:@"name"];
  [_state removeObserver:self forKeyPath:@"superstate"];
}

- (MgModuleState *)state
{
  return _state;
}

- (void)setState:(MgModuleState *)state
{
  [_state removeObserver:self forKeyPath:@"name"];
  [_state removeObserver:self forKeyPath:@"superstate"];

  _state = state;

  [_state addObserver:self forKeyPath:@"name" options:0 context:nil];
  [_state addObserver:self forKeyPath:@"superstate" options:0 context:nil];

  [self updateControls];

  _thumbnailImage = nil;
  [self updateThumbnail];
}

- (void)updateControls
{
  if (_state == nil)
    {
      [_nameField setObjectValue:@"Base State"];
      [_basedOnField setObjectValue:@" "];
    }
  else
    {
      [_nameField setObjectValue:_state.name];
      [_basedOnField setObjectValue:_state.superstate.name];
    }

  [_nameField setEnabled:_state != nil];
  [_basedOnField setEnabled:_state != nil];
}

- (void)invalidateThumbnail
{
  if (!_pendingThumbnail)
    {
      _thumbnailImage = nil;
      _pendingThumbnail = YES;

      dispatch_time_t then = dispatch_time(DISPATCH_TIME_NOW,
					   1LL * NSEC_PER_SEC);

      dispatch_after(then, dispatch_get_main_queue(), ^
	{
	  _pendingThumbnail = NO;
	  [self updateThumbnail];
	});
    }
}

- (void)updateThumbnail
{
  if (_thumbnailImage != nil)
    {
      [_thumbnailView setImage:_thumbnailImage];
      return;
    }

  if (_thumbnailOp == nil)
    {
      NSMapTable *table = [NSMapTable strongToStrongObjectsMapTable];
      MgModuleLayer *layer = [_controller.moduleLayer mg_graphCopy:table];

      CGFloat sx = [_thumbnailView bounds].size.width / layer.size.width;
      CGFloat sy = [_thumbnailView bounds].size.height / layer.size.height;
      CGFloat s = fmin(sx, sy);

      _thumbnailOp = [NSBlockOperation blockOperationWithBlock:^
	{
	  [layer setModuleState:[table objectForKey:_state] animated:NO];

	  CGImageRef im = [layer copyImageWithScale:s];

	  dispatch_async(dispatch_get_main_queue(), ^
	    {
	      _thumbnailOp = nil;
	      if (im != nil)
		{
		  _thumbnailImage = [[NSImage alloc] initWithCGImage:im
				     size:NSSizeFromCGSize(layer.size)];
		  [_thumbnailView setImage:_thumbnailImage];
		  CGImageRelease(im);
		}
	      else
		_thumbnailImage = nil;
	    });
	}];

      [((GtAppDelegate *)[NSApp delegate]).thumbnailQueue
       addOperation:_thumbnailOp];
    }
}

- (IBAction)controlAction:(id)sender
{
  NSString *key = nil;

  if (sender == _nameField)
    key = @"name";
  else if (sender == _basedOnField)
    key = @"superstate.name";

  if (key != nil)
    [_controller state:_state setValue:[sender objectValue] forKey:key];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
    change:(NSDictionary *)change context:(void *)context
{
  if ([keyPath isEqualToString:@"name"]
      || [keyPath isEqualToString:@"superstate"])
    {
      [self updateControls];
    }
}

@end
