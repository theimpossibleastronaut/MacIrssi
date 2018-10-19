/*
 ChannelController.m
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

//*****************************************************************
// Controls the GUI of a channel.
//*****************************************************************

#import "ChannelController.h"
#import "AppController.h"
#import "window-activity.h"
#import "IrssiBridge.h"
#import "ColorSet.h"
#import "NSAttributedStringAdditions.h"

extern int currentDataLevel;
void get_mirc_color(const char **str, int *fg_ret, int *bg_ret);

@implementation ChannelController

- (MIChannelSearchController*)searchController
{
  return searchController;
}

- (MISearchBar*)searchBar
{
  return searchBar;
}

- (NSTextView*)textView
{
  return mainTextView;
}

- (void)setSearchBarVisible:(BOOL)flag
{
  id target = (splitView ? (id)splitView : (id)[mainTextView enclosingScrollView]);
  
  if (flag && !searchBar)
  {
    /* Setup state so that we maintain scroll position */
    [self beginTextUpdates];
    
    /* Make a search bar, link it to the search controller and put onscreen. */
    searchBar = [[MISearchBar alloc] initWithFrame:NSMakeRect(0, 0, [target frame].size.width, 25.0f)];
    [searchBar setDelegate:searchController];
    [[target superview] addSubview:searchBar positioned:NSWindowBelow relativeTo:[topicTextField superview]];
    
    /* Pull the splitView down by 20 pixels and put it in there */
    NSRect r = [target frame];
    r.size.height -= [searchBar frame].size.height;
    
    [target setLayoutName:@"targetView"];
    
    /* Search bar is directly above the split view, centered X axis, equal width */
    [searchBar addLayoutConstraint:[CHLayoutConstraint constraintWithAttribute:CHLayoutConstraintAttributeMinY relativeTo:@"targetView" attribute:CHLayoutConstraintAttributeMaxY]];
    [searchBar addLayoutConstraint:[CHLayoutConstraint constraintWithAttribute:CHLayoutConstraintAttributeWidth relativeTo:@"targetView" attribute:CHLayoutConstraintAttributeWidth]];
    [searchBar addLayoutConstraint:[CHLayoutConstraint constraintWithAttribute:CHLayoutConstraintAttributeMidX relativeTo:@"targetView" attribute:CHLayoutConstraintAttributeMidX]];
    
    [target setFrame:r];
    
    /* Now restore scroll position */
    [self endTextUpdates];
  }
  else if (!flag && searchBar)
  {
    [self beginTextUpdates];
    
    [searchBar removeAllLayoutConstraints];
    
    /* Push the target view up before we remove the search bar */
    NSRect r = [target frame];
    r.size.height += [searchBar frame].size.height;

    [target setFrame:r];
    [target setLayoutName:nil];
    
    [searchBar removeFromSuperview];
    [searchBar release];
    searchBar = nil;
    
    [self endTextUpdates];
  }
  
  if (flag)
  {
    /* Always make the search box responder on keypress */
    [[searchBar window] makeFirstResponder:searchBar];
  }
}

#pragma mark IBAction methods

//-------------------------------------------------------------------
// modeChanged:
// Sets a flag so we know topic window has been edited. 
//
// "sender" - The edited object
//-------------------------------------------------------------------
- (IBAction)modeChanged:(id)sender
{
  modeChanged = TRUE;
}

//-------------------------------------------------------------------
// endTopicWindow:
// Closes the topic window and change channelmode to conform to changes made. 
//
// "sender" - The "Save" or "Cancel" button
//-------------------------------------------------------------------
- (IBAction)endTopicWindow:(id)sender
{
  /* Check if changes has been made */
  if ([[sender title] isEqual:@"Save"])
  {
    // This doesn't require Ops at all
    useFloater = ([floaterCheckBox state] == NSOnState);

    // This only requires Ops if +t, otherwise all is well.
    if ((ownnick->op || ([onlyOpsCanChangeTopicCheckBox state] == NSOffState)) &&
        ([[topicEditableTextField stringValue] isEqual:[topicTextField stringValue]] == FALSE)) 
    {
      NSString *cmd = [NSString stringWithFormat:@"/topic %@", [topicEditableTextField stringValue]];
      const char *tmp = [cmd UTF8String];
      signal_emit("send command", 3, tmp, windowRec->active_server, windowRec->active);
    }
    
    /* do channel silence */
    NSString *squelchTag = [NSString stringWithFormat:@"%@ - %@", [NSString stringWithUTF8String:channel->server->tag], name];
    if ([silenceCheckBox state] || ([[[NSUserDefaults standardUserDefaults] valueForKey:@"eventSilences"] valueForKey:squelchTag]))
    {
      NSDictionary *silences = [[[[NSUserDefaults standardUserDefaults] valueForKey:@"eventSilences"] mutableCopy] autorelease];
      [silences setValue:[NSNumber numberWithBool:[silenceCheckBox state]] forKey:squelchTag];
      [[NSUserDefaults standardUserDefaults] setValue:silences forKey:@"eventSilences"];
    }
    
    if (ownnick->op)
    {
      /* mode-parser */
      if (modeChanged) {
        NSMutableString *removeMode = [[NSMutableString alloc] initWithFormat:@"/mode %@ -", name];
        NSMutableString *addMode = [[NSMutableString alloc] initWithString:@"+"];
        
        /* invite */
        if ([inviteCheckBox state] == NSOnState)
          [addMode appendString:@"i"];
        else
          [removeMode appendString:@"i"];
        
        /* moderated */
        if ([moderatedCheckBox state] == NSOnState)
          [addMode appendString:@"m"];
        else
          [removeMode appendString:@"m"];
        
        /* private */
        if ([privateCheckBox state] == NSOnState)
          [addMode appendString:@"p"];
        else
          [removeMode appendString:@"p"];
        
        /* secret */
        if ([secretCheckBox state] == NSOnState)
          [addMode appendString:@"s"];
        else
          [removeMode appendString:@"s"];
        
        /* no external messages */
        if ([noExternalMessagesCheckBox state] == NSOnState)
          [addMode appendString:@"n"];
        else
          [removeMode appendString:@"n"];
        
        /* only ops can change topic */
        if ([onlyOpsCanChangeTopicCheckBox state] == NSOnState)
          [addMode appendString:@"t"];
        else
          [removeMode appendString:@"t"];
        
        /* limit */
        if ([maxUsersTextField intValue] != 0)
          [addMode appendFormat:@"l %d ", [maxUsersTextField intValue]];
        else
          [removeMode appendString:@"l"];
        
        /* key (special treatment) */
        if ([[keyTextField stringValue] isEqual:@""] && ([mode rangeOfString:@"k"].location != NSNotFound))
          [removeMode appendString:@"k"];
        else if (![[keyTextField stringValue] isEqual:key]) {
          if ([mode rangeOfString:@"k"].location != NSNotFound) {
            /* Remove old key */
            NSString *removeKey = [NSString stringWithFormat:@"/mode %@ -k", name];
            const char *tmp = [removeKey UTF8String];
            signal_emit("send command", 3, tmp, windowRec->active_server, windowRec->active);
          }
          [addMode appendFormat:@"+k %@", [keyTextField stringValue]];
        }
        
        [removeMode appendString:addMode];

        const char *tmp2 = [removeMode UTF8String];
        signal_emit("send command", 3, tmp2, windowRec->active_server, windowRec->active);
        [addMode release];
        [removeMode release];
        modeChanged = FALSE;
      }
    }
  }
  
  /* Remove sheet */
  [topicWindow orderOut:sender];
  [NSApp endSheet:topicWindow returnCode:1];
}


//-------------------------------------------------------------------
// endReasonWindow
// Closes the reason window and performs action with entered reason. 
//
// "sender" - The reason text field
//-------------------------------------------------------------------
- (IBAction)endReasonWindow:(id)sender
{
  [commandWithReason appendString:[sender stringValue]];
  const char *tmp = [commandWithReason UTF8String];
  signal_emit("send command", 3, tmp, windowRec->active_server, windowRec->active);
  [commandWithReason release];
        
  /* Remove sheet */
  [reasonWindow orderOut:sender];
  [NSApp endSheet:reasonWindow returnCode:1];
  [sender setStringValue:@""];
}


//-------------------------------------------------------------------
// nickViewMenuClicked:
// Performes the apropriate action for the context menu item selected. 
//
// "sender" - The context menu item
//-------------------------------------------------------------------
#define EMITMULTI(command)  signal_emit("send command", 3, [[NSString stringWithFormat:command, [coalesedNicks componentsJoinedByString:@" "]] cStringUsingEncoding:NSUTF8StringEncoding], windowRec->active_server, windowRec->active)
#define EMITSINGLE(command) { \
  NSEnumerator *nicksEnum = [coalesedNicks objectEnumerator]; \
  while (nick = [nicksEnum nextObject]) \
  { \
    signal_emit("send command", 3, [[NSString stringWithFormat:command, nick] cStringUsingEncoding:NSUTF8StringEncoding], windowRec->active_server, windowRec->active); \
  } \
}

- (IBAction)nickViewMenuClicked:(id)sender
{
  NSIndexSet *indexSet = [nickTableView selectedRowIndexes];
  NSInteger row = [indexSet firstIndex];
  
  NSMutableArray *coalesedNicks = [NSMutableArray array];
  
  // some commands can be coalesed, so get all the nicks first
  while (row != NSNotFound)
  {
    char *nickStr = ((NICK_REC*)[[nicks objectAtIndex:row] pointerValue])->nick;
    NSString *nick = [NSString stringWithUTF8String:nickStr];
    
    [coalesedNicks addObject:nick];
    row = [indexSet indexGreaterThanIndex:row];
  }
  
  NSString *nick;
  NSString *command;
  NSString *host;
    
  switch ([sender tag]) {
    case Query:
      EMITSINGLE(@"/query %@");
      break;
    case Whois:
      EMITSINGLE(@"/whois %@");
      break;
    case Who:
      EMITSINGLE(@"/who %@");
      break;
    /* Control */
    case Ignore:
      /* todo */
      return;
    case Op:
      EMITMULTI(@"/op %@");
      break;
    case Deop:
      EMITMULTI(@"/deop %@");
      break;
    case Voice:
      EMITMULTI(@"/voice %@");
      break;
    case Devoice:
      EMITMULTI(@"/devoice %@");
      break;
    case Kick:
      commandWithReason = [[NSMutableString alloc] initWithFormat:@"/kick %@ ", [coalesedNicks objectAtIndex:0]];
      [NSApp beginSheet:reasonWindow modalForWindow:[wholeView window] modalDelegate:nil didEndSelector:nil contextInfo:nil];
      return;
    case Ban:
      EMITMULTI(@"/ban %@");
      break;
    case KickBan:
      commandWithReason = [[NSMutableString alloc] initWithFormat:@"/kickban %@ ", [coalesedNicks objectAtIndex:0]];
      [NSApp beginSheet:reasonWindow modalForWindow:[wholeView window] modalDelegate:nil didEndSelector:nil contextInfo:nil];
      return;
    /* CTCP */
    case Ping:
      EMITSINGLE(@"/ping %@");
      break;
    case Finger:
      EMITSINGLE(@"/ctcp %@ finger");
      break;
    case Version:
      EMITSINGLE(@"/ctcp %@ version");
      break;
    case Time:
      EMITSINGLE(@"/ctcp %@ time");
      break;
    case Userinfo:
      EMITSINGLE(@"/ctcp %@ userinfo");
      break;
    case Clientinfo:
      EMITSINGLE(@"/ctcp %@ clientinfo");
      break;
      /* DCC */
    case Send:
      /* todo */
      return;
    case Chat:
      /* todo */
      return;
    case List:
      EMITSINGLE(@"/msg %@ xdcc list");
      break;
    case CopyIP:
      host = [NSString stringWithUTF8String:((NICK_REC*)[[nicks objectAtIndex:row] pointerValue])->host];
      NSArray *tmp = [host componentsSeparatedByString:@"@"];
      
      if ([tmp count] < 2) {
        command = [NSString stringWithFormat:@"/echo Error: Couldn't copy IP address!"];
        EMITSINGLE(command);
      } else {
        [[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
        [[NSPasteboard generalPasteboard] setString:[tmp lastObject] forType:NSStringPboardType];
        return;
      }
        break;
    default:
      NSLog(@"Error: Unknown menu item.");
      return;
  }
}

//-------------------------------------------------------------------
// mainTextViewMenuClicked:
// Not yet implemented 
//
// "sender" - A menu item
//-------------------------------------------------------------------
- (IBAction)mainTextViewMenuClicked:(id)sender
{
  NSLog(@"%@", [sender title]);
}


//-------------------------------------------------------------------
// raiseTopicWindow:
// Brings up the topic window. 
//
// "sender" - The "Edit channel" button
//-------------------------------------------------------------------
- (IBAction)raiseTopicWindow:(id)sender
{
  /* mode-parser */
  NSString *tmp = [[mode componentsSeparatedByString:@" "] objectAtIndex:0]; // Don't include the key
  [inviteCheckBox setState:([tmp rangeOfString:@"i"].location == NSNotFound) ? NSOffState : NSOnState];
  [moderatedCheckBox setState:([tmp rangeOfString:@"m"].location == NSNotFound) ? NSOffState : NSOnState];
  [privateCheckBox setState:([tmp rangeOfString:@"p"].location == NSNotFound) ? NSOffState : NSOnState];
  [secretCheckBox setState:([tmp rangeOfString:@"s"].location == NSNotFound) ? NSOffState : NSOnState];
  [noExternalMessagesCheckBox setState:([tmp rangeOfString:@"n"].location == NSNotFound) ? NSOffState : NSOnState];
  [onlyOpsCanChangeTopicCheckBox setState:([tmp rangeOfString:@"t"].location == NSNotFound) ? NSOffState : NSOnState];
  [maxUsersTextField setIntValue:limit];
  [keyTextField setStringValue:key ? key : @""];
  
  /* If op, allow editing, else disallow */
  if (ownnick->op) {
    [topicEditableTextField setEditable:TRUE];
    [inviteCheckBox setEnabled:TRUE];
    [moderatedCheckBox setEnabled:TRUE];
    [privateCheckBox setEnabled:TRUE];
    [secretCheckBox setEnabled:TRUE];
    [noExternalMessagesCheckBox setEnabled:TRUE];
    [onlyOpsCanChangeTopicCheckBox setEnabled:TRUE];
    [maxUsersTextField setEnabled:TRUE];
    [keyTextField setEnabled:TRUE];
    //[saveButton setEnabled:TRUE];
  }
  else {
    [topicEditableTextField setEditable:![onlyOpsCanChangeTopicCheckBox state]];
    [inviteCheckBox setEnabled:FALSE];
    [moderatedCheckBox setEnabled:FALSE];
    [privateCheckBox setEnabled:FALSE];
    [secretCheckBox setEnabled:FALSE];
    [noExternalMessagesCheckBox setEnabled:FALSE];
    [onlyOpsCanChangeTopicCheckBox setEnabled:FALSE];
    [maxUsersTextField setEnabled:FALSE];
    [keyTextField setEnabled:FALSE];
    //[saveButton setEnabled:FALSE];
  }
  
  /* Make sheet reflect current channel settings */
  [topicEditableTextField setStringValue:[topicTextField stringValue] ? [topicTextField stringValue] : @""];
  [topicByTextField setStringValue:topic_by ? [[topic_by componentsSeparatedByString:@"!"] objectAtIndex:0]: @""];
  
  NSString *topicTime;
  if (topic_time == 0)
  {
    topicTime = @"";
  }
  else
  {
    topicTime = [NSString stringWithCString:ctime(&topic_time) encoding:NSASCIIStringEncoding];
  }
  [topicTimeTextField setStringValue:topicTime];
  [maxUsersTextField setIntValue:limit];
  [floaterCheckBox setState:(useFloater ? NSOnState : NSOffState)];
  
  /* Bring up sheet */
  [NSApp beginSheet:topicWindow modalForWindow:[wholeView window] modalDelegate:nil didEndSelector:nil contextInfo:nil];
}


//-------------------------------------------------------------------
// nickListRowDoubleClicked:
// Starts a query with the nick that was double-clicked
//
// "sender" - The table view containing the row
//-------------------------------------------------------------------
- (void)nickListRowDoubleClicked:(id)sender
{
  long row = [nickTableView selectedRow];
  if (row > -1)
  {
    NSString *command = [NSString stringWithFormat:@"/query %s", ((NICK_REC *)[[nicks objectAtIndex:row] pointerValue])->nick];
    signal_emit("send command", 3, [command cStringUsingEncoding:NSASCIIStringEncoding], windowRec->active_server, windowRec->active);
  }
}

- (IBAction)makeChannelKey:(id)sender
{
  NSString *cmd = [NSString stringWithFormat:@"/window %d", windowRec->refnum];
  signal_emit("send command", 3, [cmd cStringUsingEncoding:NSASCIIStringEncoding], windowRec->active_server, windowRec->active);
}

- (BOOL)isScrolledToBottom
{
  return ([scrollViewHelper currentScrollPosition] == 1.0);
}

- (void)forceScrollToBottom
{
  [scrollViewHelper restoreScrollPosition:1.0];
}

#pragma mark Indirect receivers of irssi signals
//-------------------------------------------------------------------
// setTopic:setBy:atTime:
// Updates the topic text field. 
//
// "newTopic" - The new topic in the channel
// "setBy" - The nick who set the topic
// "time" - The time the change was made
//-------------------------------------------------------------------
- (void)setTopic:(char *)newTopic setBy:(char *)setter atTime:(time_t)time
{
  if (!newTopic)
    newTopic = "";
  if (!setter)
    setter = "";
  
  
  [topic_by release];
  topic_by = [[NSString alloc] initWithCString:setter encoding:NSUTF8StringEncoding];
  topic_time = time;

  NSAttributedString *topic = [self parseTopic:newTopic];
  [topicTextField setAttributedStringValue:topic];
  [topicTextField setToolTip:[topic string]];
}

//-------------------------------------------------------------------
// clearNickView
// Clears the nick view. 
//-------------------------------------------------------------------
- (void)clearNickView
{
  [nicks removeAllObjects];
  [nickTableView removeAllToolTips]; 
  [nickTableView reloadData];
}


//-------------------------------------------------------------------
// queryCreated
// Initializes a query. 
//
// "rec" - A QUERY_REC with info concerning the query
//-------------------------------------------------------------------
- (void)queryCreated:(QUERY_REC *)rec
{
  //printf("Hi\n");
}


//-------------------------------------------------------------------
// channelJoined:
// Initializes a channel. 
//
// "rec" - The channel that was joined
//-------------------------------------------------------------------
- (void)channelJoined:(CHANNEL_REC *)rec
{
  if (rec == NULL)
    return;
  
  channel = rec;
  isChannel = TRUE;
  
  /* Make nicklist into a NSMutableArray and sort by nickname */
  nicks = [[NSMutableArray alloc] initWithCapacity:g_hash_table_size(rec->nicks)];
  g_hash_table_foreach(rec->nicks, (GHFunc)personFromNickRec, nicks);
  [self sortNicks];
  
  /* Make NSString objects from (char *) */
  name = rec->name ? [[NSString stringWithUTF8String:rec->name] retain] : @"";
  if (topic_by) {
    [topic_by release];
    topic_by = nil;
  }

  topic_by = [[NSString alloc] initWithCString:(rec->topic_by ? rec->topic_by : "") encoding:NSUTF8StringEncoding];
  mode = [[NSString alloc] initWithCString:(rec->mode ? rec->mode : "") encoding:NSUTF8StringEncoding];
  key = [[NSString alloc] initWithCString:(rec->key ? rec->key : "") encoding:NSUTF8StringEncoding];
  
  /* Copy rest of the values */
  topic_time = rec->topic_time;
  ownnick = rec->ownnick;
  limit = rec->limit;
  no_modes = (BOOL)rec->no_modes;
  chanop = (BOOL)rec->chanop;
  names_got = (BOOL)rec->names_got;
  wholist = (BOOL)rec->wholist;
  synced = (BOOL)rec->synced;
  joined = (BOOL)rec->joined;
  justLeft = (BOOL)rec->left;
  kicked = (BOOL)rec->kicked;
  session_rejoin = (BOOL)rec->session_rejoin;
  destroying = (BOOL)rec->destroying;
  
  /* Go and see if we're supposed to silence this channel */
  NSString *squelchTag = [NSString stringWithFormat:@"%@ - %@", [NSString stringWithUTF8String:channel->server->tag], name];
  [silenceCheckBox setState:[[[[NSUserDefaults standardUserDefaults] valueForKey:@"eventSilences"] valueForKey:squelchTag] boolValue]];  
  
  /* Update GUI */
  [tabViewItem setLabel:name];
  [nickTableView removeAllToolTips];
  [nickTableView reloadData];
  [editChannelButton setEnabled:TRUE];
  
  /* Only create split view on first join, not on reconnects */
  if (splitView) {
    [splitView setNeedsDisplay:TRUE];
    return;
  }
  
  [mainTextScrollView retain];
  [nickTableScrollView retain];
  
  [mainTextScrollView removeFromSuperview];
  [nickTableScrollView removeFromSuperview];
  
  [nickTableScrollView setHidden:FALSE];
  NSRect frame = NSUnionRect([mainTextScrollView frame],[nickTableScrollView frame]);
  
  splitView = [[MISplitView alloc] initWithFrame:frame];
  [splitView setVertical:TRUE];
  [splitView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
  [splitView setDelegate:self];
  [splitView addSubview:mainTextScrollView];
  [splitView addSubview:nickTableScrollView];
  [splitView restoreLayoutUsingName:@"MainNickSplit"];
  
  [mainTextScrollView release];
  [nickTableScrollView release];

  frame.size.width -= [nickTableScrollView frame].size.width; 
  [mainTextScrollView setFrame:frame];
  
  [wholeView addSubview:splitView];
  [splitView setNeedsDisplay:TRUE];
  
  if (![[NSUserDefaults standardUserDefaults] boolForKey:@"showNicklist"])
  {
    [self setNicklistHidden:YES];
  }
}

- (void)setNicklistHidden:(BOOL)flag
{
  // Don't have a nick list otherwise.
  if ([self isChannel])
  {
    if (![nickTableScrollView isHidden] && flag)
    {
      // We're showing atm and we want to be hidden, go with that.
      [nickTableScrollView retain];
      [nickTableScrollView removeFromSuperview];
      
      [nickTableScrollView setHidden:YES];
      [wholeView addSubview:nickTableScrollView];
      
      [nickTableScrollView release];
    }
    else if ([nickTableScrollView isHidden] && !flag)
    {
      [nickTableScrollView retain];
      [nickTableScrollView removeFromSuperview];
      
      [nickTableScrollView setHidden:NO];
      [splitView addSubview:nickTableScrollView];
      [splitView restoreLayoutUsingName:@"MainNickSplit"];
      
      [nickTableScrollView release];
    }
  }
}

//-------------------------------------------------------------------
// changeServerOpForNickRec:
// Changes the serverop status for a nick in the nick list. 
//
// "rec" - The nick
//-------------------------------------------------------------------
- (void)changeServerOpForNickRec:(NICK_REC *)rec
{
  /* First undo modechange so we can find him */
  rec->serverop = (rec->serverop) ? FALSE : TRUE;
  
  @synchronized(nicks) {
    
    int i = [self findNick:rec];
    if(i == -1) {
      NSLog(@"[changeServerOpForNickRec] Error: \"%s\" not found!\n", rec->nick);
      return;
    }
    
    [nicks removeObjectAtIndex:i];
    
    /* Redo modechange */
    rec->serverop = (rec->serverop) ? FALSE : TRUE;
    
    /* Insert into new position */
    i = [self findInsertionPositionForNick:rec];
    
    [nicks insertObject:[NSValue valueWithPointer:rec] atIndex:i];
  }
  
  [nickTableView removeAllToolTips]; 
  [nickTableView reloadData];
}


//-------------------------------------------------------------------
// setMode:type:forNickRec:
// Updates a nicks apperance in nick view when mode is changed. 
//
// "mode" - The mode (@,+)
// "type" - If the mode is added (+) or removed (-)
// "nick" - The affected nick
//-------------------------------------------------------------------
- (void)setMode:(char *)mode1 type:(char *)type forNickRec:(NICK_REC *)nick
{
  int index;
  
  /* First undo modechange so we can find him */
  if (*mode1 == '@')
    nick->op = (*type == '-') ? TRUE : FALSE;
  else if (*mode1 == '+')
    nick->voice = (*type == '-') ? TRUE : FALSE;
  else if (*mode1 == '%')
    nick->halfop = (*type == '-') ? TRUE : FALSE;
  else
    NSLog(@"Nick \"%@\" received unknown mode!", [NSString stringWithUTF8String:nick->nick]);
  
  @synchronized(nicks) {

    index = [self findNick:nick];
    if (index < 0) {
      NSLog(@"[ChannelController setMode] Error: Couldn't find nick %@ in thread %p", [NSString stringWithUTF8String:nick->nick], [NSThread currentThread]);
      return;
    }
    
    [nicks removeObjectAtIndex:index];
    
    /* Redo modechange so we can insert him in new position */
    if (*mode1 == '@')
      nick->op = (*type == '+') ? TRUE : FALSE;
    else if (*mode1 == '+')
      nick->voice = (*type == '+') ? TRUE : FALSE;
    else if (*mode1 == '%')
      nick->halfop = (*type == '+') ? TRUE : FALSE;
    else
      NSLog(@"Nick \"%@\" received unknown mode!", [NSString stringWithUTF8String:nick->nick]);

    
    index = [self findInsertionPositionForNick:nick];
    [nicks insertObject:[NSValue valueWithPointer:nick] atIndex:index];
  }
  
  [nickTableView removeAllToolTips]; 
  [nickTableView reloadData]; 
}


//-------------------------------------------------------------------
// addNickRec:
// Adds a nick to the channel list. 
//
// "nick" - The nick to be added
//-------------------------------------------------------------------
- (void)addNickRec:(NICK_REC *)nick
{
  @synchronized(nicks) {
    int i = [self findInsertionPositionForNick:nick];
    [nicks insertObject:[NSValue valueWithPointer:nick] atIndex:i];
  }
  [nickTableView removeAllToolTips]; 
  [nickTableView reloadData];
}


//-------------------------------------------------------------------
// removeNickRec:
// Remove a nick from the nick list. 
//
// "nick" - The nick to be removed
//-------------------------------------------------------------------
- (void)removeNickRec:(NICK_REC *)nick
{
  @synchronized(nicks) {
    int i = [self findNick:nick];
    if (i == -1) {
      NSLog(@"Error: nick %@ not found in thread %p!\n", [NSString stringWithUTF8String:nick->nick], [NSThread currentThread]);
      return;
    }
    [nicks removeObjectAtIndex:i];
  }
  
  [nickTableView removeAllToolTips]; 
  [nickTableView reloadData];
}


//-------------------------------------------------------------------
// changeNickForNickRec:fromNick:
// Changes the 'nick' of a nick. 
//
// "oldNick" - The old 'nick'
// "rec" - The new nick
//-------------------------------------------------------------------
- (void)changeNickForNickRec:(NICK_REC *)rec fromNick:(char *)oldNick
{
  /* First undo nickchange so we can find him */
  char *newNick = rec->nick;
  rec->nick = oldNick;
  
  @synchronized(nicks) {
    int i = [self findNick:rec];
    if(i == -1) {
      NSLog(@"Error: nick %s (new: %s) not found!\n", oldNick, newNick);
      return;
    }
    
    /* Remove from from nicks-array */
    [nicks removeObjectAtIndex:i];
  
    /* Redo nickchange */
    rec->nick = newNick;
    
    /* Insert into new position */
    i = [self findInsertionPositionForNick:rec];
    
    [nicks insertObject:[NSValue valueWithPointer:rec] atIndex:i];
  }
  
  [nickTableView removeAllToolTips];
  [nickTableView reloadData];
}


//-------------------------------------------------------------------
// channelModeChanged:setBy:
// Chages the mode of the channel
//
// "rec" - The channel that changed
// "setter" - The nick that set the mode
//-------------------------------------------------------------------
- (void)channelModeChanged:(CHANNEL_REC *)rec setBy:(char *)setter
{
  [mode release];
  [key release];
  mode = [[NSString alloc] initWithCString:(rec->mode ? rec->mode : "") encoding:NSUTF8StringEncoding];
  key = [[NSString alloc] initWithCString:(rec->key ? rec->key : "") encoding:NSUTF8StringEncoding];
  limit = rec->limit;
}

#pragma mark - Text Updates

/* From gui-printtext.c */
int mirc_colors[] = { 15, 0, 1, 2, 12, 4, 5, 6, 14, 10, 3, 11, 9, 13, 8, 7 };

- (void)beginTextUpdates
{
  // Caught text updates happening during window display after we've already saved
  // the window state. So this is to prevent an interior update overwriting the scroll
  // state.
  if (!insideTextUpdates)
  {
    // Yep, we're inside text updates now
    insideTextUpdates = YES;
    
    // Flush out the layout before we start updating, so we can be sure where the scroller is.
    [[mainTextView layoutManager] ensureLayoutForTextContainer:[mainTextView textContainer]];
    
    // Save our current state, then when updates are finished we'll restore the state.
    savedScrollPoint = [scrollViewHelper currentScrollPosition];
    if ((savedScrollPoint > 0.0) && (savedScrollPoint < 1.0))
    {
      savedScrollPoint = [scrollViewHelper currentDistanceFromTop];
    }
  }
}

- (void)endTextUpdates
{
  // ... and force the layout of new stuff so we can see the effects.
  [[mainTextView layoutManager] ensureLayoutForTextContainer:[mainTextView textContainer]];
  
  // savedScrollPoint which is > 1.0 is an absolute distance-from-top.
  if (savedScrollPoint > 1.0)
  {
    [scrollViewHelper restoreDistanceFromTop:savedScrollPoint];
  }
  else
  {
    [scrollViewHelper restoreScrollPosition:savedScrollPoint];
  }
  
  // reset update state, all on mainthread, shouldn't need to be atomic
  insideTextUpdates = NO;
}

//-------------------------------------------------------------------
// printText:forground:background:flags:
// Adds a text section to the linebuffer. Called for each new
// text-color-section. Currenlty ignores flags <-- FIX =)
//
// "text" - The text to print
// "fg" - The foreground color
// "bg" - The background color
// "flags" - Flags
//-------------------------------------------------------------------
- (void)printText:(char *)text forground:(int)fg background:(int)bg flags:(int)flags
{
  /* Convert the incoming string to NSString */
  NSString *decodedString = (NSString *)CFStringCreateWithCStringNoCopy(NULL, text, kCFStringEncodingUTF8, kCFAllocatorNull);
  [line appendString:decodedString foreground:fg background:bg flags:flags attributes:textAttributes];
  
  [decodedString release];
}


//-------------------------------------------------------------------
// finishLine
// Called after a series of printText when the current line should be
// put out to screen.
//-------------------------------------------------------------------
- (void)finishLine
{
  [line detectURLs:[ColorSet channelLinkColour]];
  [textStorage appendAttributedString:line];
  
  /* User notifications */
  if (currentDataLevel > 2 && [self isChannel])
  {
    NSString *str = [[line string] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObject:str forKey:@"Description"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"IRSSI_ROOM_HIGHLIGHT" object:self userInfo:info];
  }
  
  /* I used to scroll the view here, however, now the view should scroll itself
     to the bottom of the clipview for us, as long as the user hasn't scrolled up. */
  
  /* Reset line */
  [line replaceCharactersInRange:NSMakeRange(0, [line length]) withString:@"\n"];
}

#pragma mark Public methods

//-------------------------------------------------------------------
// clearTextView:
// Clears the text view
//-------------------------------------------------------------------
- (void)clearTextView
{
  [textStorage deleteCharactersInRange:NSMakeRange(0, [textStorage length])];
}

//-------------------------------------------------------------------
// setFont:
// Set font in main text view
//
// "font" - The font to use
//-------------------------------------------------------------------
- (void)setFont:(NSFont *)font
{
  [channelFont release];
  channelFont = [font retain];
  
  NSRange range = {0, [textStorage length]};

  [textAttributes setObject:font forKey:NSFontAttributeName];
  [textStorage addAttribute:NSFontAttributeName value:font range:range];
  [topicTextField setFont:font];
}

- (void)setNicklistFont:(NSFont*)font
{
  [font retain];
  [nickListFont release];
  nickListFont = font;
  
  // Nick list uses the current font anyway but it'll need poking to reload
  NSSize textSize = [@"" sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:nickListFont, NSFontAttributeName, nil]];
  [nickTableView setRowHeight:textSize.height];
  [nickTableView reloadData];  
}

//-------------------------------------------------------------------
// validateMenuItem:
// Controls if context-menu item should be enabled/disabled
//
// "menuItem" - The menu item to be validated
//
// Returns: TRUE if enabled, FALSE if not
//-------------------------------------------------------------------
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
  /* Control sub-menu are only for ops */
  if ([[[menuItem menu] title] isEqual:@"Control"] && !ownnick->op)
    return FALSE;
  else
    return TRUE;
}

//-------------------------------------------------------------------
// setTabViewItem:colors:appController:
// Get reference to various items. TODO: Fix this ugly mess :P 
//
// "newTabViewItem" - The tab view associated with the channel
// "colors" - The colors used
// "ref" - The app controller
//-------------------------------------------------------------------
- (void)setTabViewItem:(NSTabViewItem *)newTabViewItem colors:(ColorSet *)colors appController:(AppController *)ref;
{
  appController = ref;
  tabViewItem = newTabViewItem;

  [mainTextView setBackgroundColor:[ColorSet channelBackgroundColor]];
  [[mainTextView enclosingScrollView] setBackgroundColor:[ColorSet channelBackgroundColor]];
  [nickTableView setBackgroundColor:[ColorSet nickListBackgroundColor]];
  
  /* Set up fonts and attributes */
  NSFont *chanFont = [NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] valueForKey:@"channelFont"]];
  NSFont *nickFont = [NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] valueForKey:@"nickListFont"]];
  
  [self setFont:chanFont];
  [self setNicklistFont:nickFont];
  
  textAttributes = [[NSMutableDictionary alloc] init];
  topicAttributes = [[NSMutableDictionary alloc] init];
  nickAttributes = [[NSMutableDictionary alloc] init];
  
  [textAttributes setObject:channelFont forKey:NSFontAttributeName];
  [topicTextField setFont:channelFont];
  [topicEditableTextField setFont:channelFont];
  [maxUsersTextField setFont:channelFont];
  [keyTextField setFont:channelFont];
  
  NSMutableParagraphStyle *style = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
  [style setAlignment:NSCenterTextAlignment];
  [topicAttributes setObject:style forKey:NSParagraphStyleAttributeName];
  [topicAttributes setObject:[NSFont fontWithName:@"Monaco" size:9.0] forKey:NSFontAttributeName];
  [topicTextField setStringValue:@"(no topic)"];
}


#pragma mark Delegate & notification receiver methods
//-------------------------------------------------------------------
// numberOfRowsInTableView:
// NSTableView delegate method. Returns the number of nicks. 
//
// "aTableView" - The table view
//
// Returns: The number of nicks
//-------------------------------------------------------------------
- (int) numberOfRowsInTableView:(NSTableView *)aTableView
{
  return (int)[nicks count];
}


//-------------------------------------------------------------------
// tableView:objectValueForTableColumn:row:
// NSTableView delegate method. Returns a nick at a specific index. 
//
// "aTableView" - The table view
// "aTableColumn" - The column
// "rowIndex" - The row
//
// Returns: A string representation of the nick at index rowIndex.
//-------------------------------------------------------------------
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
  if (rowIndex >= [nicks count]) {
    NSLog(@"rowIndex >= [nicks count] !!!");
    return @"";
  }
  
  NICK_REC *nick = (NICK_REC *)[[nicks objectAtIndex:rowIndex] pointerValue];
  NSColor *color;
  
  if (nick->serverop)
  {
    color = [ColorSet nickListForegroundServerOpColor];
  }
  else if (nick->op)
  {
    color = [ColorSet nickListForegroundOpColor];
  }
  else if (nick->halfop)
  {
    color = [ColorSet nickListForegroundHalfOpColor];
  }
  else if (nick->voice)
  {
    color = [ColorSet nickListForegroundVoiceColor];
  }
  else
  {
    color = [ColorSet nickListForegroundNormalColor];
  }
  
  [nickAttributes setObject:color forKey:NSForegroundColorAttributeName];
  [nickAttributes setObject:nickListFont forKey:NSFontAttributeName];
  return [[[NSAttributedString alloc] initWithString:[NSString stringWithUTF8String:nick->nick] attributes:nickAttributes] autorelease];
}


//-------------------------------------------------------------------
// tableView:willDisplayCell:forTableColumn:tableColumn:rowIndex:
// Adds a tooltip rect on the cell to be diplayed. 
//
// "tableView" - The nick table view
// "cell" - The cell that will be displayed
// "tableColum" - Ignored
// "rowIndex" - The row that contains the cell
//-------------------------------------------------------------------
- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex {
#if 0
  [nickTableView addToolTipRect:[nickTableView frameOfCellAtColumn:0 row:rowIndex] 
              owner:self userData:(void *)rowIndex];
#endif
}


//-------------------------------------------------------------------
// view:stringForToolTip:point:userData:
// Returns the string to be displayed in a tooltip for a nick in the
// userlist.
//-------------------------------------------------------------------
- (NSString *)view:(NSView *)view stringForToolTip:(NSToolTipTag)tag point:(NSPoint)point userData:(void *)userData
{
  NICK_REC *nick = (NICK_REC *)[[nicks objectAtIndex:(NSInteger)userData] pointerValue];
    
  if (!nick || !nick->nick) {
    [appController presentUnexpectedEvent:@"Can't create tooltip when nick is NULL!"];
    return @"";
  }
  
  if (!nick->realname || !nick->host) {
    /* If we don't have all info, do a who lookup */
    char tmp[strlen(nick->nick) + 5];
    sprintf(tmp, "/who %s", nick->nick);
    signal_emit("send command", 3, tmp, windowRec->active_server, windowRec->active);
  }
  
  return [NSString stringWithFormat:@"%@ -- [%@]\n%@", 
          [NSString stringWithUTF8String:nick->nick], 
          nick->realname ? [NSString stringWithUTF8String:nick->realname] : @"real name not received", 
          nick->host ? [NSString stringWithUTF8String:nick->host] : @"host name not received"];
}

- (void)checkUserDefaults:(NSNotification*)notification
{
  // Re-check user defaults that we care about.
  BOOL shouldAntialias = [[NSUserDefaults standardUserDefaults] boolForKey:@"antiAliasFonts"];
  [mainTextView setShouldAntialias:shouldAntialias];
  [topicTextField setShouldAntialias:shouldAntialias];
}

//-------------------------------------------------------------------
// channelColorChanged:
// Updates the colors in the main channel text area.
//
// "note" - Ignored
//-------------------------------------------------------------------
- (void)channelColorChanged:(NSNotification *)note
{
//  [defaultTextColor release];
//  defaultTextColor = [[colorSet channelFGDefaultColor] retain];
  [mainTextView setBackgroundColor:[ColorSet channelBackgroundColor]];
  [[mainTextView enclosingScrollView] setBackgroundColor:[ColorSet channelBackgroundColor]];
  [mainTextView setNeedsDisplay:TRUE];
}


//-------------------------------------------------------------------
// nickListColorChanged
// Updates the colors in the nick list. 
//
// "note" - Ignored
//-------------------------------------------------------------------
- (void)nickListColorChanged:(NSNotification *)note
{
  [nickTableView setBackgroundColor:[ColorSet nickListBackgroundColor]];
  [nickTableView removeAllToolTips]; 
  [nickTableView reloadData];
}

// Force a splitView resize save on resize
- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification
{
  [splitView saveLayoutUsingName:@"MainNickSplit"];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"ChannelControllerSplitViewDidResize" object:self];
}

- (void)channelControllerSplitViewDidResize:(NSNotification*)notification
{
  if ([[notification object] isNotEqualTo:self])
  {
    [splitView restoreLayoutUsingName:@"MainNickSplit"];
  }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  if ([object isEqual:mainTextView])
  {
    /* deal with externally influenced bounds changes */
    if ([[change objectForKey:@"notificationIsPrior"] boolValue])
    {
      [self beginTextUpdates];
    }
    else
    {
      [self endTextUpdates];
    }
  }
}

#pragma mark [De]Initializers
//-------------------------------------------------------------------
// awakeFromNib
// Initializer 
//-------------------------------------------------------------------
- (void)awakeFromNib
{
  /* Register for color notifications */
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self selector:@selector(channelColorChanged:) name:@"channelColorChanged" object:nil];
  [nc addObserver:self selector:@selector(nickListColorChanged:) name:@"nickListColorChanged" object:nil];
  [nc addObserver:self selector:@selector(channelControllerSplitViewDidResize:) name:@"ChannelControllerSplitViewDidResize" object:nil];
  [nc addObserver:self selector:@selector(checkUserDefaults:) name:NSUserDefaultsDidChangeNotification object:nil];
  
  /* Force the text view to post frame changes */
  [mainTextView addObserver:self forKeyPath:@"frame" options:(NSKeyValueObservingOptionPrior|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew) context:nil];
  
  /* Create the helper to control scrolling */
  scrollViewHelper = [[MIScrollViewHelper alloc] initWithScrollView:[mainTextView enclosingScrollView]];
  
  /* Force the important defaults to be checked now */
  [self checkUserDefaults:nil];

  /* Set up context-menus */
  [nickTableView setMenu:nickViewMenu];
  //[mainTextView setMenu:mainTextViewMenu];
  [mainTextView setUsesFontPanel:FALSE];

  /* Other */
  textStorage = [mainTextView textStorage];
  searchRanges = [[NSMutableArray alloc] init];
  
  [nickTableView setTarget:self];
  [nickTableView setDoubleAction:@selector(nickListRowDoubleClicked:)];

  [nickTableScrollView setHidden:TRUE];
  [nickTableScrollView setDrawsBackground:YES];
  NSRect frame = [mainTextScrollView frame];
  frame.size.width += [nickTableScrollView frame].size.width + 8;
  [mainTextScrollView setFrame:frame];
  [mainTextScrollView setNeedsDisplay:TRUE];
  [topicTextField setAllowsEditingTextAttributes:TRUE];
}

//-------------------------------------------------------------------
// initWithWindowRec:
// Designated initializer. 
//
// "rec" - A WINDOW_REC representing a window (tab in this case)
//
// Returns: self
//-------------------------------------------------------------------
- (id)initWithWindowRec:(WINDOW_REC *)rec
{
  [super init];
  if (rec == NULL) {
    NSLog(@"Warning: WINDOW_REC is NULL");
    return self;
  }

  splitView = nil;
  windowRec = rec;
  isChannel = FALSE;
  useFloater = FALSE;
  insideTextUpdates = NO;

  line = [[NSMutableAttributedString alloc] init];
  oldSearchMatchRange = NSMakeRange(0,0);
  searchController = [[MIChannelSearchController alloc] initWithController:self];
  return self;
}


/* Wrapper */
- (id)init {return [self initWithWindowRec:NULL]; }


//-------------------------------------------------------------------
// dealloc
// Deallocates the resources used by this instance
// TODO: Yes this currently leaks memory
//-------------------------------------------------------------------
- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  [searchController release];
  [scrollViewHelper release];
  
  [wholeView release];
  [topicWindow release];
  //[mainTextViewMenu release];
  [nickViewMenu release];
  
  [nicks release];
  [name release];
  [topic_by release];
  [mode release];
  [key release];

  [textAttributes release];
  [topicAttributes release];
  [nickAttributes release];
  [searchRanges release];
  
  [super dealloc];
}

#pragma mark Instance variables

/* If it is an actual irc channel */
- (BOOL)isChannel { return isChannel; }

//-------------------------------------------------------------------
// The nick array
//-------------------------------------------------------------------
- (NSArray *)nicks { return nicks; }

//-------------------------------------------------------------------
// The mode of the channel
//-------------------------------------------------------------------
- (NSString *)mode { return mode; }

//-------------------------------------------------------------------
// The current tab view item.
//-------------------------------------------------------------------
- (NSTabViewItem *)tabViewItem { return tabViewItem; }


//-------------------------------------------------------------------
// The current channel text view. 
//-------------------------------------------------------------------
- (NSTextView *)mainTextView { return mainTextView; }


//-------------------------------------------------------------------
// The WINDOW_REC this tab is representing. 
//-------------------------------------------------------------------
- (WINDOW_REC *)windowRec { return windowRec; }


//-------------------------------------------------------------------
// The view of the tab. 
//-------------------------------------------------------------------
- (NSView *)view { return wholeView; }


//-------------------------------------------------------------------
// Partial command (for changing window)
//-------------------------------------------------------------------
- (NSString *)partialCommand { return partialCommand; }

- (NSRange)partialCommandSelection {
  return partialCommandSelection;
}

- (void)setPartialCommand:(NSString*)cmd
{
  [cmd retain];
  [partialCommand release];
  partialCommand = cmd;
}

- (void)setPartialCommandSelection:(NSRange)range
{
  partialCommandSelection = range;
}

//-------------------------------------------------------------------
// Last event tracker (for Growl mainly)
//-------------------------------------------------------------------

- (int)waitingEvents
{
  return waitingEvents;
}

- (void)setWaitingEvents:(int)count
{
  waitingEvents = count;
}

- (NSString*)lastEventOwner
{
  return lastEventOwner;
}

- (void)setLastEventOwner:(NSString*)owner
{
  [owner retain];
  [lastEventOwner release];
  lastEventOwner = owner;
}

//-------------------------------------------------------------------
// The current data level 
//-------------------------------------------------------------------
#if 0
- (void)setCurrentDataLevel:(int)level { currentDataLevel = level; }
#endif


//-------------------------------------------------------------------
// The current channel topic 
//-------------------------------------------------------------------
- (NSString *)topic { return [topicTextField stringValue]; }


//-------------------------------------------------------------------
// The name of the channel. 
//-------------------------------------------------------------------
- (NSString *)name { return name; }

- (void)setName:(NSString *)newName
{
  if (name == newName)
    return;
  
  [name release];
  name = [newName retain];
  [tabViewItem setLabel:name];
}

#pragma mark Private methods

//-------------------------------------------------------------------
// parseTopic:
// Parses a topic string, looking for mirc colors (currently ignores them) and links
//
// "str" - The topic string
//
// Returns: A string with the resulting attributes
//-------------------------------------------------------------------
- (NSAttributedString *)parseTopic:(char *)str
{
#if 0
  const char *p, *start = NULL;
  char tmp[strlen(str)];
  int fg, bg, len;
  NSAttributedString *partialTopic;
  NSMutableDictionary *topicAttributes = [[NSMutableDictionary alloc] init];
  NSMutableAttributedString *attributedTopic = [[NSMutableAttributedString alloc] init];
  
  for (p = str; *p != '\0'; p++) {
    
    /* Only parse mirc colors on first pass */
    if (*p != 3)
      continue;
    /* Check if this is the end of a color range */
    if (start) {
      len = p - start;
      NSAssert(len >= 0, @"Len is subzero!"); //TODO: remove?
      
      tmp = (char *)malloc(len+1);
      bcopy(start, tmp, len);
      tmp[len] = 0;
      
      
      /* Check foreground color */
      if (fg < 0 || fg > 15)
      {
        [topicAttributes setObject:defaultTextColor forKey:NSForegroundColorAttributeName];
      }
      else
      {
        [topicAttributes setObject:[[ColorSet mircColours] objectAtIndex:[mirc_colors[fg % 16]]] forKey:NSForegroundColorAttributeName];
      }

      /* Check background color */
      if (bg < 0 || bg > 15)
        [topicAttributes removeObjectForKey:NSBackgroundColorAttributeName];
      else
        [topicAttributes setObject:[bg_colors objectAtIndex:[mirc_colors[bg % 16]]] forKey:NSBackgroundColorAttributeName];

      partialTopic = [[NSAttributedString alloc] initWithString:[NSString stringWithUTF8String:tmp] attributes:topicAttributes];
      [attributedTopic appendAttributedString:partialTopic];
      
      free(tmp);
      [partialTopic release];
      
    }
    
    /* get mirc color */
    p++;  
    get_mirc_color(&p, &fg, &bg);
    start = p;
    p--;      
  }
  
  [topicAttributes release];
#endif

  char *stripped = strip_codes(str);
  
  NSMutableAttributedString *attributedTopic = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithUTF8String:stripped] attributes:topicAttributes];
  [attributedTopic detectURLs:[NSColor blueColor]];
  
  free(stripped);
  
  return [attributedTopic autorelease];
}

/* Wrapper - Start recursion */
- (void)sortNicks
{
    // MDB TODO
  /*@synchronized(nicks) {
    [self sortNicksWithLeftBound:0 rightBound:[nicks count] - 1];
  }*/
}

//-------------------------------------------------------------------
// sortNicksWithLeftBound:rightBound:
// Sorts the nicks in the channel based on name (case insensitive) 
// and status (op, voice...). Sorts using quicksort (recursive).
//
// "left" - The left bound
// "right" - The right bound
//-------------------------------------------------------------------
- (void)sortNicksWithLeftBound:(int)left rightBound:(int)right
{
  int i, last;

  /* Check if sorted (base case) */
  if (left >= right)
    return;

  const char *nick_flags = channel->server->get_nick_flags(channel->server);
  [nicks exchangeObjectAtIndex:left withObjectAtIndex:(left + right)/2];
  last = left;
  for (i = left+1; i <= right; i++)
    if (nicklist_compare((NICK_REC *)[[nicks objectAtIndex:i] pointerValue], (NICK_REC *)[[nicks objectAtIndex:left] pointerValue], (void *)nick_flags) < 0)
      [nicks exchangeObjectAtIndex:++last withObjectAtIndex:i];
  [nicks exchangeObjectAtIndex:left withObjectAtIndex:last];

  /* Recursive call */
  [self sortNicksWithLeftBound:left rightBound:last-1];
  [self sortNicksWithLeftBound:last+1 rightBound:right];
}


//-------------------------------------------------------------------
// findNick
// Finds the array-index of an nick. 
//
// "nick" - The nick to be located
//
// Returns: If found, the index of the nick, else -1
//-------------------------------------------------------------------
- (int)findNick:(NICK_REC *)nick
{
  int mid, result, low = 0, high = (int) [nicks count] - 1;

  const char *nick_flags = channel ? channel->server->get_nick_flags(channel->server) : NULL;
  
  while (low <= high) {
    mid = (low + high) / 2;
    result = nicklist_compare((NICK_REC *)[[nicks objectAtIndex:mid] pointerValue], nick, (void *)nick_flags);
    if (result < 0)
      low = mid + 1;
    else if (result > 0)
      high = mid - 1;
    else
      return mid; // Found
  }
  
  /* Not found, try linear search (synchronizing problem?) */
  return [self findNickLinear:nick];
}

//-------------------------------------------------------------------
// findNickLinear
// Finds the array-index of an nick (using linear search). 
//
// "nick" - The nick to be located
//
// Returns: If found, the index of the nick, else -1
//-------------------------------------------------------------------
- (int)findNickLinear:(NICK_REC *)nick
{
  int i;
  const char *nick_flags = channel ? channel->server->get_nick_flags(channel->server) : NULL;

  for (i = 0; i < [nicks count]; i++)
    if (nicklist_compare((NICK_REC *)[[nicks objectAtIndex:i] pointerValue], nick, (void *)nick_flags) == 0)
      return i;
  
  /* Not found */
  for (i = 0; i < [nicks count]; i++)
    NSLog(@"%s", ((NICK_REC *)[[nicks objectAtIndex:i] pointerValue])->nick);

  return -1;
}

//-------------------------------------------------------------------
// findInsertionPositionForNick
// Finds the position a new nick should be inserted into.
// To keep the nicks sorted. 
//
// "nick" - The nick to be inserted
//
// Returns: The position
//-------------------------------------------------------------------
- (int)findInsertionPositionForNick:(NICK_REC *)nick
{
  int mid = 0, result, low = 0, high = (int) [nicks count] - 1;
  const char *nick_flags = channel->server->get_nick_flags(channel->server);

  while (low < high) {
    mid = (low + high) / 2;
    result = nicklist_compare((NICK_REC *)[[nicks objectAtIndex:mid] pointerValue], nick, (void *)nick_flags);
    if (result < 0)
      low = mid + 1;
    else if (result > 0)
      high = mid - 1;
    else {
      NSLog(@"Error: Two identical nicks in channel!");
      return mid;
    }
  }
  /* Find free slot when inserting */
  if (low == high) {
    mid = (low + high) / 2;
    if (nicklist_compare((NICK_REC *)[[nicks objectAtIndex:mid] pointerValue], nick, (void *)nick_flags) < 0)
      mid++;
  }

  return mid;
}


//-------------------------------------------------------------------
// controlTextDidChange
// Called to mark change in topic sheet 
//
// "aNotification" - Ignored
//-------------------------------------------------------------------
- (void)controlTextDidChange:(NSNotification *)aNotification
{
  [self modeChanged:nil];
}

//-------------------------------------------------------------------
// personFromNickRec (C function)
// Called using glibs hash iterator. Used after joining a channel, 
// adding the nick from the hash table to our nick list
//
// "key" - The hashing key
// "rec" - The nick
// "nicks" - The array of nicks
//-------------------------------------------------------------------
void personFromNickRec(gpointer key, NICK_REC *rec, NSMutableArray *nicks)
{
  [nicks addObject:[NSValue valueWithPointer:rec]];
}

@end
