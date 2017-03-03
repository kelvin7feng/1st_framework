//
//  center_client.hpp
//  server
//
//  Created by 冯文斌 on 17/2/22.
//  Copyright © 2017年 kelvin. All rights reserved.
//

#ifndef center_client_hpp
#define center_client_hpp

#include "tcp_client.hpp"

class CenterClient : public TCPClient
{
public:
    CenterClient();
    
    ~CenterClient();
    
    CenterClient(const CenterClient& CenterClient);
    
    static CenterClient* GetInstance();
    
    //初始函数
    int Init(uv_loop_t* loop, const char* ip, int port, int nServerType);
    
    //连接后的回调函数
    void OnConnect(uv_connect_t *req, int status);
    
    //数据收到处理,转发给客户端
    void OnMsgRecv(uv_stream_t* client, ssize_t nread, const uv_buf_t *buf);
    
    //转发到服务端函数
    void TransferToCenterServer(const char* pBuffer, ssize_t nRead);
    
    //转发到服务端的回调
    void OnTransferToCenterServer(uv_write_t *req, int status);
    
    //注册到中心服
    void RegisterToCenter();
    
    //发送网络包
    void SendNetPacket(unsigned short uServerId, unsigned int uEventType, const char* pBuffer, unsigned int uMsgSize);
    
    //设置服务器类型
    void SetSeverType(int nServerType);
    
    //获取服务器类型
    int GetSeverType();
    
private:
    
    bool _ProcessNetData(const char* pData, size_t uSize);
    
    int m_nServerType;
    
};

#endif /* center_client_hpp */
