//
//  tcp_session.cpp
//  server
//
//  Created by 冯文斌 on 16/10/8.
//  Copyright © 2016年 冯文斌. All rights reserved.
//

#include "kmacros.h"
#include "net_buffer.hpp"
#include "tcp_session.hpp"
#include "gateway_client.hpp"

TCPSession::TCPSession()
{
    m_pRecvPacket = KG_CreateCommonPackage();
}

TCPSession::~TCPSession()
{
    
}

unsigned int TCPSession::GetHandlerId()
{
    return m_uHandlerId;
}

void TCPSession::SetHandlerId(unsigned int uHandlerId)
{
    m_uHandlerId = uHandlerId;
}

bool TCPSession::ProcessNetData(const char* pData, size_t uRead)
{
    bool bResult = false;
    unsigned int uWrite = 0;
    if(!(pData && uRead > 0))
        goto Exit0;
    do
    {
        _ASSERT(m_pRecvPacket);
        if(!(m_pRecvPacket->Write(pData, (unsigned int)uRead, &uWrite)))
            goto Exit0;
        if (m_pRecvPacket->IsValid())
        {
            IKG_Buffer* pBuffer = NULL;
            bool bRet = m_pRecvPacket->GetData(&pBuffer);
            if(!(bRet && pBuffer))
                goto Exit0;
            
            char* pDataBuffer = (char*)pBuffer->GetData();
            unsigned int uDataBufferSize = pBuffer->GetSize();
            if(m_pRecvPacket->CheckNetPacket(pDataBuffer, uDataBufferSize))
            {
                unsigned int uHandlerId = GetHandlerId();
                AddHanderIdToBuffer(uHandlerId, pDataBuffer, uDataBufferSize);
                GatewayClient* pGamewayClientToLogic = GatewayClient::GetInstance();
                pGamewayClientToLogic->TransferToLogicServer(pDataBuffer, uDataBufferSize);
                std::cout << "protobuf is legal..." << std::endl;
            } else {
                std::cout << "protobuf is illegal..." << std::endl;
            }
            
            SAFE_DELETE(pBuffer);
            m_pRecvPacket->Reset();
        }
        pData += uWrite;
        uRead -= uWrite;
        if (uRead > 0)
            continue;
        break;
    } while (true);
    bResult = true;
Exit0:
    return bResult;
}