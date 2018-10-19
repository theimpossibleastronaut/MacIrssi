/*
 MIChannelSearchController.h
 Copyright (c) 2010 Matt Wright.
 
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

#import <Cocoa/Cocoa.h>
#import "MISearchBar.h"

@class ChannelController;

@interface MIChannelSearchController : NSObject {
  ChannelController *controller;

  NSString *currentSearchTerm;
  
  NSMutableArray *matches;
  unsigned long currentMatch;
}

- (id)initWithController:(ChannelController*)controller;
- (void)dealloc;

- (BOOL)canPerformFindForTag:(int)tag;
- (void)performFind:(id)sender;

- (void)searchBar:(MISearchBar*)bar findInDirection:(MISearchDirection)direction withString:(NSString*)term;
- (NSInteger)searchBar:(MISearchBar *)bar numberOfMatchesWithString:(NSString*)term;
- (void)searchBarShouldCancel:(MISearchBar*)bar;

@end
