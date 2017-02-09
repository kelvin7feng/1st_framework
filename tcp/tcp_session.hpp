//
//  tcp_session.hpp
//  server
//
//  Created by 冯文斌 on 16/10/8.
//  Copyright © 2016年 冯文斌. All rights reserved.
//

#ifndef tcp_session_hpp
#define tcp_session_hpp

#include <stdio.h>
#include <map>
#include <queue>
#include <memory>
#include <uv.h>

#include "knetpacket.h"
#include "gateway_client.hpp"

class TCPSession
{
public:
    
    TCPSession();
    ~TCPSession();
    
    unsigned int GetHandlerId();
    
    void SetHandlerId(unsigned int uHandlerId);
    
    bool ProcessNetData(const char* pData, size_t uSize);
    
    std::shared_ptr<uv_tcp_t> connection;
    std::shared_ptr<uv_timer_t> activity_timer;
    
private:
    
    GatewayClient* GetGatewayClient(unsigned short uServerId);
    
    unsigned int m_uHandlerId;
    
    IKNetPacket* m_pRecvPacket;

};

extern GatewayClient* g_pLoginLogicClient;
extern GatewayClient* g_pGameLogicClient;
extern GatewayClient* g_pRoomLogicClient;

#endif /* tcp_session_hpp */