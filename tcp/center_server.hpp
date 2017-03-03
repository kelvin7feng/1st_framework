//
//  center_server.hpp
//  server
//
//  Created by 冯文斌 on 17/2/22.
//  Copyright © 2017年 kelvin. All rights reserved.
//

#ifndef center_server_hpp
#define center_server_hpp

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <iostream>

#include <map>
#include <uv.h>

#include "tcp_client.hpp"
#include "lua_engine.hpp"
#include "tcp_base_server.hpp"

#include "google.pb.h"

using namespace std;
using namespace google;

typedef std::map<unsigned int, unsigned int> server_type_handler_map_t;

class CenterServer : public TCPBaseServer {
    
public:
    
    CenterServer();
    
    ~CenterServer();
    
    CenterServer(const CenterServer& CenterServer);
    
    static CenterServer* GetInstance();
    
    //初始化
    int Init(uv_loop_t* loop);
    
    //监听新建连接
    void OnNewConnection(uv_stream_t *server, int status);
    
    //监听接收数据
    void OnMsgRecv(uv_stream_t *client, ssize_t nread, const uv_buf_t *buf);
    
    //释放客户端句柄
    void RemoveClient(uv_stream_t* client);
    
    //客户端关闭后的回调
    void OnConnectionClose(uv_handle_t* handle);
    
    //转发到客户端
    void TransferToClient(unsigned int uHandlerId, const char* pBuffer, unsigned int uSize);
    
    //转发到客户端的回调
    void OnTransferToClient(uv_write_t *req, int status);
    
    //调用lua虚拟机
    void CallLua(unsigned int uHandlerId, unsigned int uEventType, const char* pParam);
    
    //设置服务器类型与句柄关系
    void SetServerTypeToHandler(unsigned int uServerType, unsigned int uHandlerId);
    
    //根据服务器类型获取句柄
    unsigned int GetServerTypeToHandler(unsigned int uServerType);
    
    //获取服务器类型与句柄map
    server_type_handler_map_t& GetServerTypeToHandlerMap();
    
private:
    
    LuaEngine lua_engine;
    
    server_type_handler_map_t m_mapServerTypeToHandler;
};

#endif /* center_server_hpp */
