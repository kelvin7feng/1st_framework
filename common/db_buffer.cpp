//
//  db_buffer.cpp
//  thread
//
//  Created by 冯文斌 on 16/12/7.
//  Copyright © 2016年 kelvin. All rights reserved.
//

#include <new>
#include <stdlib.h>
#include <stdio.h>
#include <iostream>
#include "kmacros.h"
#include "db_def.h"
#include "db_buffer.h"
#include "krequest_def.h"
#include "kg_interlockedvariable.h"

#define MEMORY_BUFFER_RESERVE_SIZE   8

class KG_Buffer : public IKG_Buffer
{
public:
    KG_Buffer(unsigned int uSize, void* pvData);
    ~KG_Buffer();
    
    virtual long AddRef();
    virtual long Release();
    virtual void* GetData() {return m_pvData;}
    virtual const void* GetData() const {return m_pvData;}
    virtual unsigned int GetSize() {return m_uSize;}
    virtual unsigned int GetReserveSize() {return MEMORY_BUFFER_RESERVE_SIZE;}
    virtual void* GetReserveData() {return (char*)m_pvData - MEMORY_BUFFER_RESERVE_SIZE;}
    
private:
    volatile long   m_lRefCount;
    unsigned int    m_uOriginSize;
    
    unsigned int    m_uSize;
    void*           m_pvData;
};

KG_Buffer::KG_Buffer(unsigned int uSize, void* pvData) : m_lRefCount(1), m_uOriginSize(uSize), m_uSize(uSize), m_pvData(pvData)
{
    
}

KG_Buffer::~KG_Buffer()
{
    
}

long KG_Buffer::AddRef()
{
    return KG_InterlockedIncrement((long*)&m_lRefCount);
}

long KG_Buffer::Release()
{
    long lRefNow = KG_InterlockedDecrement((long*)&m_lRefCount);
    if (lRefNow > 0)
        goto Exit0;
    if (lRefNow < 0)
    {
        _ASSERT(false);
        printf("Err: Bad use of memory block : Unexpected memory release!");
    }
    
    this->~KG_Buffer();
    free((void*)this);
Exit0:
    return lRefNow;
}

void DB_SetBufferHead(IKG_Buffer* pBuffer, unsigned int uUserId, unsigned int uEventType)
{
    KREQUEST_HEAD* pResond = (KREQUEST_HEAD*)pBuffer->GetData();
    pResond->uUserId = uUserId;
    pResond->uEventType = uEventType;
}

void DB_SetCommonHead(IKG_Buffer* pBuffer, unsigned int uUserId, unsigned int uEventType)
{
    KRESOOND_COMMON* pResond = (KRESOOND_COMMON*)pBuffer->GetData();
    pResond->uUserId = uUserId;
    pResond->uEventType = uEventType;
}

void DB_SetMulDataHead(IKG_Buffer* pBuffer, unsigned int uUserId, unsigned int uEventType)
{
    KP_DBRESPOND_MULTI_DATA* pResond = (KP_DBRESPOND_MULTI_DATA*)((char*)pBuffer->GetData() + 1);
    pResond->uUserId = uUserId;
    pResond->uEventType = uEventType;
}

IKG_Buffer* DB_MemoryCreateBuffer(unsigned int uSize)
{
    KG_Buffer* pBuffer = NULL;
    unsigned int uBufferSize = 0;
    void* pvBuffer = NULL;
    void* pvData = NULL;
    
    uBufferSize = uSize + sizeof(KG_Buffer) + MEMORY_BUFFER_RESERVE_SIZE;
    pvBuffer = malloc(uBufferSize);
    
    pvData = (void *)(((unsigned char *)pvBuffer) + sizeof(KG_Buffer) + MEMORY_BUFFER_RESERVE_SIZE);
    pBuffer = new(pvBuffer)KG_Buffer(uSize, pvData);
    
    return pBuffer;
}

IKG_Buffer* DB_CreateRedisExpireBuffer(const std::string& szKey, int nSecond)
{
    int nSize = (int)(sizeof(KREQUEST_EXPIRE) + szKey.length());
    IKG_Buffer* pBuffer = DB_MemoryCreateBuffer(nSize);
    KREQUEST_EXPIRE* pRequest = (KREQUEST_EXPIRE*)pBuffer->GetData();
    pRequest->nExpire = nSecond;
    pRequest->byType = KE_REQUEST_TYPE::emREQUEST_AUTO_EXPIRE;
    memcpy(pRequest->data, szKey.c_str(), szKey.length());
    
    return pBuffer;
}

IKG_Buffer* DB_CreateSetBuffer(const std::string& szTable, const std::string& szKey, const std::string& szValue)
{
    int nSize = (int)(sizeof(KREQUEST_SET) + szKey.length() + szValue.length());
    IKG_Buffer* pBuffer = DB_MemoryCreateBuffer(nSize);
    KREQUEST_SET* pRequest = (KREQUEST_SET*)pBuffer->GetData();
    pRequest->uPrefixLen = (unsigned int)szTable.length();
    pRequest->uKeyLen = (unsigned int)szKey.length();
    pRequest->uValueLen = (unsigned int)szValue.length();
    pRequest->byType = KE_REQUEST_TYPE::emREQUEST_SET;
    memcpy(pRequest->data, szTable.c_str(), szTable.length());
    memcpy(pRequest->data + szTable.length(), REQUEST_KEY_UNDERLINED, REQUEST_KEY_UNDERLINED_LEN);
    memcpy(pRequest->data + szTable.length() + REQUEST_KEY_UNDERLINED_LEN, szKey.c_str(), szKey.length());
    memcpy(pRequest->data + szTable.length() + szKey.length() + REQUEST_KEY_UNDERLINED_LEN, szValue.c_str(), szValue.length());
    
    //printf("-----------------------DB_CreateSetBuffer %p\r\n", pBuffer);
    return pBuffer;
}

IKG_Buffer* DB_CreateGetBuffer(const std::string& szTable, const std::string& szKey)
{
    int nSize = (int)(sizeof(KREQUEST_GET) + szKey.length());
    IKG_Buffer* pBuffer = DB_MemoryCreateBuffer(nSize);
    KREQUEST_GET* pRequest = (KREQUEST_GET*)pBuffer->GetData();
    pRequest->uPrefixLen = (unsigned int)szTable.length();
    pRequest->uKeyLen = (unsigned int)szKey.length();
    pRequest->byType = KE_REQUEST_TYPE::emREQUEST_GET;
    memcpy(pRequest->data, szTable.c_str(), szTable.length());
    memcpy(pRequest->data + szTable.length(), REQUEST_KEY_UNDERLINED, REQUEST_KEY_UNDERLINED_LEN);
    memcpy(pRequest->data + szTable.length() + REQUEST_KEY_UNDERLINED_LEN, szKey.c_str(), szKey.length());
    
    return pBuffer;
}

IKG_Buffer* DB_CreateGetsBuffer(const std::string& szKeys)
{
    int nSize = (int)(sizeof(KREQUEST_GETS) + szKeys.length());
    IKG_Buffer* pBuffer = DB_MemoryCreateBuffer(nSize);
    KREQUEST_GETS* pRequest = (KREQUEST_GETS*)pBuffer->GetData();
    pRequest->uHashKeyLen = (unsigned int)szKeys.length();
    pRequest->byType = KE_REQUEST_TYPE::emREQUEST_GETS;
    memcpy(pRequest->data, szKeys.c_str(), szKeys.length());
    pRequest->data[szKeys.length()+1] = '\0';
    
    return pBuffer;
}

IKG_Buffer* DB_CreateHSetBuffer(const std::string& szKey, const std::string& szField, const std::string& szValue)
{
    int nSize = (int)(sizeof(KREQUEST_HSET) + szKey.length() + szField.length() + szValue.length());
    IKG_Buffer* pBuffer = DB_MemoryCreateBuffer(nSize);
    KREQUEST_HSET* pRequest = (KREQUEST_HSET*)pBuffer->GetData();
    
    pRequest->byType = KE_REQUEST_TYPE::emREQUEST_HSET;
    pRequest->uTableNameLen = (unsigned int)szKey.length();
    pRequest->uHashKeyLen = (unsigned int)szField.length();
    pRequest->uValueLen = (unsigned int)szValue.length();
    
    memcpy(pRequest->data, szKey.c_str(), szKey.length());
    memcpy(pRequest->data + szKey.length(), szField.c_str(), szField.length());
    memcpy(pRequest->data + szKey.length() + szField.length(), szValue.c_str(),  szValue.length());
    
    return pBuffer;
}

IKG_Buffer* DB_CreateHgetBuffer(const std::string& szKey, const std::string& szField)
{
    int nSize = (int)(sizeof(KREQUEST_HGET) + szKey.length() + szField.length());
    IKG_Buffer* pBuffer = DB_MemoryCreateBuffer(nSize);
    KREQUEST_HGET* pRequest = (KREQUEST_HGET*)pBuffer->GetData();
    
    pRequest->bAllowRedisNil = false;
    pRequest->byType = KE_REQUEST_TYPE::emREQUEST_HGET;
    pRequest->uTableNameLen = (unsigned int)szKey.length();
    pRequest->uHashKeyLen = (unsigned int)szField.length();
    
    memcpy(pRequest->data, szKey.c_str(), szKey.length());
    memcpy(pRequest->data + szKey.length(), szField.c_str(), szField.length());
    
    return pBuffer;
}

IKG_Buffer* DB_CreateDelBuffer(const std::string& szTable, const std::string& szKey)
{
    int nSize = (int)(sizeof(KREQUEST_DEL) + szKey.length());
    IKG_Buffer* pBuffer = DB_MemoryCreateBuffer(nSize);
    KREQUEST_DEL* pRequest = (KREQUEST_DEL*)pBuffer->GetData();
    pRequest->uPrefixLen = (unsigned int)szTable.length();
    pRequest->uKeyLen = (unsigned int)szKey.length();
    pRequest->byType = KE_REQUEST_TYPE::emREQUEST_DEL;
    memcpy(pRequest->data, szTable.c_str(), szTable.length());
    memcpy(pRequest->data + szTable.length(), REQUEST_KEY_UNDERLINED, REQUEST_KEY_UNDERLINED_LEN);
    memcpy(pRequest->data + szTable.length() + REQUEST_KEY_UNDERLINED_LEN, szKey.c_str(), szKey.length());
    
    return pBuffer;
}

IKG_Buffer* DB_CreateHdelBuffer(const std::string& szTable, const std::string& szKey)
{
    int nSize = (int)(sizeof(KREQUEST_HDEL) + szTable.length() + szKey.length());
    IKG_Buffer* pBuffer = DB_MemoryCreateBuffer(nSize);
    KREQUEST_HDEL* pRequest = (KREQUEST_HDEL*)pBuffer->GetData();
    
    pRequest->bAllowRedisNil = false;
    pRequest->byType = KE_REQUEST_TYPE::emREQUEST_HDEL;
    pRequest->uTableNameLen = (unsigned int)szTable.length();
    pRequest->uHashKeyLen = (unsigned int)szKey.length();
    
    memcpy(pRequest->data, szTable.c_str(), szTable.length());
    memcpy(pRequest->data + szTable.length(), szKey.c_str(), szKey.length());
    
    return pBuffer;
}