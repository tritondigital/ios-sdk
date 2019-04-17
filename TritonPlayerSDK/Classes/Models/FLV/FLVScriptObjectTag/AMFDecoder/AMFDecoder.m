//
//  AMFDecoder.m
//  iPhoneV2
//
//  Created by Thierry Bucco on 09-03-26.
//  Copyright 2009 StreamTheWorld. All rights reserved.
//

#import "AMFDecoder.h"

@interface AMFDecoder (Protected)
- (void)ensureLength:(unsigned)length;
- (void)unableToDecodeType:(const char *)type;
- (id)objectReferenceAtIndex:(uint32_t)index;
- (NSNumber *)decodeNumberForKey:(NSString *)key;
@end

@interface AMF0Decoder (Private)
- (NSObject *)decodeAMFObjectWithType:(AMF0Type)type;
- (NSArray *)decodeAMFArray;
- (NSObject *)decodeAMFTypedObject;
- (NSObject *)decodeAMFASObject:(NSString *)className;
- (NSString *)decodeAMFLongString;
- (NSString *)decodeAMFXML;
- (NSDate *)decodeAMFDate;
- (NSDictionary *)decodeAMFECMAArray;
- (NSObject *)decodeAMFReference;
@end

@interface AMF3Decoder (Private)
- (NSObject *)decodeAMFObjectWithType:(AMF3Type)type;
- (NSObject *)decodeAMFASObject;
- (NSObject *)decodeAMFArray;
- (NSString *)decodeAMFXML;
- (NSData *)decodeAMFByteArray;
- (NSDate *)decodeAMFDate;
- (AMF3TraitsInfo *)decodeAMFTraits:(uint32_t)infoBits;
- (NSString *)stringReferenceAtIndex:(uint32_t)index;
- (AMF3TraitsInfo *)traitsReferenceAtIndex:(uint32_t)index;
@end

#pragma mark -


@implementation AMFDecoder

static NSMutableDictionary *g_registeredClasses = nil;
@synthesize objectEncoding=m_objectEncoding, data=m_data;

#pragma mark -
#pragma mark Initialization & Deallocation

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// initForReadingWithData
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (id)initForReadingWithData:(NSData *)data encoding:(AMFVersion)encoding
{
    NSObjectExtensionsEmptyFunction();
    
	NSZone *temp = nil;  // Must not call methods after release
	              // Placeholder no longer needed
	return (encoding == kAMF0Version)
    ? [[AMF0Decoder allocWithZone:temp] initForReadingWithData:data]
    : [[AMF3Decoder allocWithZone:temp] initForReadingWithData:data];
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// initForReadingWithData
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (id)initForReadingWithData:(NSData *)data
{
	if (self = [super init])
	{
		m_data = data;
		m_bytes = [data bytes];
		m_objectTable = [[NSMutableArray alloc] init];
		m_registeredClasses = [[NSMutableDictionary alloc] init];
		m_currentDeserializedObject = nil;
		m_position = 0;
	}
	return self;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// unarchiveObjectWithData
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

+ (id)unarchiveObjectWithData:(NSData *)data encoding:(AMFVersion)encoding
{
	if (data == nil)
	{
		[NSException raise:@"AMFInvalidArchiveOperationException" format:@"Invalid data"];
	}
	AMFDecoder *byteArray = [[AMFDecoder alloc] initForReadingWithData:data encoding:encoding];
	id object = [byteArray decodeObject];
	return object;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// unarchiveObjectWithFile
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

+ (id)unarchiveObjectWithFile:(NSString *)path encoding:(AMFVersion)encoding
{
	NSData *data = [NSData dataWithContentsOfFile:path];
	return [[self class] unarchiveObjectWithData:data encoding:encoding];
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// dealloc
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=




#pragma mark -
#pragma mark Public methods

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// allowsKeyedCoding
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (BOOL)allowsKeyedCoding
{
	return !(!m_currentDeserializedObject || m_currentDeserializedObject.isExternalizable);
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// containsValueForKey
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (BOOL)containsValueForKey:(NSString *)key
{
	return [m_currentDeserializedObject.properties objectForKey:key] != nil;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// finishDecoding
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)finishDecoding
{
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// bytesAvailable
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (NSUInteger)bytesAvailable
{
	return [m_data length] - m_position;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// isAtEnd
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (BOOL)isAtEnd
{
	return !(m_position < [m_data length]);
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// classForClassName
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (Class)classForClassName:(NSString *)codedName
{
	return [m_registeredClasses objectForKey:codedName];
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// classForClassName
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

+ (Class)classForClassName:(NSString *)codedName
{
	return [g_registeredClasses objectForKey:codedName];
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// setClass
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)setClass:(Class)cls forClassName:(NSString *)codedName
{
	[m_registeredClasses setObject:cls forKey:codedName];
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// setClass
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

+ (void)setClass:(Class)cls forClassName:(NSString *)codedName
{
	if (!g_registeredClasses) g_registeredClasses = [[NSMutableDictionary alloc] init];
	[g_registeredClasses setObject:cls forKey:codedName];
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeBoolForKey
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (BOOL)decodeBoolForKey:(NSString *)key
{
	NSNumber *num = [self decodeNumberForKey:key];
	if (num) return [num boolValue];
	return NO;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeDoubleForKey
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (double)decodeDoubleForKey:(NSString *)key
{
	NSNumber *num = [self decodeNumberForKey:key];
	if (num) return [num doubleValue];
	return 0.0;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeFloatForKey
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (float)decodeFloatForKey:(NSString *)key
{
	NSNumber *num = [self decodeNumberForKey:key];
	if (num) return [num floatValue];
	return 0.0f;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeInt32ForKey
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (int32_t)decodeInt32ForKey:(NSString *)key
{
	NSNumber *num = [self decodeNumberForKey:key];
	if (num) return [num intValue];
	return 0;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeInt64ForKey
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (int64_t)decodeInt64ForKey:(NSString *)key
{
	NSNumber *num = [self decodeNumberForKey:key];
	if (num) return [num integerValue];
	return 0;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeIntForKey
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (int)decodeIntForKey:(NSString *)key
{
	NSNumber *num = [self decodeNumberForKey:key];
	if (num) return [num intValue];
	return 0;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeObjectForKey
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (id)decodeObjectForKey:(NSString *)key
{
	return [m_currentDeserializedObject.properties objectForKey:key];
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeValueOfObjCType
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)decodeValueOfObjCType:(const char *)valueType at:(void *)data
{
	switch (*valueType)
	{
		case 'c':
		{
			int8_t *value = data;
			*value = [self decodeChar];
		}
            break;
		case 'C':
		{
			uint8_t *value = data;
			*value = [self decodeUnsignedChar];
		}
            break;
		case 'i':
		{
			int32_t *value = data;
			*value = [self decodeInt];
		}
            break;
		case 'I':
		{
			uint32_t *value = data;
			*value = [self decodeUnsignedInt];
		}
            break;
		case 's':
		{
			int16_t *value = data;
			*value = [self decodeShort];
		}
            break;
		case 'S':
		{
			uint16_t *value = data;
			*value = [self decodeUnsignedShort];
		}
            break;
		case 'f':
		{
			float *value = data;
			*value = [self decodeFloat];
		}
            break;
		case 'd':
		{
			double *value = data;
			*value = [self decodeDouble];
		}
            break;
		case 'B':
		{
			uint8_t *value = data;
			*value = [self decodeUnsignedChar];
		}
            break;
		case '*':
		{
			const char **cString = data;
			NSString *string = [self decodeUTF];
			*cString = NSZoneMalloc(NSDefaultMallocZone(), 
                                    [string lengthOfBytesUsingEncoding:NSUTF8StringEncoding] + 1);
			*cString = [string cStringUsingEncoding:NSUTF8StringEncoding];
		}
            break;
		case '@':
		{
			void **obj = data;
			*obj = (__bridge void *)([self decodeObject]);
		}
            break;
		default:
			[self unableToDecodeType:valueType];
	}
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeBool
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (BOOL)decodeBool
{
	return ([self decodeUnsignedChar] != 0);
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeChar
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (int8_t)decodeChar
{
	[self ensureLength:1];
	return (int8_t)m_bytes[m_position++];
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeBytes
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (NSData *)decodeBytes:(uint32_t)length
{
	[self ensureLength:length];
	NSData *subdata = [m_data subdataWithRange:(NSRange){m_position, length}];
	m_position += length;
	return subdata;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeDouble
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (double)decodeDouble
{
	[self ensureLength:8];
	uint8_t data[8];
	data[7] = m_bytes[m_position++];
	data[6] = m_bytes[m_position++];
	data[5] = m_bytes[m_position++];
	data[4] = m_bytes[m_position++];
	data[3] = m_bytes[m_position++];
	data[2] = m_bytes[m_position++];
	data[1] = m_bytes[m_position++];
	data[0] = m_bytes[m_position++];
	return *((double *)data);
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeFloat
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (float)decodeFloat
{
	[self ensureLength:4];
	uint8_t data[4];
	data[3] = m_bytes[m_position++];
	data[2] = m_bytes[m_position++];
	data[1] = m_bytes[m_position++];
	data[0] = m_bytes[m_position++];
	return *((float *)data);
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeInt
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (int32_t)decodeInt
{
	[self ensureLength:4];
	uint8_t ch1 = m_bytes[m_position++];
	uint8_t ch2 = m_bytes[m_position++];
	uint8_t ch3 = m_bytes[m_position++];
	uint8_t ch4 = m_bytes[m_position++];
	return (ch1 << 24) + (ch2 << 16) + (ch3 << 8) + ch4;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeObject
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (NSObject *)decodeObject
{
	return nil;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeShort
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (int16_t)decodeShort
{
	[self ensureLength:2];
	int8_t ch1 = m_bytes[m_position++];
	int8_t ch2 = m_bytes[m_position++];
	return (int16_t)(ch1 << 8) + ch2;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeUnsignedChar
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (uint8_t)decodeUnsignedChar
{
	[self ensureLength:1];
	return m_bytes[m_position++];
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeUnsignedInt
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (uint32_t)decodeUnsignedInt
{
	[self ensureLength:4];
	uint8_t ch1 = m_bytes[m_position++];
	uint8_t ch2 = m_bytes[m_position++];
	uint8_t ch3 = m_bytes[m_position++];
	uint8_t ch4 = m_bytes[m_position++];
	return ((ch1 & 0xFF) << 24) | ((ch2 & 0xFF) << 16) | ((ch3 & 0xFF) << 8) | (ch4 & 0xFF);
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeUnsignedShort
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (uint16_t)decodeUnsignedShort
{
	[self ensureLength:2];
	int8_t ch1 = m_bytes[m_position++];
	int8_t ch2 = m_bytes[m_position++];
	return (int16_t)((ch1 & 0xFF) << 8) | (ch2 & 0xFF);
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeUnsignedInt29
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (uint32_t)decodeUnsignedInt29
{
	uint32_t value;
	uint8_t ch = [self decodeUnsignedChar] & 0xFF;
	
	if (ch < 128)
	{
		return ch;
	}
	
	value = (ch & 0x7F) << 7;
	ch = [self decodeUnsignedChar] & 0xFF;
	if (ch < 128)
	{
		return value | ch;
	}
	
	value = (value | (ch & 0x7F)) << 7;
	ch = [self decodeUnsignedChar] & 0xFF;
	if (ch < 128)
	{
		return value | ch;
	}
	
	value = (value | (ch & 0x7F)) << 8;
	ch = [self decodeUnsignedChar] & 0xFF;
	return value | ch;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeUTF
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (NSString *)decodeUTF
{
	return [self decodeUTFBytes:[self decodeUnsignedShort]];
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeUTFBytes
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (NSString *)decodeUTFBytes:(uint32_t)length
{
	if (length == 0)
	{
		return [NSString string];
	}
	[self ensureLength:length];
	return [[NSString alloc] initWithData:[self decodeBytes:length] 
                                  encoding:NSUTF8StringEncoding];
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeMultiByteString
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (NSString *)decodeMultiByteString:(uint32_t)length encoding:(NSStringEncoding)encoding
{
	return [[NSString alloc] initWithData:[self decodeBytes:length] encoding:encoding];
}



#pragma mark -
#pragma mark Private methods

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// _deserializeObject
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (NSObject *)_deserializeObject:(ASObject *)object
{
	if (!object.type)
	{
		return object;
	}
	NSString *className = object.type;
	Class cls;
	if (!(cls = [m_registeredClasses objectForKey:className]))
	{
		if (!(cls = [g_registeredClasses objectForKey:className]))
		{
			if (!(cls =  NSClassFromString(className)))
			{
				return object;
			}
		}
	}
	ASObject *lastDeserializedObject = m_currentDeserializedObject;
	m_currentDeserializedObject = object;
	NSObject <NSCoding> *desObject = [cls allocWithZone:NULL];
	desObject = [desObject initWithCoder:self];
	desObject = [desObject awakeAfterUsingCoder:self];
	m_currentDeserializedObject = lastDeserializedObject;
	
	return desObject;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeNumberForKey
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (NSNumber *)decodeNumberForKey:(NSString *)key
{
	NSNumber *num = [m_currentDeserializedObject.properties objectForKey:key];
	if (![num isKindOfClass:[NSNumber class]])
	{
		return nil;
	}
	return num;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// ensureLength
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)ensureLength:(unsigned)length
{
	if (m_position + length > [m_data length])
	{
		[NSException raise:@"NSUnarchiverBadArchiveException"
                    format:@"%@ attempt to read beyond length", [self className]];
	}
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// unableToDecodeType
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)unableToDecodeType:(const char *)type
{
	[NSException raise:@"NSUnarchiverCannotDecodeException"
                format:@"%@ cannot decode type=%s", [self className], type];
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// objectReferenceAtIndex
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (id)objectReferenceAtIndex:(uint32_t)index
{
	if ([m_objectTable count] <= index)
	{
		[NSException raise:@"NSUnarchiverCannotDecodeException" 
                    format:@"%@ cannot decode object reference", [self className]];
	}
	return [m_objectTable objectAtIndex:index];
}
@end



#pragma mark -



@implementation AMF0Decoder

#pragma mark -
#pragma mark Initialization & Deallocation

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// initForReadingWithData
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (id)initForReadingWithData:(NSData *)data
{
	if (self = [super initForReadingWithData:data])
	{
		m_objectEncoding = kAMF0Version;
	}
	return self;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// dealloc
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=




#pragma mark -
#pragma mark Public methods

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeObject
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (NSObject *)decodeObject
{
	AMF0Type type = (AMF0Type)[self decodeUnsignedChar];
	return [self decodeAMFObjectWithType:type];
}



#pragma mark -
#pragma mark Private methods

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeAMFObjectWithType
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (NSObject *)decodeAMFObjectWithType:(AMF0Type)type
{
	id value = nil;
	switch (type)
	{
		case kAMF0NumberType:
			value = [NSNumber numberWithDouble:[self decodeDouble]];
			break;
			
		case kAMF0BooleanType:
			value = [NSNumber numberWithBool:[self decodeBool]];
			break;
			
		case kAMF0StringType:
			value = [self decodeUTF];
			break;
			
		case kAMF0AVMPlusObjectType:
			value = [AMFDecoder unarchiveObjectWithData:[m_data subdataWithRange:
                                                         (NSRange){m_position, [m_data length] - m_position}] encoding:kAMF3Version];
			break;
			
		case kAMF0StrictArrayType:
			value = [self decodeAMFArray];
			break;
			
		case kAMF0TypedObjectType:
			value = [self decodeAMFTypedObject];
			break;
			
		case kAMF0LongStringType:
			value = [self decodeAMFLongString];
			break;
			
		case kAMF0ObjectType:
			value = [self decodeAMFASObject:nil];
			break;
			
		case kAMF0XMLObjectType:
			value = [self decodeAMFXML];
			break;
			
		case kAMF0NullType:
			value = [NSNull null];
			break;
			
		case kAMF0DateType:
			value = [self decodeAMFDate];
			break;
			
		case kAMF0ECMAArrayType:
			value = [self decodeAMFECMAArray];
			break;
			
		case kAMF0ReferenceType:
			value = [self decodeAMFReference];
			break;
			
		case kAMF0UndefinedType:
			value = [NSNull null];
			break;
			
		case kAMF0UnsupportedType:
			[self unableToDecodeType:"Unsupported type"];
			break;
			
		case kAMF0ObjectEndType:
			[self unableToDecodeType:"Unexpected object end"];
			break;
			
		case kAMF0RecordsetType:
			[self unableToDecodeType:"Unexpected recordset"];
			break;
			
		default:
			[self unableToDecodeType:"Unknown type"];
	}
	return value;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeAMFArray
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (NSArray *)decodeAMFArray
{
	uint32_t size = [self decodeUnsignedInt];
	NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:size];
	[m_objectTable addObject:array];
	for (uint32_t i = 0; i < size; i++)
	{
		NSObject *obj = [self decodeObject];
		if (obj != nil)
		{
			[array addObject:obj];
		}
	}
	return array;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeAMFTypedObject
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (NSObject *)decodeAMFTypedObject
{
	NSString *className = [self decodeUTF];
	return [self decodeAMFASObject:className];
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeAMFASObject
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (NSObject *)decodeAMFASObject:(NSString *)className
{
	ASObject *object = [[ASObject alloc] init];
	object.type = className;
	[m_objectTable addObject:object];
	
	NSString *propertyName = [self decodeUTF];
	AMF0Type type = [self decodeUnsignedChar];
	while (type != kAMF0ObjectEndType)
	{
		[object setValue:[self decodeAMFObjectWithType:type] forKey:propertyName];
		propertyName = [self decodeUTF];
		type = [self decodeUnsignedChar];
	}
	
	NSObject *desObject = [self _deserializeObject:object];
	if (desObject == object)
	{
		return object;
	}
	[m_objectTable replaceObjectAtIndex:[m_objectTable indexOfObject:object] withObject:desObject];
	return desObject;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeAMFLongString
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (NSString *)decodeAMFLongString
{
	uint32_t length = [self decodeUnsignedInt];
	if (length == 0)
	{
		return [NSString string];
	}
	return [self decodeUTFBytes:length];
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeAMFXML
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (NSString *)decodeAMFXML
{
	return [self decodeAMFLongString];
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeAMFDate
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (NSDate *)decodeAMFDate
{
	NSTimeInterval time = [self decodeDouble];
	// timezone
	[self decodeUnsignedShort];
	return [NSDate dateWithTimeIntervalSince1970:(time / 1000)];
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeAMFECMAArray
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (NSDictionary *)decodeAMFECMAArray
{
	uint32_t size = [self decodeUnsignedInt];
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:size];
	[m_objectTable addObject:dict];
	
	NSString *propertyName = [self decodeUTF];
	AMF0Type type = [self decodeUnsignedChar];
	while (type != kAMF0ObjectEndType)
	{
		[dict setValue:[self decodeAMFObjectWithType:type] forKey:propertyName];
		propertyName = [self decodeUTF];
		type = [self decodeUnsignedChar];
	}
	return dict;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeAMFReference
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (NSObject *)decodeAMFReference
{
	uint16_t index = [self decodeUnsignedShort];
	return [self objectReferenceAtIndex:index];
}

@end



#pragma mark -



@implementation AMF3Decoder

#pragma mark -
#pragma mark Initialization & Deallocation

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// initForReadingWithData
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (id)initForReadingWithData:(NSData *)data
{
	if (self = [super initForReadingWithData:data])
	{
		m_stringTable = [[NSMutableArray alloc] init];
		m_traitsTable = [[NSMutableArray alloc] init];
		m_objectEncoding = kAMF3Version;
	}
	return self;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// dealloc
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=




#pragma mark -
#pragma mark Public methods



//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeObject
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (NSObject *)decodeObject
{
	AMF3Type type = (AMF3Type)[self decodeUnsignedChar];
	return [self decodeAMFObjectWithType:type];
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeUTF
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (NSString *)decodeUTF
{
	uint32_t ref = [self decodeUnsignedInt29];
	if ((ref & 1) == 0)
	{
		ref = (ref >> 1);
		return [self stringReferenceAtIndex:ref];
	}
	uint32_t length = ref >> 1;
	if (length == 0)
	{
		return [NSString string];
	}
	NSString *value = [self decodeUTFBytes:length];
	[m_stringTable addObject:value];
	return value;
}



#pragma mark -
#pragma mark Private methods

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// stringReferenceAtIndex
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (NSString *)stringReferenceAtIndex:(uint32_t)index
{
	if ([m_stringTable count] <= index)
	{
		[NSException raise:@"NSUnarchiverCannotDecodeException" 
                    format:@"%@ cannot decode string reference", [self className]];
	}
	return [m_stringTable objectAtIndex:index];
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// traitsReferenceAtIndex
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (AMF3TraitsInfo *)traitsReferenceAtIndex:(uint32_t)index
{
	if ([m_traitsTable count] <= index)
	{
		[NSException raise:@"NSUnarchiverCannotDecodeException" 
                    format:@"%@ cannot decode traits reference", [self className]];
	}
	return [m_traitsTable objectAtIndex:index];
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeAMFObjectWithType
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (NSObject *)decodeAMFObjectWithType:(AMF3Type)type
{
	id value = nil;
	switch (type)
	{
		case kAMF3StringType:
			value = [self decodeUTF];
			break;
            
		case kAMF3ObjectType:
			value = [self decodeAMFASObject];
			break;
			
		case kAMF3ArrayType:
			value = [self decodeAMFArray];
			break;
			
		case kAMF3FalseType:
			value = [NSNumber numberWithBool:NO];
			break;
			
		case kAMF3TrueType:
			value = [NSNumber numberWithBool:YES];
			break;
			
		case kAMF3IntegerType:
		{
			int32_t intValue = [self decodeUnsignedInt29];
			intValue = (intValue << 3) >> 3;
			value = [NSNumber numberWithInt:intValue];
			break;
		}
			
		case kAMF3DoubleType:
			value = [NSNumber numberWithDouble:[self decodeDouble]];
			break;
			
		case kAMF3UndefinedType:
			return [NSNull null];
			break;
			
		case kAMF3NullType:
			return [NSNull null];
			break;
			
		case kAMF3XMLType:
		case kAMF3XMLDocType:
			value = [self decodeAMFXML];
			break;
			
		case kAMF3DateType:
			value = [self decodeAMFDate];
			break;
			
		case kAMF3ByteArrayType:
			value = [self decodeAMFByteArray];
			break;
			
		default:
			[self unableToDecodeType:"Unknown type"];
			break;
	}
	return value;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeAMFASObject
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (NSObject *)decodeAMFASObject
{
	uint32_t ref = [self decodeUnsignedInt29];
	if ((ref & 1) == 0)
	{
		ref = (ref >> 1);
		return [self objectReferenceAtIndex:ref];
	}
	
	AMF3TraitsInfo *traitsInfo = [self decodeAMFTraits:ref];
	NSObject *object;
	if (traitsInfo.className && [traitsInfo.className length] > 0)
	{
		object = [[ASObject alloc] init];
		[(ASObject *)object setType:traitsInfo.className];
		[(ASObject *)object setIsExternalizable:traitsInfo.externalizable];
	}
	else
	{
		object = [[NSMutableDictionary alloc] init];
	}
	[m_objectTable addObject:object];
	
	NSString *key;
	for (key in traitsInfo.properties)
	{
		[object setValue:[self decodeObject] forKey:key];
	}
	
	if (traitsInfo.dynamic)
	{
		key = [self decodeUTF];
		while (key != nil && [key length] > 0)
		{
			[object setValue:[self decodeObject] forKey:key];
			key = [self decodeUTF];
		}
	}
	
	if (![object isMemberOfClass:[ASObject class]])
	{
		NSDictionary *dictCopy = [object copy];
		return dictCopy;
	}
	
	NSObject *desObject = [self _deserializeObject:(ASObject *)object];
	if (desObject == object)
	{
		return object;
	}
	[m_objectTable replaceObjectAtIndex:[m_objectTable indexOfObject:object] withObject:desObject];
	return desObject;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeAMFArray
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (NSObject *)decodeAMFArray
{
	uint32_t ref = [self decodeUnsignedInt29];
	
	if ((ref & 1) == 0)
	{
		ref = (ref >> 1);
		return [self objectReferenceAtIndex:ref];
	}
	
	uint32_t length = (ref >> 1);
	NSObject *array = nil;
	for (;;)
	{
		NSString *name = [self decodeUTF];
		if (name == nil || [name length] == 0) 
		{
			break;
		}
		
		if (array == nil)
		{
			array = [NSMutableDictionary dictionary];
			[m_objectTable addObject:array];
		}
		[(NSMutableDictionary *)array setObject:[self decodeObject] forKey:name];
	}
	
	if (array == nil)
	{
		array = [NSMutableArray array];
		[m_objectTable addObject:array];
		for (uint32_t i = 0; i < length; i++)
		{
			[(NSMutableArray *)array addObject:[self decodeObject]];
		}
	}
	else
	{
		for (uint32_t i = 0; i < length; i++)
		{
			[(NSMutableDictionary *)array setObject:[self decodeObject] 
                                             forKey:[NSNumber numberWithInt:i]];
		}
	}
	
	return array;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeAMFTraits
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (AMF3TraitsInfo *)decodeAMFTraits:(uint32_t)infoBits
{
	if ((infoBits & 3) == 1)
	{
		infoBits = (infoBits >> 2);
		return [self traitsReferenceAtIndex:infoBits];
	}
	BOOL externalizable = (infoBits & 4) == 4;
	BOOL dynamic = (infoBits & 8) == 8;
	NSUInteger count = infoBits >> 4;
	NSString *className = [self decodeUTF];
	
	AMF3TraitsInfo *info = [[AMF3TraitsInfo alloc] init];
	info.className = className;
	info.dynamic = dynamic;
	info.externalizable = externalizable;
	info.count = count;
	while (count--)
	{
		[info addProperty:[self decodeUTF]];
	}
	[m_traitsTable addObject:info];
	return info;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeAMFXML
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (NSString *)decodeAMFXML
{
	// @FIXME
	return [self decodeUTF];
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeAMFByteArray
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (NSData *)decodeAMFByteArray
{
	uint32_t ref = [self decodeUnsignedInt29];
	if ((ref & 1) == 0)
	{
		ref = (ref >> 1);
		return [self objectReferenceAtIndex:ref];
	}
	uint32_t length = (ref >> 1);
	NSData *data = [self decodeBytes:length];
	return data;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// decodeAMFDate
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (NSDate *)decodeAMFDate
{
	uint32_t ref = [self decodeUnsignedInt29];
	if ((ref & 1) == 0)
	{
		ref = (ref >> 1);
		return [self objectReferenceAtIndex:ref];
	}
	NSTimeInterval time = [self decodeDouble];
	NSDate *date = [NSDate dateWithTimeIntervalSince1970:(time / 1000)];
	[m_objectTable addObject:date];
	return date;
}

@end



#pragma mark -



@implementation AMF3TraitsInfo

@synthesize className=m_className;
@synthesize dynamic=m_dynamic;
@synthesize externalizable=m_externalizable;
@synthesize count=m_count;
@synthesize properties=m_properties;


#pragma mark -
#pragma mark Initialization & Deallocation

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// init
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (id)init
{
	if (self = [super init])
	{
		m_properties = [[NSMutableArray alloc] init];
		m_dynamic = NO;
		m_externalizable = NO;
	}
	return self;
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// dealloc
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=




#pragma mark -
#pragma mark Public methods

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// addProperty
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (void)addProperty:(NSString *)property
{
	[m_properties addObject:property];
}

//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// isEqual
//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

- (BOOL)isEqual:(id)anObject
{
	if ([anObject class] != [self class])
	{
		return NO;
	}
	AMF3TraitsInfo *traits = (AMF3TraitsInfo *)anObject;
	BOOL classNameIdentical = m_className == nil 
    ? traits.className == nil 
    : [traits.className isEqualToString:m_className];
	BOOL propertiesIdentical = m_properties == nil 
    ? traits.properties == nil 
    : [traits.properties isEqualToArray:m_properties];
	if (classNameIdentical &&
		traits.dynamic == m_dynamic &&
		traits.externalizable == m_externalizable &&
		[traits count] == m_count &&
		propertiesIdentical)
	{
		return YES;
	}
	return NO;
}

@end