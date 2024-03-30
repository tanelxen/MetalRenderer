/**
 Bullet Continuous Collision Detection and Physics Library
 Copyright (c) 2003-2006 Erwin Coumans  http://continuousphysics.com/Bullet/
 
 Swift Binding
 Copyright (c) 2018 Yohei Yoshihara
 
 This software is provided 'as-is', without any express or implied warranty.
 In no event will the authors be held liable for any damages arising from the use of this software.
 Permission is granted to anyone to use this software for any purpose,
 including commercial applications, and to alter it and redistribute it freely,
 subject to the following restrictions:
 
 1. The origin of this software must not be misrepresented; you must not claim that you wrote the original software.
    If you use this software in a product, an acknowledgment in the product documentation would be appreciated
    but is not required.
 2. Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
 3. This notice may not be removed or altered from any source distribution.
 */

#import "BulletCollisionShape.h"

@implementation BulletCollisionShape

- (void)setMargin:(float)margin
{
  bullet_cast(self.ptr)->setMargin(margin);
}

- (float)margin
{
  return bullet_cast(self.ptr)->getMargin();
}

- (BOOL)isConcave
{
  return bullet_cast(self.ptr)->isConcave();
}

- (BOOL)isConvex
{
  return bullet_cast(self.ptr)->isConvex();
}

- (BOOL)isInfinite
{
  return bullet_cast(self.ptr)->isInfinite();
}

- (BOOL)isNonMoving
{
  return bullet_cast(self.ptr)->isNonMoving();
}

- (BOOL)isPolyhedral
{
  return bullet_cast(self.ptr)->isPolyhedral();
}

- (btCollisionShapeC *)ptr
{
  NSAssert(NO, @"subclass must override");
  return nil;
}

- (vector_float3)calculateLocalInertiaWithMass:(float)mass
{
  btVector3 inertia;
  bullet_cast(self.ptr)->calculateLocalInertia(mass, inertia);
  return vector3(inertia.x(), inertia.y(), inertia.z());
}

- (NSString *)description
{
  NSMutableString *s = [NSMutableString string];
  [s appendString:@"BulletShape<"];
  [s appendFormat:@"margin=%f,", self.margin];
  [s appendFormat:@"concave=%@,", self.isConcave ? @"true" : @"false"];
  [s appendFormat:@"convex=%@,", self.isConvex ? @"true" : @"false"];
  [s appendFormat:@"infinite=%@,", self.isInfinite ? @"true" : @"false"];
  [s appendFormat:@"nonMoving=%@,", self.isNonMoving ? @"true" : @"false"];
  [s appendFormat:@"polyhedral=%@", self.isPolyhedral ? @"true" : @"false"];
  [s appendString:@">"];
  return s;
}

@end
