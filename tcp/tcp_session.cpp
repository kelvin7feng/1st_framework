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
#include "center_server.hpp"

GatewayClient* g_pLoginLogicClient = NULL;
GatewayClient* g_pGameLogicClient = NULL;
GatewayClient* g_pRoomLogicClient = NULL;
CenterClient* g_pCenterLogicClient = NULL;

TCPSession::TCPSession()
{
    m_pRecvPacket = KG_CreateCommonPackage();
}

TCPSession::~TCPSession()
{
    //SAFE_FREE(m_pRecvPacket);
    //std::cout << "TCPSession::~TCPSession()" << std::endl;
}

unsigned int TCPSession::GetHandlerId()
{
    return m_uHandlerId;
}

void TCPSession::SetHandlerId(unsigned int uHandlerId)
{
    m_uHandlerId = uHandlerId;
}

GatewayClient* TCPSession::GetGatewayClient(unsigned short uServerId)
{
    GatewayClient* pClient = NULL;
    if(uServerId == LOGIN)
    {
        pClient = g_pLoginLogicClient;
    }
    else if(uServerId == LOGIC)
    {
        pClient = g_pGameLogicClient;
    }
    else if(uServerId == ROOM)
    {
        pClient = g_pRoomLogicClient;
    }
    
    return pClient;
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
                unsigned short uServerId = GetServerId(pDataBuffer);
                GatewayClient* pClient = GetGatewayClient(uServerId);
                pClient->TransferToLogicServer(pDataBuffer, uDataBufferSize);
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

bool TCPSession::CenterServerProcessNetData(const char* pData, size_t uRead)
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
                unsigned short uServerId = GetServerId(pDataBuffer);
                std::cout << "protobuf is legal..." << std::endl;

                if(uServerId == CENTER)
                {
                    std::cout << "send to center deal..." << std::endl;
                    char* pNetBodyBuffer = NULL;
                    unsigned int uNetBodySize = 0;
                    unsigned int uHandlerId = GetHandlerId();
                    unsigned int uEventType = GetEventType(pDataBuffer);
                    GetNetPackageBody(pDataBuffer, pBuffer->GetSize(), &pNetBodyBuffer, &uNetBodySize);
                    
                    Message msg;
                    bool bIsOk = msg.ParseFromArray(pNetBodyBuffer, uNetBodySize);
                    if(bIsOk)
                    {
                        std::cout << "VM deal..." << std::endl;
                        CenterServer* pCenterServer = CenterServer::GetInstance();
                        pCenterServer->CallLua(uHandlerId, uEventType, msg.data().c_str());
                    }
                } else {
                    unsigned int uHandlerId = CenterServer::GetInstance()->GetServerTypeToHandler(uServerId);
                    CenterServer::GetInstance()->TransferToClient(uHandlerId, pDataBuffer, uDataBufferSize);
                    std::cout << "should transfer to other server..." << uServerId << std::endl;
                }
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