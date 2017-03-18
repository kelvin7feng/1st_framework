//
//  center_client.cpp
//  server
//
//  Created by 冯文斌 on 17/2/22.
//  Copyright © 2017年 kelvin. All rights reserved.
//

#include "kmacros.h"
#include "google.pb.h"
#include "net_buffer.hpp"
#include "tcp_session.hpp"
#include "center_client.hpp"
#include "game_logic_server.hpp"

using namespace google;

CenterClient::CenterClient()
{
    
}

CenterClient::~CenterClient()
{
    
}

CenterClient* CenterClient::GetInstance()
{
    static CenterClient client;
    return &client;
}

CenterClient::CenterClient(const CenterClient& CenterClient){
    
}

int CenterClient::Init(uv_loop_t* loop, const char* ip, int port, int nServerType)
{
    SetIp(ip);
    SetPort(port);
    SetLoop(loop);
    SetSeverType(nServerType);
    
    uv_tcp_init(loop, &m_client);
    uv_ip4_addr(ip, port, &m_dest);
    int ret = uv_tcp_connect(&m_connect_req, &m_client, (const struct sockaddr*)&m_dest,
                             [](uv_connect_t *req, int status)
                             {
                                 CenterClient::GetInstance()->OnConnect(req, status);
                             });
    
    if(ret < 0)
    {
        cout << "client connect error: " << ip << ":" << port << endl;
        exit(1);
    }
    
    if(ret == 0)
    {
        cout << "client connect to " << ip << ":" << port << " succeed"<< endl;
    }
    
    return ret;
}

void CenterClient::RegisterToCenter()
{
    
    Message msg;
    char* buffer = new char[100];
    int n = sprintf(buffer, "[\"%s\", 8001, %d]", GetIp(), GetSeverType());
    msg.set_data(buffer, n);
    std::string str;
    msg.SerializeToString(&str);
    SendNetPacket(CENTER, 3001, str.c_str(), (unsigned int)str.length());
    SAFE_DELETE_ARRAY(buffer);
}

void CenterClient::SendNetPacket(unsigned short uServerId, unsigned int uEventType, const char* pBuffer, unsigned int uMsgSize){
    
    unsigned int uErrorCode = 0;
    unsigned int uHandlerId = 0;
    unsigned int uPacketLen = 0;
    unsigned short uSequenceId = 0;
    void* pvNetBuffer = CreateNetBuffer(uEventType, uErrorCode, uHandlerId, uServerId, uSequenceId, pBuffer, uMsgSize, &uPacketLen);
    
    TransferToCenterServer((char*)pvNetBuffer, uPacketLen);
    SAFE_DELETE(pvNetBuffer);
}

void CenterClient::OnConnect(uv_connect_t *pServer, int nStatus) {
    
    if (nStatus < 0) {
        cout << "CenterClient connect error: " << uv_strerror(nStatus) << endl;
        exit(1);
    }
    
    if (nStatus == -1) {
        fprintf(stderr, "error CenterClient OnConnect");
        return;
    }
    
    int iret = uv_read_start(pServer->handle, AllocBuffer,
                             [](uv_stream_t* req, ssize_t nread, const uv_buf_t *buf)
                             {
                                 CenterClient::GetInstance()->OnMsgRecv(req, nread, buf);
                             });
    
    if(!iret)
    {
        //尝试重连
    }

    //发送注册请求
    g_pCenterLogicClient->RegisterToCenter();
}

void CenterClient::OnMsgRecv(uv_stream_t* pServer, ssize_t nread, const uv_buf_t *buf)
{
    if (nread == UV_EOF)
    {
        cout << "Server Disconnected" << endl;
    }
    else if (nread > 0)
    {
        GameLogicServer::GetInstance()->_ProcessNetData(buf->base, (unsigned int)nread, CENTER);
    }
    
    free(buf->base);
}

//转发函数
void CenterClient::TransferToCenterServer(const char* pBuffer, ssize_t nRead){
    
    char* pvBuffer = NULL;
    pvBuffer = (char*)malloc(nRead);
    memcpy(pvBuffer, pBuffer, nRead);
    
    uv_write_t* pWriteReq = new uv_write_t;
    
    uv_buf_t buf = uv_buf_init(pvBuffer, (unsigned int)nRead);
    int nRet = uv_write(pWriteReq, (uv_stream_t*)&m_client, &buf, 1,
                        [](uv_write_t *req, int status)
                        {
                            CenterClient::GetInstance()->OnTransferToCenterServer(req, status);
                        });
    if(nRet != 0)
    {
        cout << "transfer to center server failed.." << endl;
        SAFE_DELETE(pWriteReq);
    }
    
    SAFE_FREE(pvBuffer);
}

//转发到服务端的回调
void CenterClient::OnTransferToCenterServer(uv_write_t *pReq, int nStatus){
    if (nStatus < 0) {
        cout << "TCP Client write error: " << uv_strerror(nStatus) << endl;
        return;
    }
    
    if (nStatus == 0) {
        cout << "transfer to center succeed!" << endl;
    }
    
    SAFE_DELETE(pReq);
}

bool CenterClient::_ProcessNetData(const char* pData, size_t uRead)
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
            unsigned int uBufferSize = pBuffer->GetSize();
            unsigned int uHandlerId = GetHandlerId(pDataBuffer);
            if(uHandlerId > 0)
            {
                //to do: 丢到逻辑服的虚拟机处理
                cout << "waiting vm to deal ..." << endl;
            } else {
                cout << "handler is not exist..." << endl;
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

void CenterClient::SetSeverType(int nServerType)
{
    m_nServerType = nServerType;
}

int CenterClient::GetSeverType()
{
    return m_nServerType;
}