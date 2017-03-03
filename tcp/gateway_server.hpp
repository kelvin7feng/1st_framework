//
//  gateway_server.hpp
//  server
//
//  Created by 冯文斌 on 16/9/5.
//  Copyright © 2016年 冯文斌. All rights reserved.
//

#ifndef gateway_server_hpp
#define gateway_server_hpp

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <iostream>

#include <map>
#include <uv.h>

#include "tcp_client.hpp"
#include "tcp_base_server.hpp"

#include "google.pb.h"

using namespace std;
using namespace google;

class GatewayServer : public TCPBaseServer {
    
public:
    
    GatewayServer();
    
    ~GatewayServer();
    
    GatewayServer(const GatewayServer& GatewayServer);
    
    static GatewayServer* GetInstance();
    
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
    
};

#endif /* gateway_server_hpp */