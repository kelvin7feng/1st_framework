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
#include "game_logic_server.hpp"
#include <iostream>

static int SendToGameway(lua_State* lua_state)
{
    int nRetCode = 0;
    int nParam = lua_gettop(lua_state);
    if(nParam != 5)
    {
        std::cout << "count of param is not equal to 5..." << std::endl;
        return 0;
    }
    
    unsigned int uEventType = lua_tonumber(lua_state, nParam - 4);
    unsigned int uErrorCode = lua_tonumber(lua_state, nParam - 3);
    unsigned int uHandlerId = lua_tonumber(lua_state, nParam - 2);
    unsigned int uParamSize = lua_tonumber(lua_state, nParam - 1);
    std::string szParam = lua_tostring(lua_state, nParam);
    
    unsigned int uNetPacketSize = KD_PACKAGE_HEADER_SIZE + uParamSize;
    void* pNetPackage = Net_CreateBuffer(uEventType, uErrorCode, uHandlerId, szParam.c_str(), uParamSize);
    GameLogicServer::GetInstance()->SendDataToGateway((char*)pNetPackage, uNetPacketSize);
    
    delete[] (char*)pNetPackage;
    return nRetCode;
}

static const luaL_reg sLuaNetFunction[] =
{
    {"SendToGameway", SendToGameway},
    {NULL, NULL}
};

int LuaRegisterNet(lua_State* lua_state)
{
    luaL_register(lua_state, "CNet", sLuaNetFunction);
    return 1;
}