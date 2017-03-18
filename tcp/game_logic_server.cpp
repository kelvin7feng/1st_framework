//
//  game_logic_server.cpp
//  server
//
//  Created by 冯文斌 on 16/10/10.
//  Copyright © 2016年 kelvin. All rights reserved.
//

#include <exception>

#include "kmacros.h"
#include "document.h"
#include "file_util.h"
#include "db_def.h"
#include "net_buffer.hpp"
#include "db_client_manager.hpp"
#include "game_logic_server.hpp"

using namespace rapidjson;

static void OnUVTimer(uv_timer_t *handle) {
    g_pDBClientMgr->Activate();
}

GameLogicServer::GameLogicServer()
{
    
}

GameLogicServer::~GameLogicServer()
{
    
    cout << "Server Terminated" << endl;
}

GameLogicServer* GameLogicServer::GetInstance()
{
    static GameLogicServer server;
    return &server;
}

int GameLogicServer::Init(uv_loop_t* loop)
{
    string sz_config;
    bool is_ok = g_pFileUtil->ReadFile("config.json", sz_config);
    if(!is_ok)
    {
        cout << "read config failed." << endl;
        return 0;
    }
    
    Document json_doc;
    json_doc.Parse(sz_config.c_str());
    
    const Value& server_config = json_doc["listen"];
    string sz_ip = server_config["ip"].GetString();
    int port = server_config["port"].GetInt();
    const char* ip = sz_ip.c_str();
    
    SetIp(ip);
    SetPort(port);
    SetLoop(loop);
    
    uv_tcp_t& server = GetTcpServerHandler();
    uv_tcp_init(loop, &server);
    
    sockaddr_in& addr = GetSockAddrIn();
    uv_ip4_addr(ip, port, &addr);
    
    uv_tcp_bind(&server, (const struct sockaddr*)&addr, 0);
    
    int r = uv_listen((uv_stream_t*) &server, GetDefaultBackLog(),
                      [](uv_stream_t* server, int status)
                      {
                          GameLogicServer::GetInstance()->OnNewConnection(server, status);
                      });
    
    if (r) {
        fprintf(stderr, "Listen error %s: %s:%d\n", uv_strerror(r), ip, port);
        exit(1);
    }
    
    cout << "logic server listen: " << ip << ":" << port << endl;
    
    //数据管理定时器
    uv_timer_init(loop, &m_db_timer_req);
    uv_timer_start(&m_db_timer_req, OnUVTimer, 0, 100);
    
    int nLogicServerType = json_doc["logic_server_type"].GetInt();
    lua_engine.InitState(nLogicServerType);
    
    return 1;
}

void GameLogicServer::OnMsgRecv(uv_stream_t* client, ssize_t nread, const uv_buf_t *buf)
{
    session_map_t& open_sessions = GetSessionMap();
    auto connection_pos = open_sessions.find(client);
    if (connection_pos != open_sessions.end())
    {
        if (nread == UV_EOF)
        {
            cout << "Client Disconnected" << endl;
            RemoveClient(client);
        }
        else if (nread > 0)
        {
            _ProcessNetData(buf->base, nread, GATEWAY);
        }
        
        free(buf->base);
        
    }
    else
    {
        uv_read_stop(client);
        cout << "Unrecognized client. Disconnecting." << endl;;
    }
}

void GameLogicServer::RemoveClient(uv_stream_t* client)
{
    session_map_t& open_sessions = GetSessionMap();
    auto connection_pos = open_sessions.find(client);
    if (connection_pos != open_sessions.end())
    {
        uv_close((uv_handle_t*)connection_pos->second->connection.get(),
                 [] (uv_handle_t* handle)
                 {
                     GameLogicServer::GetInstance()->OnConnectionClose(handle);
                 });
        
    }
}

void GameLogicServer::OnConnectionClose(uv_handle_t* handle)
{
    session_map_t& open_sessions = GameLogicServer::GetInstance()->GetSessionMap();
    open_sessions.erase((uv_stream_t*)handle);
}

void GameLogicServer::OnNewConnection(uv_stream_t *server, int status)
{
    if (status < 0) {
        fprintf(stderr, "New connection error %s\n", uv_strerror(status));
        return;
    }
    
    TCPSession* new_session = new TCPSession;
    new_session->connection = std::make_shared<uv_tcp_t>();
    
    uv_tcp_init(GetLoop(), new_session->connection.get());
    if (uv_accept(server, (uv_stream_t*)new_session->connection.get()) == 0) {
        
        uv_read_start((uv_stream_t*)new_session->connection.get(),
                      [](uv_handle_t* stream, size_t nread, uv_buf_t *buf)
                      {
                          GameLogicServer::GetInstance()->AllocBuffer(stream, nread, buf);
                      },
                      [](uv_stream_t* stream, ssize_t nread, const uv_buf_t* buf)
                      {
                          GameLogicServer::GetInstance()->OnMsgRecv(stream, nread, buf);
                      });
        
        m_pGatewayClient = (uv_stream_t*)new_session->connection.get();
        AddSession(new_session);
        
    }
    else {
        uv_close((uv_handle_t*)new_session->connection.get(), NULL);
    }
}

void GameLogicServer::SendDataToGateway(const char *pBuffer, unsigned int uSize)
{
    char* pvBuffer = NULL;
    pvBuffer = (char*)malloc(uSize);
    memcpy(pvBuffer, pBuffer, uSize);
    uv_buf_t pUvBuf = uv_buf_init(pvBuffer, uSize);
    
    uv_write_t* pWriteReq = new uv_write_t;
    
    int nRet = uv_write(pWriteReq, m_pGatewayClient, &pUvBuf, 1,
             [](uv_write_t *pReq, int nStatus)
             {
                 GameLogicServer::GetInstance()->OnSendData(pReq, nStatus);
             });
    
    cout << "send data to gateway, uv write error code:" << nRet << endl;
    
    if(nRet != 0)
    {
        SAFE_DELETE(pWriteReq);
    }
    
    SAFE_FREE(pvBuffer);
}

void GameLogicServer::OnSendData(uv_write_t *pReq, int nStatus){
    
    if (nStatus == -1) {
        fprintf(stderr, "error OnSendData");
        return;
    }
    
    if (nStatus == 0) {
        cout << "send to client succeed!" << endl;
    }
    
    SAFE_DELETE(pReq);
}

void GameLogicServer::OnDBResponse(KRESOOND_COMMON* pCommonResponse)
{
    //调用lua处理回调
    int nDataLen = pCommonResponse->nDataLen;
    if(nDataLen < 0)
        nDataLen = 0;
    char* szData = new char[nDataLen+1];
    memset(szData, 0, (size_t)(nDataLen + 1));
    memcpy(szData, pCommonResponse->data, (size_t)nDataLen);
    lua_engine.RedisCallLua(pCommonResponse->uUserId, pCommonResponse->uEventType, szData);
    
    delete[] szData;
}

void GameLogicServer::OnDBResponse(KP_DBRESPOND_MULTI_DATA* pMulDataResponse)
{
    //调用lua处理回调
    int nParamCount = pMulDataResponse->nCount;
    if(nParamCount < 0)
        nParamCount = 0;
    lua_engine.RedisCallLua(pMulDataResponse->uSquenceId, pMulDataResponse->uUserId, pMulDataResponse->uEventType, nParamCount, pMulDataResponse->data);
}

bool GameLogicServer::_ProcessNetData(const char* pData, size_t uRead, unsigned int uServerFrom)
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
            
            unsigned int uEventType = GetEventType(pDataBuffer);
            unsigned int uHandlerId = GetHandlerId(pDataBuffer);
            unsigned int uSequenceId = GetSequenceId(pDataBuffer);
            
            char* pNetBodyBuffer = NULL;
            unsigned int uNetBodySize = 0;
            GetNetPackageBody(pDataBuffer, pBuffer->GetSize(), &pNetBodyBuffer, &uNetBodySize);
            
            Message msg;
            bool bIsOk = msg.ParseFromArray(pNetBodyBuffer, uNetBodySize);
            if(bIsOk)
            {
                if(uServerFrom == SERVER_TYPE::LOGIC || uServerFrom == SERVER_TYPE::GATEWAY){
                    lua_engine.CallLua(uHandlerId, uEventType, uSequenceId, msg.data().c_str());
                } else if(uServerFrom == SERVER_TYPE::CENTER){
                    lua_engine.CallCenterRequestLua(uHandlerId, uEventType, uSequenceId, msg.data().c_str());
                } else {
                    cout <<  "Does not support server type:" << uServerFrom << endl;
                }
            }
            
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