#ifndef __COMMON_KNETPACKAGE_H__
#define __COMMON_KNETPACKAGE_H__

#include "db_buffer.h"

class IKNetPacket
{
public:
	virtual ~IKNetPacket() {}
	virtual bool GetData(IKG_Buffer** ppBuffer) const = 0;
    virtual unsigned int GetEventType(void* pBuffer) const = 0;
    virtual unsigned int GetHandlerId(void* pBuffer) const = 0;
	virtual bool IsValid() const = 0;
	virtual bool Reset() = 0;
    virtual bool CheckNetPacket(char* pData, unsigned int uSize) = 0;
	//************************************
	// Method:    Write
	// FullName:  IKNetPackage::Write
	// Access:    virtual public 
	// Returns:   bool true:д��ɹ� false:д������ʧ��
	// Qualifier: 
	// Parameter: const char * pData д�������ָ��
	// Parameter: unsigned int uDataLen	���ݳ���
	// Parameter: unsigned int * puWrite ��ʵд��ĳ���
	//************************************
	virtual bool Write(const char* pData, unsigned int uDataLen, unsigned int* puWrite) = 0;
};

IKNetPacket* KG_CreateCommonPackage();

#endif
