// From Colloquy

#import "JVFontPreviewField.h"

#if __LP64__ || TARGET_OS_EMBEDDED || TARGET_OS_IPHONE || TARGET_OS_WIN32 || NS_BUILD_32_LIKE_64
typedef unsigned long NSUInteger;
#else
typedef unsigned int NSUInteger;
#endif

@implementation JVFontPreviewField

- (id) initWithCoder:(NSCoder *) coder {
	self = [super initWithCoder:coder];
	if( [coder allowsKeyedCoding] ) {
		_showPointSize = [coder decodeBoolForKey:@"showPointSize"];
		_showFontFace = [coder decodeBoolForKey:@"showFontFace"];
		_actualFont = [[coder decodeObjectForKey:@"actualFont"] retain];
	} else {
		[coder decodeValueOfObjCType:@encode(char) at:&_showPointSize];
		[coder decodeValueOfObjCType:@encode(char) at:&_showFontFace];
		_actualFont = [[coder decodeObject] retain];
	}
	return self;
}

- (void) encodeWithCoder:(NSCoder *) coder {
	[super encodeWithCoder:coder];
	if( [coder allowsKeyedCoding] ) {
		[coder encodeBool:_showPointSize forKey:@"showPointSize"];
		[coder encodeBool:_showFontFace forKey:@"showFontFace"];
		[coder encodeObject:_actualFont forKey:@"actualFont"];
	} else {
		[coder encodeValueOfObjCType:@encode(char) at:&_showPointSize];
		[coder encodeValueOfObjCType:@encode(char) at:&_showFontFace];
		[coder encodeObject:_actualFont];
	}
}

- (void) dealloc {
	[_actualFont release];
	_actualFont = nil;
	[super dealloc];
}

- (void) selectFont:(id) sender {
	NSFont *font = [sender convertFont:[self font]];

	if(!font) return;

	if([[self delegate] respondsToSelector:@selector(fontPreviewField:shouldChangeToFont:)])
		if(![(id)[self delegate] fontPreviewField:self shouldChangeToFont:font]) return;

	[self setFont:font];

	if([[self delegate] respondsToSelector:@selector(fontPreviewField:didChangeToFont:)])
		[(id)[self delegate] fontPreviewField:self didChangeToFont:font];
}

#ifndef MAC_OS_X_VERSION_10_3
#define NSFontPanelStandardModesMask 0
#define NSFontPanelSizeModeMask 0
#define NSFontPanelFaceModeMask 0
#endif

/*- (NSFontPanelModeMask) validModesForFontPanel:(NSFontPanel *) fontPanel
{
	NSUInteger ret = NSFontPanelStandardModesMask;
	if(!_showPointSize) ret ^= NSFontPanelSizeModeMask;
	if(!_showFontFace) ret ^= NSFontPanelFaceModeMask;
	return ret;
}*/

- (BOOL) becomeFirstResponder 
{
	[[NSFontManager sharedFontManager] setSelectedFont:_actualFont isMultiple:NO];
	return YES;
}

- (void) setFont:(NSFont *)font
{
	if(!font) return;

	[_actualFont autorelease];
	_actualFont = [font retain];
  
  float displaySize = [_actualFont pointSize] < 12.0 ? [_actualFont pointSize] : [NSFont smallSystemFontSize];

	[super setFont:[[NSFontManager sharedFontManager] convertFont:font toSize:displaySize]];

	NSMutableAttributedString *text = nil;
	if(_showPointSize){
//#warning 64BIT: Check formatting arguments
		text = [[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@, %.1f pt.", (_showFontFace ? [_actualFont displayName] : [_actualFont familyName]), [_actualFont pointSize]]] autorelease];
	}else{
		text = [[[NSMutableAttributedString alloc] initWithString:( _showFontFace ? [_actualFont displayName] : [_actualFont familyName] )] autorelease];
	}

	NSMutableParagraphStyle *paraStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];

	[paraStyle setMinimumLineHeight:NSHeight([self bounds])];
	[paraStyle setMaximumLineHeight:NSHeight([self bounds])];
	[text addAttribute:NSParagraphStyleAttributeName value:paraStyle range:NSMakeRange(0, [text length])];

	[self setObjectValue:text];
}

- (IBAction) chooseFontWithFontPanel:(id) sender
{
	[[NSFontManager sharedFontManager] setAction:@selector( selectFont: )];
	[[self window] makeFirstResponder:self];
	[[NSFontManager sharedFontManager] orderFrontFontPanel:nil];
}

- (void) setShowPointSize:(BOOL) show 
{
	_showPointSize = show;
}

- (void) setShowFontFace:(BOOL) show
{
	_showFontFace = show;
}

@end
