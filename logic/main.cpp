//
//  main.cpp
//  server
//
//  Created by 冯文斌 on 16/10/11.
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
#include "center_client.hpp"
#include "db_client_manager.hpp"
#include "game_logic_server.hpp"

using namespace rapidjson;

int main() {
    
    g_pFileUtil = new FileUtil;
    g_pDBClientMgr = new KDBClientMgr;
    
    string sz_config;
    bool is_ok = g_pFileUtil->ReadFile("config.json", sz_config);
    if(!is_ok)
    {
        cout << "read config failed." << endl;
        exit(1);
    }
    
    uv_loop_t *loop = uv_default_loop();
    GameLogicServer *server = GameLogicServer::GetInstance();
    server->Init(loop);
    
    Document json_doc;
    json_doc.Parse(sz_config.c_str());
    
    //连接登录服
    if(json_doc.HasMember("center_server"))
    {
        int nServerType = json_doc["logic_server_type"].GetInt();
        const Value& center_server_config = json_doc["center_server"];
        if(center_server_config.HasMember("ip") && center_server_config.HasMember("port"))
        {
            string center_server_ip = center_server_config["ip"].GetString();
            int center_server_port = center_server_config["port"].GetInt();
            
            g_pCenterLogicClient = new CenterClient();
            g_pCenterLogicClient->Init(loop, center_server_ip.c_str(), center_server_port, nServerType);
        }
    }
    return uv_run(loop, UV_RUN_DEFAULT);
}