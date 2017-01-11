//
//  lua_net.hpp
//  server
//
//  Created by 冯文斌 on 17/1/11.
//  Copyright © 2017年 kelvin. All rights reserved.
//

#ifndef lua_net_hpp
#define lua_net_hpp

extern "C"
{
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
};

int LuaRegisterNet(lua_State* lua_state);

#endif /* lua_net_hpp */
