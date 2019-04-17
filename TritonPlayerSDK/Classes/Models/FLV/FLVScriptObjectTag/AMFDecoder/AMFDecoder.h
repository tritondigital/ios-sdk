//
//  AMFDecoder.h
//  iPhoneV2
//
//  Created by Thierry Bucco on 09-03-26.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "AMF.h"
#import "ASObject.h"
#import "NSObject+Extensions.h"

#define AMFInvalidArchiveOperationException @"AMFInvalidArchiveOperationException"

@interface AMFDecoder : NSCoder 
{
	NSData *__weak m_data;
	const uint8_t *m_bytes;
	uint32_t m_position;
	AMFVersion m_objectEncoding;
	NSMutableDictionary *m_registeredClasses;
	NSMutableArray *m_objectTable;
	ASObject *m_currentDeserializedObject;
}
@property (nonatomic, readonly) AMFVersion objectEncoding;
@property (weak, nonatomic, readonly) NSData *data;

//--------------------------------------------------------------------------------------------------
//	Usual NSCoder methods
//--------------------------------------------------------------------------------------------------

- (id)initForReadingWithData:(NSData *)data encoding:(AMFVersion)encoding;
+ (id)unarchiveObjectWithData:(NSData *)data encoding:(AMFVersion)encoding;
+ (id)unarchiveObjectWithFile:(NSString *)path encoding:(AMFVersion)encoding;

- (BOOL)allowsKeyedCoding;
- (void)finishDecoding;
- (NSUInteger)bytesAvailable;
- (BOOL)isAtEnd;
- (Class)classForClassName:(NSString *)codedName;
+ (Class)classForClassName:(NSString *)codedName;
- (void)setClass:(Class)cls forClassName:(NSString *)codedName;
+ (void)setClass:(Class)cls forClassName:(NSString *)codedName;
- (BOOL)containsValueForKey:(NSString *)key;

- (BOOL)decodeBoolForKey:(NSString *)key;
- (double)decodeDoubleForKey:(NSString *)key;
- (float)decodeFloatForKey:(NSString *)key;
- (int32_t)decodeInt32ForKey:(NSString *)key;
- (int64_t)decodeInt64ForKey:(NSString *)key;
- (int)decodeIntForKey:(NSString *)key;
- (id)decodeObjectForKey:(NSString *)key;
- (void)decodeValueOfObjCType:(const char *)valueType at:(void *)data;

//--------------------------------------------------------------------------------------------------
//	AMF Extensions for reading specific data and deserializing externalizable classes
//--------------------------------------------------------------------------------------------------

- (BOOL)decodeBool;
- (int8_t)decodeChar;
- (double)decodeDouble;
- (float)decodeFloat;
- (int32_t)decodeInt;
- (int16_t)decodeShort;
- (uint8_t)decodeUnsignedChar;
- (uint32_t)decodeUnsignedInt;
- (uint16_t)decodeUnsignedShort;
- (uint32_t)decodeUnsignedInt29;
- (NSData *)decodeBytes:(uint32_t)length;
- (NSString *)decodeMultiByteString:(uint32_t)length encoding:(NSStringEncoding)encoding;
- (NSObject *)decodeObject;
- (NSString *)decodeUTF;
- (NSString *)decodeUTFBytes:(uint32_t)length;
@end



@interface AMF0Decoder : AMFDecoder
{
}

- (id)initForReadingWithData:(NSData *)data;
@end



@interface AMF3Decoder : AMFDecoder
{
	NSMutableArray *m_stringTable;
	NSMutableArray *m_traitsTable;
}

- (id)initForReadingWithData:(NSData *)data;
@end



@interface AMF3TraitsInfo : NSObject 
{
	NSString *m_className;
	BOOL m_dynamic;
	BOOL m_externalizable;
	NSUInteger m_count;
	NSMutableArray *m_properties;
}
@property (nonatomic, strong) NSString *className;
@property (nonatomic, assign) BOOL dynamic;
@property (nonatomic, assign) BOOL externalizable;
@property (nonatomic, assign) NSUInteger count;
@property (nonatomic, strong) NSMutableArray *properties;

- (void)addProperty:(NSString *)property;
@end