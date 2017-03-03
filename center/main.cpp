//
//  main.cpp
//  server
//
//  Created by 冯文斌 on 16/10/10.
//  Copyright © 2016年 kelvin. All rights reserved.
//

#include <uv.h>
#include "center_server.hpp"

int main() {
    
    uv_loop_t *loop = uv_default_loop();
    CenterServer *server = CenterServer::GetInstance();
    server->Init(loop);
    
    return uv_run(loop, UV_RUN_DEFAULT);
}