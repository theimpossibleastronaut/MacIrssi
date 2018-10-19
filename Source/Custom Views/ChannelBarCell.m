/*
 ChannelBarCell.m
 Copyright (c) 2008, 2009 Matt Wright, 2008 Nils Hjelte.
 
 MacIrssi is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 2 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "ChannelBarCell.h"
#import "ChannelController.h"
#import "fe-windows.h"
#import "servers.h"
#import "ColorSet.h"

@implementation ChannelBarCell

//-------------------------------------------------------------------
// initWithWindowRec:rec
// Designated initializer
//-------------------------------------------------------------------
- (id)initWithWindowRec:(WINDOW_REC *)rec
{
  if (self = [super initWithFrame:NSZeroRect]) {
    highlightAttributes = [[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Monaco" size:9.0], NSFontAttributeName, nil] retain];
    
    isActive = NO;
    windowRec = rec;
    
    inactiveBorderBezierPath = [[NSBezierPath alloc] init];
    [inactiveBorderBezierPath setLineWidth:2.0];
    [inactiveBorderBezierPath setLineCapStyle:NSSquareLineCapStyle];
    [inactiveBorderBezierPath setLineJoinStyle:NSMiterLineJoinStyle];
  }
  return self;
}

/* Dealloc */
- (void)dealloc
{
	[highlightAttributes release];
	[inactiveBorderBezierPath release];
	[super dealloc];
}

//-------------------------------------------------------------------
// stringWidth
// Returns the width of the string.
//-------------------------------------------------------------------
- (float)stringWidth
{
	if ([self name])
		return [[self name] sizeWithAttributes:highlightAttributes].width;
	else
		return 0;
}

//-------------------------------------------------------------------
// setFrame:frame
// Adjusts the tooltip area to the new frame.
//-------------------------------------------------------------------
- (void)setFrame:(NSRect)frame
{
	NSRect oldFrame = [self frame];
	[super setFrame:frame];
  
  [inactiveBorderBezierPath removeAllPoints];
  [inactiveBorderBezierPath appendBezierPathWithRect:[self bounds]];
  
  if ( !NSEqualRects(frame, oldFrame) )
	{
		[self removeAllToolTips];
		[self addToolTipRect:[self bounds] owner:self userData:nil];
	}
}

//-------------------------------------------------------------------
// view:stringForToolTip:point:userData:
// Returns the string to be displayed in a tooltip for a nick in the
// userlist.
//-------------------------------------------------------------------
- (NSString *)view:(NSView *)view stringForToolTip:(NSToolTipTag)tag point:(NSPoint)point userData:(void *)userData
{
	NSArray *nicks = [(ChannelController *)windowRec->gui_data nicks];
	int nickCount = (int)[nicks count];
	int serverOpCount = 0;
	int opCount = 0;
	int halfOpCount = 0;
	int voiceCount = 0;
	int normalCount = 0;
	int i;
	NICK_REC *nick;
	
	for (i = 0; i < nickCount; i++) {
		nick = (NICK_REC *)[[nicks objectAtIndex:i] pointerValue];
    
		if (nick->serverop)
			serverOpCount++;
		else if (nick->op)
			opCount++;
		else if (nick->halfop)
			halfOpCount++;
		else if (nick->voice)
			voiceCount++;
		else
			normalCount++;
	}
	
	SERVER_REC *server = windowRec->active_server;
	char *serverName = (server && server->tag) ? server->tag : "";
	
	NSMutableString *toolTip = [NSMutableString stringWithFormat:@"Name: %@\nServer: %s", [self name], serverName];
	NSString *mode = [(ChannelController *)windowRec->gui_data mode];
	if (mode)
		[toolTip appendFormat:@"\nMode: %@", mode];
	if (nickCount > 0)
		[toolTip appendFormat:@"\nNicks: %d (%d serverops, %d ops, %d halfops, %d voices, %d normal)", nickCount, serverOpCount, opCount, halfOpCount, voiceCount, normalCount];
	return toolTip;
}

//-------------------------------------------------------------------
// borderWidth
// Returns the border width
//-------------------------------------------------------------------
+ (float)borderWidth
{
	return 6.0;
}

//-------------------------------------------------------------------
// name
// Returns the name of the channel
//-------------------------------------------------------------------
- (NSString *)name
{
	return [(ChannelController *)windowRec->gui_data name];
}

//-------------------------------------------------------------------
// windowRec
// Returns the window rec of the channel
//-------------------------------------------------------------------
- (WINDOW_REC *)windowRec
{
	return windowRec;
}

#if 0
/**
 * Sets data level. Clamps to max and min
 */
- (void)setDataLevel:(int)level
{
	if (level > 3)
		level = 3;
	else if (level < 0)
		level = 0;
	
	dataLevel = level;
}
#endif

//-------------------------------------------------------------------
// drawRect:rect
// Draws the cell
//-------------------------------------------------------------------
- (void)drawRect:(NSRect)rect
{
  NSRect backgroundRect = NSInsetRect([self bounds], 2.0, 2.0);
  if (isActive) {
    [[NSColor clearColor] set];
    NSRectFillUsingOperation([self bounds], NSCompositeDestinationOver);	
    [[NSColor  colorWithCalibratedRed:246.0/255 green:249.0/255 blue:232.0/255 alpha:1.0] set];
  }
  else
  {
    [[NSColor grayColor] set];
  }
  NSRectFillUsingOperation(backgroundRect, NSCompositeCopy);	
  
  /* Draw channel name */
  NSRect stringRect = NSInsetRect([self bounds], [ChannelBarCell borderWidth], 1.0);
  if (isActive && [NSApp isActive]) {
    [highlightAttributes setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
  } else {
    int dataLevel = (windowRec->data_level > 3 ? 3 : windowRec->data_level);
    
    if (isActive && ![NSApp isActive] && (dataLevel == 0)) {
      [highlightAttributes setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
    } else {
      [highlightAttributes setObject:[ColorSet colorForKey:[[ColorSet channelListForegroundKeys] objectAtIndex:dataLevel]] forKey:NSForegroundColorAttributeName];
    }
  }
  
  [[self name] drawAtPoint:stringRect.origin withAttributes:highlightAttributes];
  
  if ([self stringWidth] > [self bounds].size.width - 2 * [ChannelBarCell borderWidth]) {
    NSRect removeRect = backgroundRect;
    removeRect.origin.x += [self bounds].size.width - [ChannelBarCell borderWidth];
    removeRect.size.width = [ChannelBarCell borderWidth];
    
    if (isActive && [NSApp isActive])
    {
      [[NSColor colorWithCalibratedRed:246.0/255 green:249.0/255 blue:232.0/255 alpha:1.0] set];
    }
    else
    {
      [[NSColor grayColor] set];
    }
    
    [NSBezierPath fillRect:removeRect];
  }		
  
  if (!isActive) {
    // the bounds of inactiveBorderBezierPath are set during setFrame:
    [[NSColor whiteColor] set];
    [inactiveBorderBezierPath stroke];
  }
}

//-------------------------------------------------------------------
// setActive:flag
// Sets active attribute
//-------------------------------------------------------------------
- (void)setActive:(BOOL)flag
{
	isActive = flag;
	[self setNeedsDisplay:TRUE];
}

//-------------------------------------------------------------------
// mouseDown:theEvent
// Switch active channel to the channel of the cell
//-------------------------------------------------------------------
- (void)mouseDown:(NSEvent *)theEvent
{
	window_set_active(windowRec);
}

@end
