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

#import "BulletContact.h"
#import "BulletContactResult.h"
#import "BulletManifoldPoint.h"
#import "BulletCollision/CollisionDispatch/btCollisionWorld.h"

struct ContactResult : public btCollisionWorld::ContactResultCallback {
  void *m_parent;
  
  ContactResult(BulletContactResult *parent) : m_parent((__bridge void *)parent) {}
  
  btScalar addSingleResult(btManifoldPoint &cp,
                           const btCollisionObjectWrapper *colObj0Wrap, int partId0, int index0,
                           const btCollisionObjectWrapper *colObj1Wrap, int partId1, int index1) {
    BulletContactResult *parent = (__bridge BulletContactResult *)m_parent;
    BulletContact *contact = [[BulletContact alloc] initWithManifoldPoint:bullet_cast(&cp)
                                                                  object0:bullet_cast(colObj0Wrap->getCollisionObject())
                                                                  partId0:partId0
                                                                   index0:index0
                                                                  object1:bullet_cast(colObj1Wrap->getCollisionObject())
                                                                  partId1:partId1
                                                                   index1:index1];
    [parent addContact:contact];
    return 1.0f;
  }
};

@implementation BulletContactResult
{
  ContactResult *m_callback;
  NSMutableArray *m_contacts;
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    m_callback = new ContactResult(self);
    m_contacts = [NSMutableArray array];
  }
  return self;
}

- (void)dealloc
{
  delete m_callback;
}

- (btContactResultCallbackC *)callback
{
  return bullet_cast(static_cast<btCollisionWorld::ContactResultCallback *>(m_callback));
}

- (NSUInteger)numberOfContacts
{
  return m_contacts.count;
}

- (NSUInteger)count
{
  return m_contacts.count;
}

- (BulletContact *)contactAt:(NSUInteger)index
{
  return m_contacts[index];
}

- (void)addContact:(BulletContact *)contact
{
  [m_contacts addObject:contact];
}

- (BulletContact *)contactWith:(BulletRigidBody *)body
{
  for (BulletContact *contact in m_contacts) {
    if (contact.node0 == body || contact.node1 == body) {
      return contact;
    }
  }
  return nil;
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx
{
  return m_contacts[idx];
}

- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx
{
  m_contacts[idx] = obj;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(__unsafe_unretained id [])buffer
                                    count:(NSUInteger)len
{
  return [m_contacts countByEnumeratingWithState:state objects:buffer count:len];
}

@end
