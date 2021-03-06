//
//  lua_engine.hpp
//  lua_five_one
//
//  Created by 冯文斌 on 16/11/28.
//  Copyright © 2016年 kelvin. All rights reserved.
//

#ifndef lua_engine_hpp
#define lua_engine_hpp

extern "C"
{
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
};

#include <stdio.h>
#include <iostream>
#include <string>
#include <fstream>
#include <map>

using namespace std;

class LuaEngine {
    
public:
    
    LuaEngine();
    ~LuaEngine();
    void Close();
    lua_State* GetLuaState();
    int InitState(int server_type);
    int UpdateTimer(double elapse);
    int CallLua(unsigned int uHandlerId, unsigned int uEventType, unsigned short uSequenceId, const char* pParam);
    int CallCenterRequestLua(unsigned int uHandlerId, unsigned int uEventType, unsigned short uSequenceId, const char* pParam);
    int RedisCallLua(const unsigned int uSquenceId, const unsigned int uUserId, const unsigned int uEventType, const std::string& request);
    int RedisCallLua(const unsigned int uSquenceId, const unsigned int uUserId, const unsigned int uEventType, const unsigned int uParamCount, char* request);

private:
    
    void stackDump(lua_State* L);
    
    lua_State* m_lua_state;
    
    map<int, string> server_path;
};

#endif /* lua_engine_hpp */
