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

#import "MgSpringFunction.h"

#import <Foundation/Foundation.h>

typedef float (^MgSpringEval)(float t);

@implementation MgSpringFunction
{
  CGFloat _mass;
  CGFloat _stiffness;
  CGFloat _damping;
  CGFloat _initialVelocity;

  MgSpringEval _eval;
}

- (id)init
{
  self = [super init];
  if (self == nil)
    return nil;

  /* These values look reasonable for a 1s animation. */

  _mass = 1;
  _stiffness = 250;
  _damping = 22;
  _initialVelocity = 0;

  return self;
}

- (NSInteger)domainDimension
{
  return 1;
}

- (NSInteger)rangeDimension
{
  return 1;
}

- (CGFloat)mass
{
  return _mass;
}

- (void)setMass:(CGFloat)x
{
  if (_mass != x)
    {
      _mass = x;
      _eval = nil;
    }
}

- (CGFloat)stiffness
{
  return _stiffness;
}

- (void)setStiffness:(CGFloat)x
{
  if (_stiffness != x)
    {
      _stiffness = x;
      _eval = nil;
    }
}

- (CGFloat)damping
{
  return _damping;
}

- (void)setDamping:(CGFloat)x
{
  if (_damping != x)
    {
      _damping = x;
      _eval = nil;
    }
}

- (CGFloat)initialVelocity
{
  return _initialVelocity;
}

- (void)setInitialVelocity:(CGFloat)x
{
  if (_initialVelocity != x)
    {
      _initialVelocity = x;
      _eval = nil;
    }
}

- (void)_makeSpringEvaluator
{
  if (_eval == nil)
    {
      /* All math from http://en.wikipedia.org/wiki/Damping */

      MgSpringEval eval = nil;

      float k = _stiffness;
      float m = _mass;
      float c = _damping;
      float x_0 = 1;
      float v_0 = -_initialVelocity;
      float omega_0 = sqrtf(k / m);
      float zeta = c / (2 * sqrtf(m * k));

      if (!(zeta < 1))
	{
	  float A = x_0;
	  float B = v_0 + omega_0 * x_0;

	  eval = ^float (float t)
	    {
	      return 1 - (A + B * t) * expf(-omega_0 * t);
	    };
	}
      else
	{
	  float zeta_omega_0 = zeta * omega_0;
	  float omega_d = omega_0 * sqrtf(1 - zeta*zeta);
	  float A = x_0;
	  float B = 1/omega_d * (zeta_omega_0 * x_0 + v_0);

	  eval = ^float (float t)
	    {
	      return 1 - (expf(-zeta_omega_0 * t)
			  * (A * cosf(omega_d * t) + B * (sinf(omega_d * t))));
	    };
	}

      _eval = [eval copy];
    }
}

- (void)evaluate:(const double *)in result:(double *)out
{
  if (_eval == nil)
    [self _makeSpringEvaluator];

  *out = _eval(*in);
}

- (double)durationForEpsilon:(double)eps
{
  float k = _stiffness;
  float m = _mass;
  float c = _damping;
  float omega_0 = sqrtf(k / m);
  float zeta = fminf(c / (2 * sqrtf(m * k)), 1);
  float zeta_omega_0 = zeta * omega_0;

  float t = 0;
  while (expf(-zeta_omega_0 * t) > eps)
    t += .1f;

  return t;
}

/** NSCopying methods. **/

- (id)copyWithZone:(NSZone *)zone
{
  MgSpringFunction *copy = [super copyWithZone:zone];

  copy->_mass = _mass;
  copy->_stiffness = _stiffness;
  copy->_damping = _damping;
  copy->_initialVelocity = _initialVelocity;
  copy->_eval = _eval;

  return copy;
}

/** NSCoding methods. **/

- (void)encodeWithCoder:(NSCoder *)c
{
  [super encodeWithCoder:c];

  [c encodeDouble:_mass forKey:@"mass"];
  [c encodeDouble:_stiffness forKey:@"stiffness"];
  [c encodeDouble:_damping forKey:@"damping"];
  [c encodeDouble:_initialVelocity forKey:@"initialVelocity"];
}

- (id)initWithCoder:(NSCoder *)c
{
  self = [super initWithCoder:c];
  if (self == nil)
    return nil;

  _mass = [c decodeDoubleForKey:@"mass"];
  _stiffness = [c decodeDoubleForKey:@"stiffness"];
  _damping = [c decodeDoubleForKey:@"damping"];
  _initialVelocity = [c decodeDoubleForKey:@"initialVelocity"];

  return self;
}

@end
