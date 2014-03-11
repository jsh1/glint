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

#import "CoreAnimationExtensions.h"

@implementation GtAppDelegate

- (id)init
{
  self = [super init];
  if (self == nil)
    return nil;

  NSString *path = [[NSBundle mainBundle]
		    pathForResource:@"defaults" ofType:@"plist"];
  if (path != nil)
    {
      NSData *data = [NSData dataWithContentsOfFile:path];

      if (data != nil)
	{
	  NSDictionary *dict = [NSPropertyListSerialization
				propertyListWithData:data options:
				NSPropertyListImmutable format:nil
				error:nil];
	  if (dict != nil)
	    [[NSUserDefaults standardUserDefaults] registerDefaults:dict];
	}
    }

  return self;
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
    
  for (NSMenuItem *item in [menu itemArray])
    {
      SEL action = [item action];

      if (action == @selector(toggleEnabled:))
	[item setState:[document toggleEnabledState]];
      else if (action == @selector(toggleIsolated:))
	[item setState:[document toggleIsolatedState]];
      else if (action == @selector(setBlendMode:))
	[item setState:[document setBlendModeState:item]];
      else if (action == @selector(setAlpha:))
	[item setState:[document setAlphaState:item]];
    }
}

@end
