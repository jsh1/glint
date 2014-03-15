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

#if TARGET_OS_MAC

#import "MgNodePasteboard.h"

#import <AppKit/AppKit.h>

@implementation MgNode (MgNodePasteboard)

/** NSPasteboardWriting methods. **/

- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pboard
{
  return @[MgArchiveType, MgNodeType];
}

- (NSPasteboardWritingOptions)writingOptionsForType:(NSString *)type
    pasteboard:(NSPasteboard *)pboard
{
  return 0;
}

- (id)pasteboardPropertyListForType:(NSString *)type
{
  if (UTTypeConformsTo((__bridge CFStringRef)type,
		       (__bridge CFStringRef)MgNodeType))
    {
      return [NSKeyedArchiver archivedDataWithRootObject:self];
    }

  return nil;
}

/** NSPasteboardReading methods. **/

+ (NSArray *)readableTypesForPasteboard:(NSPasteboard *)pboard
{
  return @[MgNodeType, MgArchiveType];
}

+ (NSPasteboardReadingOptions)readingOptionsForType:(NSString *)type
    pasteboard:(NSPasteboard *)pboard
{
  if (UTTypeConformsTo((__bridge CFStringRef)type,
		       (__bridge CFStringRef)MgNodeType))
    {
      return NSPasteboardReadingAsKeyedArchive;
    }

  return 0;
}

- (id)initWithPasteboardPropertyList:(id)plist ofType:(NSString *)type
{
  return nil;
}

@end

#endif /* TARGET_OS_MAC */
