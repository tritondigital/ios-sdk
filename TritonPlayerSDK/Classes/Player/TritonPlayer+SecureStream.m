#import "TritonPlayer+SecureStream.h"
#import "TritonPlayer+SecureStreamPrivate.h"
#include "SecureLib.h"


#define stw_b( stw_74, stw_s, stw_78) if ( stw_cv == stw_74) {  \
strncpy( stw_op, gSecInfo->rp[stw_s], strlen(gSecInfo->rp[stw_s])); \
stw_op += strlen(gSecInfo->rp[stw_s]);  \
stw_cv = stw_cv + stw_78; }

#define stw_75( stw_16, stw_98, stw_108, stw_94, stw_90, stw_101,  \
stw_95, stw_84, stw_70, stw_96, stw_81, stw_51, stw_97, stw_79,  \
stw_44, stw_35, stw_76, stw_40, stw_99, stw_72, stw_37, stw_93,  \
stw_71, stw_19, stw_92, stw_68, stw_15, stw_102, stw_66, stw_14,  \
stw_103, stw_57, stw_11, stw_105, stw_52, stw_8, stw_106, stw_49,  \
stw_7, stw_107, stw_48, stw_4, stw_77, stw_46, stw_2, stw_109, stw_42 \
, stw_100, stw_110, stw_53, stw_88, stw_111, stw_54, stw_80, stw_112, \
stw_55, stw_73, stw_113, stw_56, stw_69, stw_114 ) char  *  stw_ro = \
( char  *  ) malloc(514  *  sizeof( char)); char  *  stw_op = stw_ro \
; int32_t stw_cv = stw_16; while ( stw_cv != 0) { stw_b( stw_98,  \
stw_108, stw_94) stw_b( stw_90, stw_101, stw_95) stw_b( stw_84,  \
stw_70, stw_96) stw_b( stw_81, stw_51, stw_97) stw_b( stw_79, stw_44, \
stw_35) stw_b( stw_76, stw_40, stw_99) stw_b( stw_72, stw_37, stw_93 \
) stw_b( stw_71, stw_19, stw_92) stw_b( stw_68, stw_15, stw_102)  \
stw_b( stw_66, stw_14, stw_103) stw_b( stw_57, stw_11, stw_105) stw_b \
( stw_52, stw_8, stw_106) stw_b( stw_49, stw_7, stw_107) stw_b(  \
stw_48, stw_4, stw_77) stw_b( stw_46, stw_2, stw_109) stw_b( stw_42,  \
stw_100, stw_110) stw_b( stw_53, stw_88, stw_111) stw_b( stw_54,  \
stw_80, stw_112) stw_b( stw_55, stw_73, stw_113) stw_b( stw_56,  \
stw_69, stw_114) } stw_ro[512] = '\0';

#define stw_22( stw_60, stw_91, stw_32, stw_5, stw_3, stw_33, stw_34) size_t  \
stw_w; uint8_t  *  stw_1 = Hvewufaw( stw_ro, & stw_w); free( stw_ro); \
size_t stw_i, stw_q; uint8_t  *  stw_z = Hvewufaw( STW_CHALLENGE, &  \
stw_i); uint8_t  *  stw_v = Hvewufaw( STW_CODE, & stw_q); size_t  \
stw_c = stw_i + stw_q + 1; uint8_t  *  stw_d = ( uint8_t  *  ) malloc \
( stw_c); stw_d[0] = ( uint8_t) stw_i; memcpy(& stw_d[1], stw_z,  \
stw_i); memcpy(& stw_d[1 + stw_i], stw_v, stw_q); free( stw_z); free( \
stw_v); int stw_104 = stw_60; int stw_l = 0; uint32_t stw_r = 0; for (  \
int stw_n = 0; stw_n < stw_104; stw_n++) { stw_l = stw_91[stw_n]; stw_r = \
stw_32[stw_n]; size_t stw_t = stw_c  *  2  *  stw_l; uint32_t stw_h =  \
stw_r; uint32_t stw_j = stw_h; uint8_t  *  stw_k = ( uint8_t  *  )  \
malloc( stw_t); for ( int stw_a = 0; stw_a < 8; stw_a++) { stw_h =  \
stw_h  *  1664525UL + 1013904223UL; stw_j = stw_j  *  1103515245UL +  \
12345UL; } for ( int stw_a = 0; stw_a < stw_t; stw_a++) { stw_h =  \
stw_h  *  1664525UL + 1013904223UL; stw_j = stw_j  *  1103515245UL +  \
12345UL; stw_k[ stw_a] = ( int8_t)(( uint8_t)( stw_h >> 22) ^ (  \
uint8_t)( stw_j >> 24)); } uint8_t  *  stw_e = stw_d; size_t stw_g =  \
stw_t; uint8_t stw_p = 0; for ( int stw_x = 0; stw_x < stw_l; stw_x++ \
) { stw_g = stw_g - stw_c; for ( int stw_a = 0; stw_a < stw_c; stw_a \
++) { stw_p = stw_k[ stw_g + stw_a]; stw_e[ stw_a] = stw_e[ stw_a] ^  \
stw_p; } stw_g = stw_g - stw_c; uint8_t  *  stw_f = ( uint8_t  *  )  \
malloc( stw_c); for ( uint8_t stw_a = 0; stw_a < stw_c; stw_a++) {  \
stw_f[ stw_a] = stw_a; } for ( int stw_a = 0; stw_a < stw_c; stw_a++)  \
{ stw_p = stw_k[ stw_g + stw_a]; uint8_t stw_u = stw_p % stw_c;  \
uint8_t stw_45 = stw_f[ stw_a]; stw_f[ stw_a] = stw_f[ stw_u]; stw_f[ \
stw_u] = stw_45; } uint8_t  *  stw_y = ( uint8_t  *  ) malloc( stw_c \
); for ( int stw_a = 0; stw_a < stw_c; stw_a++) { stw_y[ stw_f[ stw_a \
]] = stw_e[ stw_a]; } if ( stw_e != stw_d) free( stw_e); stw_e =  \
stw_y; free( stw_f); } free( stw_d); stw_d = stw_e; free( stw_k); }  \
char  *  STW_RESPONSE = Ajhdszfas( stw_d, stw_c, stw_1, stw_w, stw_5, \
stw_3, stw_33, stw_34); free( stw_d); free( stw_1);


@implementation TritonPlayer (SecureStream)

static SecureStruct* gSecInfo;

- (void)initSecurity:(SecureStruct*)pSecInfo
{
	gSecInfo = pSecInfo;
}

@end

@implementation TritonPlayer (SecureStreamPrivate)

- (NSString*)processChallengeWithCode:(NSString*)codeString andChallenge:(NSString*)challengeString
{
	const char* STW_CHALLENGE = [challengeString cStringUsingEncoding:NSASCIIStringEncoding];
	const char* STW_CODE = [codeString cStringUsingEncoding:NSASCIIStringEncoding];
	
	stw_75(gSecInfo->ss,
			 gSecInfo->stv[0], gSecInfo->strp[0], gSecInfo->stin[0],
			 gSecInfo->stv[1], gSecInfo->strp[1], gSecInfo->stin[1],
			 gSecInfo->stv[2], gSecInfo->strp[2], gSecInfo->stin[2],
			 gSecInfo->stv[3], gSecInfo->strp[3], gSecInfo->stin[3],
			 gSecInfo->stv[4], gSecInfo->strp[4], gSecInfo->stin[4],
			 gSecInfo->stv[5], gSecInfo->strp[5], gSecInfo->stin[5],
			 gSecInfo->stv[6], gSecInfo->strp[6], gSecInfo->stin[6],
			 gSecInfo->stv[7], gSecInfo->strp[7], gSecInfo->stin[7],
			 gSecInfo->stv[8], gSecInfo->strp[8], gSecInfo->stin[8],
			 gSecInfo->stv[9], gSecInfo->strp[9], gSecInfo->stin[9],
			 gSecInfo->stv[10], gSecInfo->strp[10], gSecInfo->stin[10],
			 gSecInfo->stv[11], gSecInfo->strp[11], gSecInfo->stin[11],
			 gSecInfo->stv[12], gSecInfo->strp[12], gSecInfo->stin[12],
			 gSecInfo->stv[13], gSecInfo->strp[13], gSecInfo->stin[13],
			 gSecInfo->stv[14], gSecInfo->strp[14], gSecInfo->stin[14],
			 gSecInfo->stv[15], gSecInfo->strp[15], gSecInfo->stin[15],
			 gSecInfo->stv[16], gSecInfo->strp[16], gSecInfo->stin[16],
			 gSecInfo->stv[17], gSecInfo->strp[17], gSecInfo->stin[17],
			 gSecInfo->stv[18], gSecInfo->strp[18], gSecInfo->stin[18],
			 gSecInfo->stv[19], gSecInfo->strp[19], gSecInfo->stin[19]);
	stw_22(gSecInfo->nsr, gSecInfo->nbr, gSecInfo->rs, gSecInfo->xa, gSecInfo->xb, gSecInfo->xc, gSecInfo->xd);
	
	NSString* pResponse = [NSString stringWithCString:STW_RESPONSE encoding:NSASCIIStringEncoding];
	free(STW_RESPONSE);
	
	return pResponse;
}

@end
