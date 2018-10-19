/*
 AppcastVersionComparator.m
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

#import "AppcastVersionComparator.h"

@implementation AppcastVersionComparator

+ (AppcastVersionComparator *)defaultComparator
{
	static AppcastVersionComparator *defaultComparator = nil;
	if (defaultComparator == nil)
		defaultComparator = [[AppcastVersionComparator alloc] init];
	return defaultComparator;
}

typedef enum {
  kNumberType,
  kStringType,
  kPeriodType
} SUCharacterType;

- (SUCharacterType)typeOfCharacter:(NSString *)character
{
  if ([character isEqualToString:@"."]) {
    return kPeriodType;
  } else if ([[NSCharacterSet decimalDigitCharacterSet] characterIsMember:[character characterAtIndex:0]]) {
    return kNumberType;
  } else {
    return kStringType;
  }	
}

- (NSArray *)splitVersionString:(NSString *)version
{
  NSString *character;
  NSMutableString *s;
    unsigned long n;
  int i, oldType, newType;
  NSMutableArray *parts = [NSMutableArray array];
  if ([version length] == 0) {
    // Nothing to do here
    return parts;
  }
  s = [[[version substringToIndex:1] mutableCopy] autorelease];
  oldType = [self typeOfCharacter:s];
  n = [version length] - 1;
  for (i = 1; i <= n; ++i) {
    character = [version substringWithRange:NSMakeRange(i, 1)];
    newType = [self typeOfCharacter:character];
    if (oldType != newType || oldType == kPeriodType) {
      // We've reached a new segment
			NSString *aPart = [[NSString alloc] initWithString:s];
      [parts addObject:aPart];
			[aPart release];
      [s setString:character];
    } else {
      // Add character to string and continue
      [s appendString:character];
    }
    oldType = newType;
  }
  
  // Add the last part onto the array
  [parts addObject:[NSString stringWithString:s]];
  return parts;
}

- (NSComparisonResult)compareVersion:(NSString *)versionA toVersion:(NSString *)versionB;
{  
	NSArray *partsA = [self splitVersionString:versionA];
  NSArray *partsB = [self splitVersionString:versionB];
  
  NSString *partA, *partB;
    unsigned long n;
    int i, typeA, typeB, intA, intB;
  
  n = MIN([partsA count], [partsB count]);
  for (i = 0; i < n; ++i) {
    partA = [partsA objectAtIndex:i];
    partB = [partsB objectAtIndex:i];
    
    typeA = [self typeOfCharacter:partA];
    typeB = [self typeOfCharacter:partB];
    
    // Compare types
    if (typeA == typeB) {
      // Same type; we can compare
      if (typeA == kNumberType) {
        intA = [partA intValue];
        intB = [partB intValue];
        if (intA > intB) {
          return NSOrderedDescending;
        } else if (intA < intB) {
          return NSOrderedAscending;
        }
      } else if (typeA == kStringType) {
        NSComparisonResult result = [partA compare:partB];
        if (result != NSOrderedSame) {
          return result;
        }
      }
    } else {
      // Not the same type? Now we have to do some validity checking
      if (typeA != kStringType && typeB == kStringType) {
        // typeA wins
        return NSOrderedDescending;
      } else if (typeA == kStringType && typeB != kStringType) {
        // typeB wins
        return NSOrderedAscending;
      } else {
        // One is a number and the other is a period. The period is invalid
        if (typeA == kNumberType) {
          return NSOrderedDescending;
        } else {
          return NSOrderedAscending;
        }
      }
    }
  }
  // The versions are equal up to the point where they both still have parts
  // Lets check to see if one is larger than the other
  if ([partsA count] != [partsB count]) {
    // Yep. Lets get the next part of the larger
    // n holds the index of the part we want.
    NSString *missingPart;
    SUCharacterType missingType;
		NSComparisonResult shorterResult, largerResult;
    
    if ([partsA count] > [partsB count]) {
      missingPart = [partsA objectAtIndex:n];
      shorterResult = NSOrderedAscending;
      largerResult = NSOrderedDescending;
    } else {
      missingPart = [partsB objectAtIndex:n];
      shorterResult = NSOrderedDescending;
      largerResult = NSOrderedAscending;
    }
    
    missingType = [self typeOfCharacter:missingPart];
    // Check the type
    if (missingType == kStringType) {
      // It's a string. Shorter version wins
      return shorterResult;
    } else {
      // It's a number/period. Larger version wins
      return largerResult;
    }
  }
  
  // The 2 strings are identical
  return NSOrderedSame;
}


@end
