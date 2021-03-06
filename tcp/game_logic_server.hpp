//
//  game_logic_server.hpp
//  server
//
//  Created by 冯文斌 on 16/10/10.
//  Copyright © 2016年 kelvin. All rights reserved.
//

#pragma once

#ifndef game_logic_server_hpp
#define game_logic_server_hpp

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <iostream>
#include <time.h>

#include <map>
#include <uv.h>

#include "db_def.h"
#include "google.pb.h"
#include "krequest_def.h"
#include "lua_engine.hpp"
#include "tcp_client.hpp"
#include "tcp_base_server.hpp"

using namespace std;
using namespace google;

class GameLogicServer : public TCPBaseServer {
    
public:
    
    GameLogicServer();
    
    ~GameLogicServer();
    
    GameLogicServer(const GameLogicServer& GameLogicServer);
    
    static GameLogicServer* GetInstance();
    
    //初始化
    int Init(uv_loop_t* loop);
    
    //监听新连接
    void OnNewConnection(uv_stream_t *server, int status);
    
    //接收数据
    void OnMsgRecv(uv_stream_t* client, ssize_t nread, const uv_buf_t *buf);
    
    //数据处理的回调
    void OnDBResponse(KRESOOND_COMMON* pCommonResponse);
    
    void OnDBResponse(KP_DBRESPOND_MULTI_DATA* pMulDataResponse);
    
    //释放客户端句柄
    void RemoveClient(uv_stream_t* client);
    
    //客户端关闭后的回调
    void OnConnectionClose(uv_handle_t* handle);
    
    //发送函数
    void SendDataToGateway(const char* pBuffer, unsigned int uSize);
    
    //发送函数的回调
    void OnSendData(uv_write_t *pReq, int nStatus);
    
    void UpdateLuaTimer();
    
    uv_stream_t* m_pGatewayClient;
    
    uv_write_t m_write_req;
    
    uv_timer_t m_db_timer_req;
    
    uv_timer_t m_lua_timer;
    
    bool _ProcessNetData(const char* pData, size_t uSize, unsigned int uServerFrom);
    
private:
    
    LuaEngine lua_engine;
    
    int totol_request;
    
    double m_lua_timer_span;
    
};

#endif /* game_logic_server_hpp */