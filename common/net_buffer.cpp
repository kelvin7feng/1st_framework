//
//  net_buffer.cpp
//  client
//
//  Created by 冯文斌 on 17/1/11.
//  Copyright © 2017年 kelvin. All rights reserved.
//

#include <iostream>
#include "google.pb.h"
#include "net_buffer.hpp"

using namespace google;

bool CheckProtobuf(const char* pBuffer, unsigned int uSize)
{
    //测试
    bool bIsOk = true;
    Message msg;
    msg.ParseFromArray(pBuffer + KD_PACKAGE_HEADER_SIZE - KD_PACKAGE_HEADER_SIZE, uSize);
    return bIsOk;
}

unsigned int GetBufferSize(const char* pBuffer)
{
    unsigned int uBufferSize = *(unsigned int*)pBuffer;
    return uBufferSize;
}

unsigned int GetEventType(const char* pBuffer)
{
    unsigned int uEventType = *(unsigned int*)(pBuffer + KD_PACKAGE_HEADER_EVENT_TYPE_START);
    return uEventType;
}

unsigned int GetErrorCode(const char* pBuffer)
{
    unsigned int uErrorCode = *(unsigned int*)(pBuffer + KD_PACKAGE_HEADER_ERROR_CODE_START);
    return uErrorCode;
}

unsigned int GetHandlerId(const char* pBuffer)
{
    unsigned int uHandlerId = *(unsigned int*)(pBuffer + KD_PACKAGE_HEADER_HANDLER_ID_START);
    return uHandlerId;
}

unsigned short GetServerId(const char* pBuffer)
{
    unsigned short uServerId = *(unsigned short*)(pBuffer + KD_PACKAGE_HEADER_SERVER_ID_START);
    return uServerId;
}

unsigned short GetSequenceId(const char* pBuffer)
{
    unsigned short uSquenceId = *(unsigned short*)(pBuffer + KD_PACKAGE_HEADER_SEQUENCE_ID_START);
    return uSquenceId;
}

void AddHanderIdToBuffer(unsigned int nHandlerId, void* pBuffer, unsigned int uSize)
{
    if(uSize > KD_PACKAGE_HEADER_SIZE)
    {
        memcpy((char*)pBuffer + KD_PACKAGE_HEADER_HANDLER_ID_START, &nHandlerId, KD_PACKAGE_UINT_SIZE);
    }
}

void GetNetPackageBody(char* pNetBuffer, unsigned int pNetBufferSize, char** pBodyBuffer, unsigned int* uNetBodySize)
{
    *uNetBodySize = pNetBufferSize - KD_PACKAGE_HEADER_SIZE;
    *pBodyBuffer = pNetBuffer + KD_PACKAGE_HEADER_SIZE;
}

void* CreateNetBuffer(unsigned int uEventType, unsigned int uErrorCode, unsigned int uHandlerId, unsigned short uServerId, unsigned short uSequenceId, const char* pParam, unsigned int uParamSize, unsigned int* uNetBufferSize)
{
    unsigned int uBufferSize = KD_PACKAGE_HEADER_SIZE + uParamSize;
    void* pBuffer = malloc(uBufferSize);
    
    memcpy(pBuffer, &uBufferSize, KD_PACKAGE_UINT_SIZE);
    memcpy((char*)pBuffer + KD_PACKAGE_HEADER_EVENT_TYPE_START, &uEventType, KD_PACKAGE_UINT_SIZE);
    memcpy((char*)pBuffer + KD_PACKAGE_HEADER_ERROR_CODE_START, &uErrorCode, KD_PACKAGE_UINT_SIZE);
    memcpy((char*)pBuffer + KD_PACKAGE_HEADER_HANDLER_ID_START, &uHandlerId, KD_PACKAGE_UINT_SIZE);
    memcpy((char*)pBuffer + KD_PACKAGE_HEADER_SERVER_ID_START, &uServerId, KD_PACKAGE_USHORT_SIZE);
    memcpy((char*)pBuffer + KD_PACKAGE_HEADER_SEQUENCE_ID_START, &uSequenceId, KD_PACKAGE_USHORT_SIZE);
    memcpy((char*)pBuffer + KD_PACKAGE_HEADER_SIZE, pParam, uParamSize);
    
    *uNetBufferSize = uBufferSize;
    
    return pBuffer;
}
