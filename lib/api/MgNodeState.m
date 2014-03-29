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

#import "MgNodeState.h"

#import "MgCoreGraphics.h"
#import "MgModuleState.h"
#import "MgNodeTransition.h"

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@implementation MgNodeState
{
  BOOL _enabled;

  struct {
    bool enabled :1;
  } _defines;
}

+ (instancetype)state
{
  return [[self alloc] init];
}

+ (instancetype)defaultState
{
  MgNodeState *state = [[self alloc] init];
  [state setDefaults];
  return state;
}

+ (NSSet *)allProperties
{
  static NSMapTable *table;
  static dispatch_queue_t queue;
  static dispatch_once_t once;

  dispatch_once(&once, ^
    {
      queue = dispatch_queue_create("MgNodeState.defaultState",
				    DISPATCH_QUEUE_CONCURRENT);
      table = [NSMapTable strongToStrongObjectsMapTable];
    });

  __block NSSet *result = nil;

  dispatch_sync(queue, ^
    {
      NSSet *set = [table objectForKey:self];

      if (set == nil)
	{
	  set = [self _allProperties];
	  [table setObject:set forKey:self];
	}

      result = set;
    });

  return result;
}

+ (NSSet *)_allProperties
{
  if (self == [MgNodeState class])
    {
      return [NSSet setWithObjects:@"enabled", nil];
    }
  else
    {
      NSMutableSet *set = [NSMutableSet set];

      /* Add all non-readonly objc properties defined by the class. */

      unsigned int count = 0;
      objc_property_t *plist = class_copyPropertyList(self, &count);
      if (plist == NULL)
	return nil;

      if (count != 0)
	{
	  for (unsigned int i = 0; i < count; i++)
	    {
	      const char *attr = property_getAttributes(plist[i]);
	      bool read_only = false;
	      while (attr != NULL)
		{
		  if (*attr == 'R')		/* read-only */
		    {
		      read_only = true;
		      break;
		    }
		  attr = strchr(attr, ',');
		  if (attr != NULL)
		    attr++;
		}

	      if (!read_only)
		{
		  const char *name = property_getName(plist[i]);
		  [set addObject:[NSString stringWithUTF8String:name]];
		}
	    }
	}

      free(plist);

      [set unionSet:[[self superclass] allProperties]];

      return [set copy];
    }
}

- (void)setDefaults
{
  _enabled = YES;

  _defines.enabled = true;
}

+ (BOOL)accessInstanceVariablesDirectly
{
  /* -valueForUndefinedKey: and -setValue:forUndefinedKey: aren't called
     unless this method returns false. And if those methods aren't called
     we can't manually call our accessor methods for CF object types. */

  return NO;
}

- (id)init
{
  return [super init];
}

- (BOOL)isDescendantOf:(MgNodeState *)state
{
  for (MgNodeState *s = self; s != nil; s = s.superstate)
    {
      if (s == state)
	return YES;
    }

  return NO;
}

static size_t
state_depth(MgNodeState *s)
{
  size_t depth = 0;
  while (s != nil)
    s = s.superstate, depth++;
  return depth;
}

- (MgNodeState *)ancestorSharedWith:(MgNodeState *)s2
{
  MgNodeState *s1 = self;

  if (s1 == nil)
    return s2;
  if (s2 == nil)
    return s1;
  if (s1 == s2)
    return s1;

  size_t s1_depth = state_depth(s1);
  size_t s2_depth = state_depth(s2);

  while (s1_depth > s2_depth)
    s1 = s1.superstate, s1_depth--;
  while (s2_depth > s1_depth)
    s2 = s2.superstate, s2_depth--;

  while (s1 != s2)
    {
      s1 = s1.superstate;
      s2 = s2.superstate;
    }

  return s1;
}

- (BOOL)definesValueForKey:(NSString *)key
{
  if ([key isEqualToString:@"enabled"])
    return _defines.enabled;

  [NSException raise:@"MgNodeState"
   format:@"does not define property %@", key];
  return NO;
}

- (void)setDefinesValue:(BOOL)flag forKey:(NSString *)key
{
  if ([key isEqualToString:@"enabled"])
    {
      _defines.enabled = flag;
      return;
    }

  [NSException raise:@"MgNodeState"
   format:@"does not define property %@", key];
}

- (MgNodeState *)evaluateTransition:(MgTransition *)trans atTime:(double)t
    to:(MgNodeState *)to
{
  MgNodeState *dest = [[self class] state];

  dest.superstate = self;

  [dest applyTransition:trans atTime:t to:to];

  return dest;
}

- (void)applyTransition:(MgTransition *)trans atTime:(double)t
    to:(MgNodeState *)to
{
  double t_ = trans != nil ? [trans evaluateTime:t forKey:@"enabled"] : t;
  _enabled = MgBoolMix(self.enabled, to.enabled, t_);
  _defines.enabled = true;
}

- (BOOL)isEnabled
{
  if (_defines.enabled)
    return _enabled;
  else
    return self.superstate.enabled;
}

- (void)setEnabled:(BOOL)flag
{
  if (_defines.enabled)
    _enabled = flag;
  else
    self.superstate.enabled = flag;
}

/** MgGraphCopying methods. **/

- (id)graphCopy:(NSMapTable *)map
{
  MgNodeState *copy = [[[self class] alloc] init];

  copy->_moduleState = [_moduleState mg_conditionalGraphCopy:map];
  copy->_superstate = [_superstate mg_graphCopy:map];
  copy->_enabled = _enabled;
  copy->_defines = _defines;

  return copy;
}

/** NSSecureCoding methods. **/

+ (BOOL)supportsSecureCoding
{
  return YES;
}

- (void)encodeWithCoder:(NSCoder *)c
{
  if (_moduleState != nil)
    [c encodeConditionalObject:_moduleState forKey:@"moduleState"];

  if (_superstate != nil)
    [c encodeObject:_superstate forKey:@"superstate"];

  if (_defines.enabled)
    [c encodeBool:_enabled forKey:@"enabled"];
}

- (id)initWithCoder:(NSCoder *)c
{
  self = [self init];
  if (self == nil)
    return nil;

  if ([c containsValueForKey:@"moduleState"])
    {
      _moduleState = [c decodeObjectOfClass:[MgModuleState class]
		      forKey:@"moduleState"];
    }

  if ([c containsValueForKey:@"superstate"])
    {
      _superstate = [c decodeObjectOfClass:[MgNodeState class]
		     forKey:@"superstate"];
    }

  if (_superstate == nil)
    _superstate = [[self class] defaultState];

  if ([c containsValueForKey:@"enabled"])
    {
      _enabled = [c decodeBoolForKey:@"enabled"];
      _defines.enabled = true;
    }

  return self;
}

@end
