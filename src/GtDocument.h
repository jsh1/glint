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

#import "GtBase.h"

extern NSString *const GtDocumentGraphDidChange;
extern NSString *const GtDocumentNodeDidChange;

@interface GtDocument : NSDocument
    <NSKeyedArchiverDelegate, NSKeyedUnarchiverDelegate>

@property(nonatomic, readonly, strong) GtWindowController *windowController;

@property(nonatomic, assign) CGSize documentSize;
@property(nonatomic, assign, readonly) CGPoint documentCenter;
@property(nonatomic, strong) MgModuleLayer *documentNode;

- (void)disableUndo;
- (void)reenableUndo;

@property(nonatomic, assign, readonly, getter=isUndoEnabled) BOOL undoEnabled;

- (void)registerUndo:(void (^)())thunk;

- (IBAction)export:(id)sender;

- (BOOL)canAddObjectsFromPasteboard:(NSPasteboard *)pboard
    asImages:(BOOL)flag;

- (BOOL)addObjectsFromPasteboard:(NSPasteboard *)pboard
    asImages:(BOOL)flag atDocumentPoint:(CGPoint)p;
- (BOOL)addObjectsFromPasteboard:(NSPasteboard *)pboard
    asImages:(BOOL)flag atDocumentPoint:(CGPoint)p
    intoNode:(GtTreeNode *)parent atIndex:(NSInteger)idx;

- (IBAction)selectAll:(id)sender;
- (IBAction)selectNone:(id)sender;
- (IBAction)delete:(id)sender;
- (IBAction)cut:(id)sender;
- (IBAction)copy:(id)sender;
- (IBAction)duplicate:(id)sender;
- (IBAction)alias:(id)sender;
- (IBAction)copyDocument:(id)sender;
- (IBAction)paste:(id)sender;
- (BOOL)canPaste;
- (IBAction)pasteAsImage:(id)sender;
- (BOOL)canPasteAsImage;

- (IBAction)addLayer:(id)sender;
- (IBAction)addImage:(id)sender;
- (IBAction)group:(id)sender;
- (IBAction)ungroup:(id)sender;

- (IBAction)raiseObject:(id)sender;

- (IBAction)toggleEnabled:(id)sender;
- (NSInteger)toggleEnabledState;
- (IBAction)toggleLayerGroup:(id)sender;
- (NSInteger)toggleLayerGroupState;
- (IBAction)setBlendMode:(id)sender;
- (NSInteger)setBlendModeState:(id)sender;
- (IBAction)setAlpha:(id)sender;
- (NSInteger)setAlphaState:(id)sender;

- (void)moveObjects:(CGPoint (^)(CGPoint p))fun;

- (IBAction)addModuleState:(id)sender;
- (IBAction)removeModuleState:(id)sender;

- (IBAction)nextModuleState:(id)sender;
- (IBAction)previousModuleState:(id)sender;
- (IBAction)parentModuleState:(id)sender;
- (IBAction)gotoModuleState:(id)sender;

- (void)removeTreeNodeFromParent:(GtTreeNode *)tn;
- (void)replaceTreeNode:(GtTreeNode *)tn with:(MgNode *)node;

- (void)node:(GtTreeNode *)node setValue:(id)obj forKey:(NSString *)key;
- (void)node:(GtTreeNode *)tn insertObject:(id)value atIndex:(NSInteger)idx
    forKey:(NSString *)key;
- (void)node:(GtTreeNode *)tn replaceObject:(id)oldValue atIndex:(NSInteger)idx
    withObject:(id)value forKey:(NSString *)key;
- (void)node:(GtTreeNode *)tn removeObject:(id)oldValue atIndex:(NSInteger)idx
    forKey:(NSString *)key;
- (void)node:(GtTreeNode *)tn moveObject:(id)value atIndex:(NSInteger)idx
    by:(NSInteger)delta forKey:(NSString *)key;

- (void)node:(GtTreeNode *)tn transition:(MgNodeTransition *)trans
    setTiming:(MgTransitionTiming *)timing forKey:(NSString *)key;

- (BOOL)nodeIsEnabled:(GtTreeNode *)tn;
- (void)node:(GtTreeNode *)tn setEnabled:(BOOL)flag;

- (void)module:(MgModuleLayer *)node state:(MgModuleState *)state
    setValue:(id)value forKey:(NSString *)key;

- (void)setDocumentValue:(id)value forKey:(NSString *)key;

@end
