//
//  lua_net.cpp
//  server
//
//  Created by 冯文斌 on 17/1/11.
//  Copyright © 2017年 kelvin. All rights reserved.
//

#include "kmacros.h"
#include "db_buffer.h"
#include "lua_net.hpp"
#include "net_buffer.hpp"
#include "tcp_session.hpp"
#include "center_server.hpp"
#include "game_logic_server.hpp"
#include <iostream>

static int SendToGateway(lua_State* lua_state)
{
    int nRetCode = 0;
    int nParam = lua_gettop(lua_state);
    if(nParam != 6)
    {
        std::cout << "count of param is not equal to 6..." << std::endl;
        return 0;
    }
    
    unsigned short uSequenceId = lua_tonumber(lua_state, nParam - 5);
    unsigned int uEventType = lua_tonumber(lua_state, nParam - 4);
    unsigned int uErrorCode = lua_tonumber(lua_state, nParam - 3);
    unsigned int uHandlerId = lua_tonumber(lua_state, nParam - 2);
    //unsigned int uParamSize = lua_tonumber(lua_state, nParam - 1);
    std::string szParam = lua_tostring(lua_state, nParam);
    
    Message msg;
    msg.set_data(szParam);
    std::string szNetBody;
    msg.SerializeToString(&szNetBody);
    
    unsigned short uServerId = 0;
    unsigned int uNetPacketSize = 0;
    void* pNetPackage = CreateNetBuffer(uEventType, uErrorCode, uHandlerId, uServerId, uSequenceId, szNetBody.c_str(), (unsigned int)szNetBody.length(), &uNetPacketSize);
    GameLogicServer::GetInstance()->SendDataToGateway((char*)pNetPackage, uNetPacketSize);
    
    SAFE_FREE(pNetPackage);
    
    return nRetCode;
}

static int SendToCenter(lua_State* lua_state)
{
    int nRetCode = 0;
    int nParam = lua_gettop(lua_state);
    if(nParam != 6)
    {
        std::cout << "count of param is not equal to 6..." << std::endl;
        return 0;
    }
    
    unsigned short uSequenceId = lua_tonumber(lua_state, nParam - 5);
    unsigned int uEventType = lua_tonumber(lua_state, nParam - 4);
    unsigned int uErrorCode = lua_tonumber(lua_state, nParam - 3);
    unsigned int uHandlerId = lua_tonumber(lua_state, nParam - 2);
    //unsigned int uParamSize = lua_tonumber(lua_state, nParam - 1);
    std::string szParam = lua_tostring(lua_state, nParam);
    
    Message msg;
    msg.set_data(szParam);
    std::string szNetBody;
    msg.SerializeToString(&szNetBody);
    
    unsigned short uServerId = SERVER_TYPE::ROOM;
    unsigned int uNetPacketSize = 0;
    void* pNetPackage = CreateNetBuffer(uEventType, uErrorCode, uHandlerId, uServerId, uSequenceId, szNetBody.c_str(), (unsigned int)szNetBody.length(), &uNetPacketSize);
    if(g_pCenterLogicClient)
    {
        g_pCenterLogicClient->TransferToCenterServer((char*)pNetPackage, uNetPacketSize);
    }
    else
    {
        std::cout << "g_pCenterLogicClient is null..." << std::endl;
    }
    SAFE_FREE(pNetPackage);
    
    return nRetCode;
}

//中心服发送数据到逻辑服
static int SendToLogicServer(lua_State* lua_state)
{
    int nRetCode = 0;
    int nParam = lua_gettop(lua_state);
    if(nParam != 6)
    {
        std::cout << "count of param is not equal to 6..." << std::endl;
        return 0;
    }
    
    unsigned short uSequenceId = lua_tonumber(lua_state, nParam - 5);
    unsigned int uEventType = lua_tonumber(lua_state, nParam - 4);
    unsigned int uErrorCode = lua_tonumber(lua_state, nParam - 3);
    unsigned int uHandlerId = lua_tonumber(lua_state, nParam - 2);
    //unsigned int uParamSize = lua_tonumber(lua_state, nParam - 1);
    std::string szParam = lua_tostring(lua_state, nParam);
    
    Message msg;
    msg.set_data(szParam);
    std::string szNetBody;
    msg.SerializeToString(&szNetBody);
    
    unsigned short uServerId = 0;
    unsigned int uNetPacketSize = 0;
    void* pNetPackage = CreateNetBuffer(uEventType, uErrorCode, uHandlerId, uServerId, uSequenceId, szNetBody.c_str(), (unsigned int)szNetBody.length(), &uNetPacketSize);
    
    CenterServer::GetInstance()->TransferToClient(uHandlerId, (char*)pNetPackage, uNetPacketSize);
    std::cout << "center server transfer to client..." << std::endl;
    
    SAFE_FREE(pNetPackage);
    
    return nRetCode;
}

static int SetServerTypeToHandlerId(lua_State* lua_state)
{
    int nRetCode = 0;
    int nParam = lua_gettop(lua_state);
    if(nParam != 2)
    {
        std::cout << "count of param is not equal to 2..." << std::endl;
        return -1;
    }
    
    unsigned int uServerType = lua_tonumber(lua_state, nParam - 1);
    unsigned int uHandlerId = lua_tonumber(lua_state, nParam);
    CenterServer::GetInstance()->SetServerTypeToHandler(uServerType, uHandlerId);
    return nRetCode;
}

static const luaL_reg sLuaNetFunction[] =
{
    {"SendToGateway", SendToGateway},
    {"SendToCenter", SendToCenter},
    {"SendToLogicServer", SendToLogicServer},
    {"SetServerTypeToHandlerId", SetServerTypeToHandlerId},
    {NULL, NULL}
};

int LuaRegisterNet(lua_State* lua_state)
{
    luaL_register(lua_state, "CNet", sLuaNetFunction);
    return 1;
}