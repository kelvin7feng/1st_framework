//
//  gateway_server.cpp
//  server
//
//  Created by 冯文斌 on 16/9/5.
//  Copyright © 2016年 冯文斌. All rights reserved.
//

#include "kmacros.h"
#include "document.h"
#include "file_util.h"
#include "net_buffer.hpp"
#include "gateway_server.hpp"

using namespace rapidjson;

GatewayServer::GatewayServer()
{
    
}

GatewayServer::~GatewayServer()
{
    cout << "Gateway Server Terminated" << endl;
}

GatewayServer* GatewayServer::GetInstance()
{
    static GatewayServer server;
    return &server;
}

GatewayClient* GatewayServer::GetGatewayClient(unsigned short uServerId)
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

int GatewayServer::Init(uv_loop_t* loop)
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
    
    int ret = uv_listen((uv_stream_t*) &server, GetDefaultBackLog(),
                      [](uv_stream_t* server, int status)
                      {
                          GatewayServer::GetInstance()->OnNewConnection(server, status);
                      });

    
    if (ret) {
        fprintf(stderr, "Listen error %s: %s:%d\n", uv_strerror(ret), ip, port);
        exit(1);
    }
    
    cout << "gateway server listen " << ip << ":" << port << " succeed"<< endl;
    return ret;
}

void GatewayServer::OnMsgRecv(uv_stream_t *client, ssize_t uRead, const uv_buf_t *buf) {
    
    session_map_t& open_sessions = GetSessionMap();
    auto connection_pos = open_sessions.find(client);
    if (connection_pos != open_sessions.end())
    {
        if (uRead == UV_EOF)
        {
            cout << "Client Disconnected" << endl;
            RemoveClient(client);
        }
        else if (uRead > 0)
        {
            TCPSession* session = connection_pos->second;
            session->ProcessNetData(buf->base, uRead);
        }
    }
    
    else
    {
        uv_read_stop(client);
        cout << "Unrecognized client. Disconnecting." << endl;;
    }
    
    free(buf->base);
}

void GatewayServer::RemoveClient(uv_stream_t* client)
{
    session_map_t& open_sessions = GetSessionMap();
    auto connection_pos = open_sessions.find(client);
    if (connection_pos != open_sessions.end())
    {
        TCPSession* session = connection_pos->second;
        uv_close((uv_handle_t*)session->connection.get(),
                 [] (uv_handle_t* handle)
                 {
                     GatewayServer::GetInstance()->OnConnectionClose(handle);
                 });
        
        handler_map_to_id_t& mapHandlerToId = GetHandlerToIdMap();
        auto handlerToIdPos = mapHandlerToId.find(client);
        if(handlerToIdPos != mapHandlerToId.end())
        {
            mapHandlerToId.erase(client);
            unsigned int uSessionId = handlerToIdPos->second;
            id_map_to_handler_t& mapIdToHandler = GetIdToHandlerMap();
            auto idToHandlerPos = mapIdToHandler.find(uSessionId);
            if(idToHandlerPos != mapIdToHandler.end())
            {
                mapIdToHandler.erase(uSessionId);
            }
        }
        
        //to do:内存泄露
        //SAFE_DELETE(session);
    }
}

void GatewayServer::OnConnectionClose(uv_handle_t* handle)
{
    session_map_t& open_sessions = GatewayServer::GetInstance()->GetSessionMap();
    open_sessions.erase((uv_stream_t*)handle);
}

void GatewayServer::OnNewConnection(uv_stream_t *server, int status)
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
                          GatewayServer::GetInstance()->AllocBuffer(stream, nread, buf);
                      },
                      [](uv_stream_t* stream, ssize_t nread, const uv_buf_t* buf)
                      {
                          GatewayServer::GetInstance()->OnMsgRecv(stream, nread, buf);
                      });
        
        AddSession(new_session);
    }
    else {
        uv_close((uv_handle_t*)new_session->connection.get(), NULL);
    }
}

//玩家断线
void GatewayServer::NotifyUserSocketDisconnect(unsigned int uHandlerId)
{
    unsigned int uServerType = LOGIC;
    unsigned int uEventType = 4001;
    
    Message msg;
    char* pBbuffer = new char[sizeof("[%d]")];
    int nLen = sprintf(pBbuffer, "[%d]", uHandlerId);
    msg.set_data(pBbuffer, nLen);
    std::string szNetBody;
    msg.SerializeToString(&szNetBody);
    
    NotifyLogicServer(uServerType, uEventType, szNetBody.c_str(), (unsigned int)szNetBody.length());
    
    //释放网关
    id_map_to_handler_t& mapIdToHandler = GetIdToHandlerMap();
    auto idToHandlerPos = mapIdToHandler.find(uHandlerId);
    if(idToHandlerPos != mapIdToHandler.end())
    {
        mapIdToHandler.erase(uHandlerId);
    }
    
    SAFE_DELETE_ARRAY(pBbuffer);
}

//通知逻辑服,由网关发起的请求
void GatewayServer::NotifyLogicServer(unsigned int uServerId, unsigned int uEventType, const char* pBuffer, unsigned int uMsgSize)
{
    unsigned int uErrorCode = 0;
    unsigned int uPacketLen = 0;
    unsigned short uSequenceId = 0;
    unsigned int uHandlerId = 0;
    void* pvNetBuffer = CreateNetBuffer(uEventType, uErrorCode, uHandlerId, uServerId, uSequenceId, pBuffer, uMsgSize, &uPacketLen);
    
    GatewayClient* pClient = GetGatewayClient(uServerId);
    if(pClient)
    {
        pClient->TransferToLogicServer((char*)pvNetBuffer, uPacketLen);
    }
    
    SAFE_DELETE(pvNetBuffer);
}

//转发到客户端的回调
void GatewayServer::OnTransferToClient(uv_write_t *req, int status){
    
    if (status < 0) {
        cout << "TCP Client write error: " << uv_strerror(status) << endl;
        return;
    }
    
    if (status == 0) {
        cout << "transfer to client succeed!\r\n" << endl;
    }
    
    SAFE_DELETE(req);
}

void GatewayServer::TransferToClient(unsigned int uHandlerId, const char* pBuffer, unsigned int uSize)
{
    cout << "gateway send data to client..." << endl;
    uv_stream_t* pClientHandler = GetHandlerById(uHandlerId);
    
    if(pClientHandler != NULL)
    {
        char* pvBuffer = NULL;
        pvBuffer = (char*)malloc(uSize);
        memcpy(pvBuffer, pBuffer, uSize);
        
        uv_write_t* pWriteReq = new uv_write_t;
        
        uv_buf_t buf = uv_buf_init(pvBuffer, uSize);
        int nRet = uv_write(pWriteReq, pClientHandler, &buf, 1,
                           [](uv_write_t *req, int status)
                           {
                               GatewayServer::GetInstance()->OnTransferToClient(req, status);
                           });
        if(nRet != 0)
        {
            cout << "transfer to client failed;" << endl;
            SAFE_DELETE(pWriteReq);
        }
        SAFE_FREE(pvBuffer);
    } else {
        //需要通过逻辑服去移除相关的缓存
        NotifyUserSocketDisconnect(uHandlerId);
        cout << "client have been disconnected;" << endl;
    }
}