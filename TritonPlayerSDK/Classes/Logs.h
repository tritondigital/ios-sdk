//
//  Logs.h
//  FLVStreamPlayerLib64
//
//  Created by Carlos Pereira on 2014-10-16.
//
//
#define PLAYER_LOG_ENABLED                      0

#if PLAYER_LOG_ENABLED
#define PLAYER_LOG(fmt, ...) NSLog(@"%s: " fmt, __PRETTY_FUNCTION__, ##__VA_ARGS__)
#else
#define PLAYER_LOG(fmt, ...)
#endif

//FLOG MACRO
#if defined DEBUG && PLAYER_LOG_ENABLED
#define FLOG(fmt, ...) NSLog(@"%s: " fmt, __PRETTY_FUNCTION__, ##__VA_ARGS__)
#else
#define FLOG(fmt, ...)
#endif
