#include "kmacros.h"
#include "net_buffer.hpp"
#include "knetpacket.h"
#include "google.pb.h"

#include <memory.h>

using namespace google;

class KNetPackage : public IKNetPacket
{
public:
	KNetPackage();
	virtual ~KNetPackage();
	virtual bool GetData(IKG_Buffer** ppBuffer) const;
    virtual unsigned int GetEventType(void* pBuffer) const;
    virtual unsigned int GetHandlerId(void* pBuffer) const;
	virtual bool Write(const char* pData, unsigned int uDataLen, unsigned int* puWrite);
	virtual bool IsValid() const { return m_uRecvOffset == m_uPacketLen; }
	virtual bool Reset();
    virtual bool CheckNetPacket(char* pData, unsigned int uSize);
private:
	bool _InitPackage(unsigned int uPackageSize);
	bool _WriteData(const char* pData, unsigned int uSize);
private:
	char m_szRemain[KD_PACKAGE_LEN_SIZE];	
	unsigned int m_uPacketLen;
	unsigned int m_uRecvOffset;
	IKG_Buffer* m_pBuffer;
};

IKNetPacket* KG_CreateCommonPackage()
{
	IKNetPacket* pPackage = new KNetPackage;
	return pPackage;
}

KNetPackage::KNetPackage() :
	m_uPacketLen(KD_INVALID_PACKET_LEN),
	m_uRecvOffset(0),
	m_pBuffer(NULL)
{
	memset(m_szRemain, 0, sizeof(m_szRemain));
}

KNetPackage::~KNetPackage()
{
	SAFE_RELEASE(m_pBuffer);
}

bool KNetPackage::GetData(IKG_Buffer** ppBuffer) const
{
	bool bResult = false;
	//KGLOG_PROCESS_ERROR(ppBuffer);
	//KG_PROCESS_ERROR(IsValid());
	//KGLOG_PROCESS_ERROR(m_pBuffer);
    if(!IsValid())
        goto Exit0;
	*ppBuffer = m_pBuffer;
	bResult = true;
Exit0:
	return bResult;
}

unsigned int KNetPackage::GetEventType(void *pBuffer) const
{
    unsigned int uEventType = *(unsigned int*)((char*)pBuffer);
    return uEventType;
}

unsigned int KNetPackage::GetHandlerId(void *pBuffer) const
{
    unsigned int uHandlerId = *(unsigned int*)((char*)pBuffer + sizeof(unsigned int) * 2);
    return uHandlerId;
}

bool KNetPackage::Write(const char* pData, unsigned int uDataLen, unsigned int* puWrite)
{
	bool bResult = false;
	bool bRet = false;
	int nRet = 0;
	unsigned int uPackageLen = 0;
	unsigned int uMaxWriteLen = 0;
	unsigned int uCurWriteLen = 0;
    if(m_uPacketLen == m_uRecvOffset)
        goto Exit1;
	*puWrite = 0;
	
    //如果没有接够头的长度，需要先把长度读取出来
	if (m_uRecvOffset < KD_PACKAGE_LEN_SIZE)
	{
		for (int i = m_uRecvOffset; i < KD_PACKAGE_LEN_SIZE; ++i)
		{
			m_szRemain[m_uRecvOffset++] = *pData++;
			++uCurWriteLen;
			if (m_uRecvOffset == KD_PACKAGE_LEN_SIZE)
			{
				bRet = _InitPackage(*(unsigned int*)m_szRemain);
			}
            if(uCurWriteLen == uDataLen)
                goto Exit1;
		}
        if(uCurWriteLen == uDataLen)
            goto Exit1;
	}
	if (m_uRecvOffset < m_uPacketLen)
	{
		uMaxWriteLen = uDataLen - uCurWriteLen;
		uMaxWriteLen = uMaxWriteLen < (m_uPacketLen - m_uRecvOffset) ? uMaxWriteLen : (m_uPacketLen - m_uRecvOffset);
        if(!_WriteData(pData, uMaxWriteLen))
            goto Exit1;
		uCurWriteLen += uMaxWriteLen;
	}
Exit1:
	*puWrite = uCurWriteLen;
	bResult = true;
Exit0:
	return bResult;
}

bool KNetPackage::Reset()
{
	m_uPacketLen = KD_INVALID_PACKET_LEN;
	m_uRecvOffset = 0;
	SAFE_RELEASE(m_pBuffer);
	return true;
}

bool KNetPackage::_InitPackage(unsigned int uPacketSize)
{
	bool bResult = false;
    //KGLOG_PROCESS_ERROR(m_pBuffer == NULL);
	//KGLOG_PROCESS_ERROR(uPacketSize > KD_PACKAGE_LEN_SIZE);
	//KGLOG_PROCESS_ERROR(KD_INVALID_PACKET_LEN != uPacketSize);
	m_uPacketLen = uPacketSize;
	//m_pBuffer = DB_MemoryCreateBuffer(uPacketSize - KD_PACKAGE_LEN_SIZE);
    m_pBuffer = DB_MemoryCreateBuffer(uPacketSize);
    memcpy(m_pBuffer->GetData(), &uPacketSize, sizeof(unsigned int));
	//KGLOG_PROCESS_ERROR(m_pBuffer);
	bResult = true;
Exit0:
	return bResult;
}

bool KNetPackage::_WriteData(const char* pData, unsigned int uSize)
{
	bool bResult = false;
	//KGLOG_PROCESS_ERROR(pData);
	//KGLOG_PROCESS_ERROR(uSize > 0);
	//KGLOG_PROCESS_ERROR(m_uRecvOffset + uSize <= m_uPacketLen);
	//KGLOG_PROCESS_ERROR(m_pBuffer);
	//memcpy((char *)m_pBuffer->GetData() + (m_uRecvOffset - KD_PACKAGE_LEN_SIZE), pData, uSize);
    memcpy((char *)m_pBuffer->GetData() + m_uRecvOffset, pData, uSize);
	m_uRecvOffset += uSize;
	bResult = true;
Exit0:
	return bResult;
}

bool KNetPackage::CheckNetPacket(char* pData, unsigned int uSize)
{
    char* pBodyBuffer = NULL;
    unsigned int uNetBodySize = 0;
    GetNetPackageBody(pData, uSize, &pBodyBuffer, &uNetBodySize);
    
    Message msg;
    bool bIsOk = msg.ParseFromArray(pBodyBuffer, uNetBodySize);
    return bIsOk;
}