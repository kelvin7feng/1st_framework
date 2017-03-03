//
//  center_server.cpp
//  server
//
//  Created by 冯文斌 on 17/2/22.
//  Copyright © 2017年 kelvin. All rights reserved.
//

#include "kmacros.h"
#include "document.h"
#include "file_util.h"
#include "net_buffer.hpp"
#include "center_server.hpp"

using namespace rapidjson;

CenterServer::CenterServer()
{
    
}

CenterServer::~CenterServer()
{
    cout << "CenterServer Server Terminated" << endl;
}

CenterServer* CenterServer::GetInstance()
{
    static CenterServer server;
    return &server;
}

int CenterServer::Init(uv_loop_t* loop)
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
                            CenterServer::GetInstance()->OnNewConnection(server, status);
                        });
    
    
    if (ret) {
        fprintf(stderr, "Listen error %s: %s:%d\n", uv_strerror(ret), ip, port);
        exit(1);
    }
    
    int nLogicServerType = json_doc["logic_server_type"].GetInt();
    lua_engine.InitState(nLogicServerType);
    cout << "center server listen " << ip << ":" << port << " succeed"<< endl;
    return ret;
}

void CenterServer::OnMsgRecv(uv_stream_t *client, ssize_t uRead, const uv_buf_t *buf) {
    
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
            session->CenterServerProcessNetData(buf->base, uRead);
        }
    }
    
    else
    {
        uv_read_stop(client);
        cout << "Unrecognized client. Disconnecting." << endl;;
    }
    
    free(buf->base);
}

void CenterServer::RemoveClient(uv_stream_t* client)
{
    session_map_t& open_sessions = GetSessionMap();
    auto connection_pos = open_sessions.find(client);
    if (connection_pos != open_sessions.end())
    {
        TCPSession* session = connection_pos->second;
        uv_close((uv_handle_t*)session->connection.get(),
                 [] (uv_handle_t* handle)
                 {
                     CenterServer::GetInstance()->OnConnectionClose(handle);
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

void CenterServer::OnConnectionClose(uv_handle_t* handle)
{
    session_map_t& open_sessions = CenterServer::GetInstance()->GetSessionMap();
    open_sessions.erase((uv_stream_t*)handle);
}

void CenterServer::OnNewConnection(uv_stream_t *server, int status)
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
                          CenterServer::GetInstance()->AllocBuffer(stream, nread, buf);
                      },
                      [](uv_stream_t* stream, ssize_t nread, const uv_buf_t* buf)
                      {
                          CenterServer::GetInstance()->OnMsgRecv(stream, nread, buf);
                      });
        
        AddSession(new_session);
    }
    else {
        uv_close((uv_handle_t*)new_session->connection.get(), NULL);
    }
}

//转发到客户端的回调
void CenterServer::OnTransferToClient(uv_write_t *req, int status){
    
    if (status < 0) {
        cout << "TCP Client write error: " << uv_strerror(status) << endl;
        return;
    }
    
    if (status == 0) {
        cout << "transfer to client succeed!\r\n" << endl;
    }
    
    SAFE_DELETE(req);
}

void CenterServer::TransferToClient(unsigned int uHandlerId, const char* pBuffer, unsigned int uSize)
{
    cout << "gateway send data to client..." << endl;
    uv_stream_t* pClientHandler = GetHandlerById(uHandlerId);
    
    if(pClientHandler == NULL)
    {
        cout << "ERROR: CenterServer::TransferToClient pClientHandler is NULL" << endl;
        return;
    }
    char* pvBuffer = NULL;
    pvBuffer = (char*)malloc(uSize);
    memcpy(pvBuffer, pBuffer, uSize);
    
    uv_write_t* pWriteReq = new uv_write_t;
    
    uv_buf_t buf = uv_buf_init(pvBuffer, uSize);
    int nRet = uv_write(pWriteReq, pClientHandler, &buf, 1,
                        [](uv_write_t *req, int status)
                        {
                            CenterServer::GetInstance()->OnTransferToClient(req, status);
                        });
    if(nRet != 0)
    {
        cout << "transfer to client failed;" << endl;
        SAFE_DELETE(pWriteReq);
    }
    
    SAFE_FREE(pvBuffer);
}

void CenterServer::CallLua(unsigned int uHandlerId, unsigned int uEventType, const char* pParam){
    unsigned int nSequenceId = 0;
    lua_engine.CallLua(uHandlerId, uEventType, nSequenceId, pParam);
}

void CenterServer::SetServerTypeToHandler(unsigned int uServerType, unsigned int uHandlerId)
{
    server_type_handler_map_t& mapSH = GetServerTypeToHandlerMap();
    mapSH.insert({uServerType, uHandlerId});
}

unsigned int CenterServer::GetServerTypeToHandler(unsigned int uServerType)
{
    unsigned int uHandlerId = NULL;
    server_type_handler_map_t& mapSH = GetServerTypeToHandlerMap();
    auto handler = mapSH.find(uServerType);
    if(handler != mapSH.end())
    {
        uHandlerId = handler->second;
    }
    
    return uHandlerId;
}

server_type_handler_map_t& CenterServer::GetServerTypeToHandlerMap()
{
    return m_mapServerTypeToHandler;
}