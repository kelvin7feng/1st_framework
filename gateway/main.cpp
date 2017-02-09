//
//  main.cpp
//  server
//
//  Created by 冯文斌 on 16/10/10.
//  Copyright © 2016年 kelvin. All rights reserved.
//


#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <uv.h>

#include "document.h"
#include "file_util.h"
#include "tcp_session.hpp"
#include "gateway_server.hpp"
#include "gateway_client.hpp"

using namespace std;
using namespace rapidjson;

int main() {
    string sz_config;
    FileUtil* file_util = FileUtil::GetInstance();
    bool is_ok = file_util->ReadFile("config.json", sz_config);
    if(!is_ok)
    {
        cout << "read config failed." << endl;
        exit(1);
    }
    
    Document json_doc;
    json_doc.Parse(sz_config.c_str());
    
    //初始化网关
    const Value& server_config = json_doc["listen"];
    string gateway_ip = server_config["ip"].GetString();
    int gateway_port = server_config["port"].GetInt();
    
    uv_loop_t *loop = uv_default_loop();
    GatewayServer *server = GatewayServer::GetInstance();
    server->Init(loop, gateway_ip.c_str(), gateway_port);
    
    //连接登录服
    if(json_doc.HasMember("login_logic"))
    {
        const Value& login_logic_config = json_doc["login_logic"];
        if(login_logic_config.HasMember("ip") && login_logic_config.HasMember("port"))
        {
            string login_logic_ip = login_logic_config["ip"].GetString();
            int login_logic_port = login_logic_config["port"].GetInt();
            
            g_pLoginLogicClient = new GatewayClient();
            g_pLoginLogicClient->Init(loop, login_logic_ip.c_str(), login_logic_port);
        }
    }
    
    //连接逻辑服
    if(json_doc.HasMember("game_logic"))
    {
        const Value& game_logic_config = json_doc["game_logic"];
        if(game_logic_config.HasMember("ip") && game_logic_config.HasMember("port"))
        {
            string game_logic_ip = game_logic_config["ip"].GetString();
            int game_logic_port = game_logic_config["port"].GetInt();
            
            g_pGameLogicClient = new GatewayClient();
            g_pGameLogicClient->Init(loop, game_logic_ip.c_str(), game_logic_port);
        }
    }
    
    //连接房间服
    if(json_doc.HasMember("room_logic"))
    {
        const Value& room_logic_config = json_doc["room_logic"];
        if(room_logic_config.HasMember("ip") && room_logic_config.HasMember("port"))
        {
            string room_loic_ip = room_logic_config["ip"].GetString();
            int room_logic_port = room_logic_config["port"].GetInt();
            
            g_pRoomLogicClient = new GatewayClient();
            g_pRoomLogicClient->Init(loop, room_loic_ip.c_str(), room_logic_port);
        }
    }
    
    return uv_run(loop, UV_RUN_DEFAULT);
}