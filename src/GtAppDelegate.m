/* -*- c-style: gnu -*-

   Copyright (c) 2013 John Harper <jsh@unfactored.org>

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

#import "GtAppDelegate.h"

#import "GtDocument.h"
#import "GtWindowController.h"

#import "CoreAnimationExtensions.h"

@implementation GtAppDelegate
{
  NSMenu *_copiedObjectMenu;
  NSOperationQueue *_thumbnailQueue;
}

- (id)init
{
  self = [super init];
  if (self == nil)
    return nil;

  NSString *path = [[NSBundle mainBundle]
		    pathForResource:@"defaults" ofType:@"json"];
  if (path != nil)
    {
      NSData *data = [NSData dataWithContentsOfFile:path];

      if (data != nil)
	{
	  NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:
				data options:0 error:nil];
	  if (dict != nil)
	    [[NSUserDefaults standardUserDefaults] registerDefaults:dict];
	}
    }

  return self;
}

- (void)showObjectContextMenuWithEvent:(NSEvent *)e forView:(NSView *)view
{
  [NSMenu popUpContextMenu:_objectContextMenu withEvent:e forView:view];
}

- (NSOperationQueue *)thumbnailQueue
{
  if (_thumbnailQueue == nil)
    {
      _thumbnailQueue = [[NSOperationQueue alloc] init];
      [_thumbnailQueue setName:@"GtAppDelegate.thumbnailQueue"];
    }

  return _thumbnailQueue;
}

/** NSApplicationDelegate methods. */

- (BOOL)application:(NSApplication *)app openFile:(NSString *)file
{
  NSDocumentController *controller
    = [NSDocumentController sharedDocumentController];

  GtDocument *document = (GtDocument *)[controller currentDocument];

  NSError *err = nil;
  BOOL opened = NO;

  /* Attempt to open in the current window if that window is untitled
     and unmodified. */

  if (document != nil
      && [document fileURL] == nil
      && ![document isDocumentEdited])
    {
      NSString *type = [[NSWorkspace sharedWorkspace]
			typeOfFile:file error:nil];
      if (type != nil)
	{
	  [document revertToContentsOfURL:[NSURL fileURLWithPath:file]
	   ofType:type error:&err];
	  opened = YES;
	}
    }

  if (!opened)
    {
      [controller openDocumentWithContentsOfURL:[NSURL fileURLWithPath:file]
       display:YES error:&err];
    }

  return err == nil;
}

/** CALayer delegate methods. **/

- (id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)key
{
  return [CATransaction actionForLayer:layer forKey:key];
}

/** NSMenuDelegate methods. **/

- (void)menuNeedsUpdate:(NSMenu *)menu
{
  GtDocument *document = (GtDocument *)
   [[NSDocumentController sharedDocumentController] currentDocument];

  if (![document isKindOfClass:[GtDocument class]])
    document = nil;

  GtWindowController *controller = document.windowController;
    
  for (NSMenuItem *item in [menu itemArray])
    {
      SEL action = [item action];

      if (action == @selector(toggleEnabled:))
	[item setState:[document toggleEnabledState]];
      else if (action == @selector(toggleLayerGroup:))
	[item setState:[document toggleLayerGroupState]];
      else if (action == @selector(setBlendMode:))
	[item setState:[document setBlendModeState:item]];
      else if (action == @selector(setAlpha:))
	[item setState:[document setAlphaState:item]];
      else if (action == @selector(toggleView:))
	[item setState:[controller viewState:item]];
    }
}

@end
