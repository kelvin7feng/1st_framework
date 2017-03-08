//
//  lua_engine.cpp
//  lua_five_one
//
//  Created by 冯文斌 on 16/11/28.
//  Copyright © 2016年 kelvin. All rights reserved.
//

#include "map"
#include "kmacros.h"
#include "lua_player.h"
#include "lua_engine.hpp"
#include "lua_redis.hpp"
#include "lua_net.hpp"

using namespace std;

LuaEngine::LuaEngine()
{
    server_path[SERVER_TYPE::LOGIN] = "./../script/login_main.lua";
    server_path[SERVER_TYPE::LOGIC] = "./../script/logic_main.lua";
    server_path[SERVER_TYPE::ROOM] = "./../script/room_main.lua";
    server_path[SERVER_TYPE::CENTER] = "./../script/center_main.lua";
}

LuaEngine::~LuaEngine()
{
    this->Close();
}

void LuaEngine::Close()
{
    lua_close(m_lua_state);
}

void LuaEngine::stackDump(lua_State* L){
    cout<<"\n------------begin dump lua stack------------"<<endl;
    int i = 0;
    int top = lua_gettop(L);
    int stack_index_1 = top;
    int stack_index_2 = -1;
    for (i = 1; i <= top; ++i) {
        int t = lua_type(L, i);
        printf("%d|",stack_index_1);
        switch (t) {
            case LUA_TSTRING:
            {
                printf("'%s' ", lua_tostring(L, i));
            }
                break;
            case LUA_TBOOLEAN:
            {
                printf(lua_toboolean(L, i) ? "true " : "false ");
            }break;
            case LUA_TNUMBER:
            {
                printf("%g ", lua_tonumber(L, i));
            }
                break;
            default:
            {
                printf("%s ", lua_typename(L, t));
            }
                break;
        }
        printf("|%d\n",stack_index_2);
        stack_index_1 --;
        stack_index_2 --;
        
    }
    cout<<"------------end dump lua stack--------------\n"<<endl;
}

//调用脚本处理
int LuaEngine::CallCenterRequestLua(unsigned int uHandlerId, unsigned int uEventType, unsigned short uSequenceId, const char* pParam)
{
    //清空虚拟栈
    int nTop = lua_gettop(m_lua_state);
    
    //把OnClientRequest函数push到栈里
    lua_getglobal(m_lua_state, "OnCenterRequest");
    
    //把请求的参数push到栈里
    lua_pushnumber(m_lua_state, uHandlerId);
    lua_pushnumber(m_lua_state, uEventType);
    lua_pushnumber(m_lua_state, uSequenceId);
    lua_pushstring(m_lua_state, pParam);
    
    //函数调用参数：虚拟机句柄,函数参数个数,函数返回值个数,调用错误码
    int ret = lua_pcall(m_lua_state, 4, 1, 0);
    
    //调用出错
    if(ret)
    {
        const char *pErrorMsg = lua_tostring(m_lua_state, -1);
        cout << pErrorMsg << endl;
        return 0;
    }
    
    //取值输出
    if (lua_isnumber(m_lua_state, -1))
    {
        int fValue = lua_tonumber(m_lua_state, -1);
        if(fValue){
            //成功逻辑
        }
    } else {
        //返回值类型错误
    }
    
    lua_settop(m_lua_state, nTop);
    
    return 0;
}

//调用脚本处理
int LuaEngine::CallLua(unsigned int uHandlerId, unsigned int uEventType, unsigned short uSequenceId, const char* pParam)
{
    //清空虚拟栈
    int nTop = lua_gettop(m_lua_state);
    
    //把OnClientRequest函数push到栈里
    lua_getglobal(m_lua_state, "OnClientRequest");
    
    //把请求的参数push到栈里
    lua_pushnumber(m_lua_state, uHandlerId);
    lua_pushnumber(m_lua_state, uEventType);
    lua_pushnumber(m_lua_state, uSequenceId);
    lua_pushstring(m_lua_state, pParam);
    
    //函数调用参数：虚拟机句柄,函数参数个数,函数返回值个数,调用错误码
    int ret = lua_pcall(m_lua_state, 4, 1, 0);
    
    //调用出错
    if(ret)
    {
        const char *pErrorMsg = lua_tostring(m_lua_state, -1);
        cout << pErrorMsg << endl;
        return 0;
    }
    
    //取值输出
    if (lua_isnumber(m_lua_state, -1))
    {
        int fValue = lua_tonumber(m_lua_state, -1);
        if(fValue){
            //成功逻辑
        }
    } else {
        //返回值类型错误
    }
    
    lua_settop(m_lua_state, nTop);
    
    return 0;
}

//调用脚本处理
int LuaEngine::RedisCallLua(const unsigned int uUserId, const unsigned int uEventType, const std::string& request)
{
    int nTop = lua_gettop(m_lua_state);
    
    lua_getglobal(m_lua_state, "OnRedisRespone");
    lua_pushnumber(m_lua_state, uUserId);
    lua_pushnumber(m_lua_state, uEventType);
    lua_pushstring(m_lua_state, request.c_str());
    
    int ret = lua_pcall(m_lua_state, 3, 1, 0);
    
    //调用出错
    if(ret)
    {
        const char *pErrorMsg = lua_tostring(m_lua_state, -1);
        cout << pErrorMsg << endl;
        return 0;
    }
    
    //取值输出
    if (lua_isnumber(m_lua_state, -1))
    {
        int fValue = lua_tonumber(m_lua_state, -1);
        if(fValue){
            //成功逻辑
        }
    } else {
        //返回值类型错误
    }
    
    lua_settop(m_lua_state, nTop);
    
    return 0;
}

//调用脚本处理
int LuaEngine::RedisCallLua(const unsigned int uUserId, const unsigned int uEventType, const unsigned int nParamCount, char* szData)
{
    int nTop = lua_gettop(m_lua_state);
    
    lua_getglobal(m_lua_state, "OnRedisMulDataRespone");
    lua_pushnumber(m_lua_state, uUserId);
    lua_pushnumber(m_lua_state, uEventType);
    
    //把字符串处理成table
    lua_createtable(m_lua_state, 0, nParamCount);
    if(nParamCount > 0)
    {
        int* pnValueLen = (int*)szData;
        char* pTmp = szData + sizeof(int) * nParamCount;
        for(int i = 0; i < nParamCount; i++)
        {
            lua_pushnumber(m_lua_state, i);
            lua_pushlstring(m_lua_state, pTmp, *pnValueLen);
            pTmp += *pnValueLen;
            pnValueLen++;
            lua_settable(m_lua_state, -3);
        }
    }
    
    int ret = lua_pcall(m_lua_state, 3, 1, 0);
    
    //调用出错
    if(ret)
    {
        const char *pErrorMsg = lua_tostring(m_lua_state, -1);
        cout << pErrorMsg << endl;
        return 0;
    }
    
    //取值输出
    if (lua_isnumber(m_lua_state, -1))
    {
        int fValue = lua_tonumber(m_lua_state, -1);
        if(fValue){
            //成功逻辑
        }
    } else {
        //返回值类型错误
    }
    
    lua_settop(m_lua_state, nTop);
    return 0;
}

//Lua引擎初始化
int LuaEngine::InitState(int server_type)
{
    m_lua_state = lua_open();
    luaopen_base(m_lua_state);
    luaL_openlibs(m_lua_state);
    
    if (!m_lua_state)
    {
        cout << "opening lua engine failed...";
        exit(1);
    }
    
    LuaRegisterRedis(m_lua_state);
    LuaRegisterNet(m_lua_state);
    tolua_player_open(m_lua_state);
    string szScriptPath = server_path[server_type];
    int nStatus = luaL_dofile(m_lua_state, szScriptPath.c_str());
    
    int nResult = 0;
    if(!nStatus)
    {
        nResult = lua_pcall(m_lua_state, 0, LUA_MULTRET, 0);
    }
    else
    {
        std::cout<<"load file error [file:"<< szScriptPath.c_str() << "]: "
                    << lua_tostring(m_lua_state, -1) <<endl;
        
        exit(1);
    }
    
    lua_settop(m_lua_state, 0);
    return nResult;
}

//获取lua state结构指针
lua_State* LuaEngine::GetLuaState()
{
    return m_lua_state;
}
