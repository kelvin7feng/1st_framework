//
//  net_buffer.hpp
//  client
//
//  Created by 冯文斌 on 17/1/11.
//  Copyright © 2017年 kelvin. All rights reserved.
//

#ifndef net_buffer_hpp
#define net_buffer_hpp

#define KD_PACKAGE_UINT_SIZE sizeof(unsigned int)
#define KD_PACKAGE_USHORT_SIZE sizeof(unsigned short)
#define KD_PACKAGE_HEADER_EVENT_TYPE_START sizeof(unsigned int)
#define KD_PACKAGE_HEADER_ERROR_CODE_START sizeof(unsigned int) * 2
#define KD_PACKAGE_HEADER_HANDLER_ID_START sizeof(unsigned int) * 3
#define KD_PACKAGE_HEADER_SERVER_ID_START sizeof(unsigned int) * 4
#define KD_PACKAGE_HEADER_SEQUENCE_ID_START sizeof(unsigned int) * 4 + KD_PACKAGE_USHORT_SIZE
#define KD_PACKAGE_HEADER_SIZE (sizeof(unsigned int) * 4 + KD_PACKAGE_USHORT_SIZE * 2)

struct NET_PACKAGE_HEADER
{
    unsigned int uPacketLength;
    unsigned int uEventType;
    unsigned int uErrorCode;
    unsigned int uHandlerId;
    unsigned short uServerId;
    unsigned short uSequenceId;
};

bool CheckProtobuf(const char* pBuffer, unsigned int uSize);

unsigned int GetBufferSize(const char* pBuffer);

unsigned int GetEventType(const char* pBuffer);

unsigned int GetErrorCode(const char* pBuffer);

unsigned int GetHandlerId(const char* pBuffer);

unsigned short GetServerId(const char* pBuffer);

unsigned short GetSequenceId(const char* pBuffer);

void AddHanderIdToBuffer(unsigned int nHandlerId, void* pBuffer, unsigned int uSize);

void GetNetPackageBody(char* pNetBuffer, unsigned int pNetBufferSize, char** pBodyBuffer, unsigned int* uNetBodySize);

void* CreateNetBuffer(unsigned int uEventType, unsigned int uErrorCode, unsigned int uHandlerId, unsigned short uServerId, unsigned short uSequenceId, const char* pParam, unsigned int uParamSize, unsigned int* uNetSize);

#endif /* net_buffer_hpp */
