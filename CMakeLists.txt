#定义项目名称：1ST_LOGIC_SERVER, 编译语言为:C, Cpp
PROJECT(1ST_LOGIC_SERVER C CXX)
#设置Cmake的最低版本为 2.8
CMAKE_MINIMUM_REQUIRED(VERSION 2.8)
#设置变量PROJECT_ROOT_PATH为当前路径
SET(PROJECT_ROOT_PATH ".")
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
include(CheckCXXCompilerFlag)  
CHECK_CXX_COMPILER_FLAG("-std=c++11" COMPILER_SUPPORTS_CXX11)  
if(COMPILER_SUPPORTS_CXX11)  
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")  
else()  
     message(STATUS "The compiler ${CMAKE_CXX_COMPILER} has no C++11 support.
Please use a different C++ compiler.")  
endif() 
MESSAGE(STATUS "CMake version is ${CMAKE_VERSION}")
MESSAGE(STATUS "CMake compiler version is ${CMAKE_CXX_COMPILER}")
#设置头文件搜索路径
#第三方库头文件
INCLUDE_DIRECTORIES("${PROJECT_ROOT_PATH}/third_party/")
INCLUDE_DIRECTORIES("${PROJECT_ROOT_PATH}/third_party/lua-5.1.5/src/")
INCLUDE_DIRECTORIES("${PROJECT_ROOT_PATH}/third_party/rapidjson/")
INCLUDE_DIRECTORIES("${PROJECT_ROOT_PATH}/third_party/libuv/include/")
INCLUDE_DIRECTORIES("${PROJECT_ROOT_PATH}/third_party/mysql_connector/include/")
INCLUDE_DIRECTORIES("${PROJECT_ROOT_PATH}/third_party/hiredis/")
#开发用到的头文件
INCLUDE_DIRECTORIES("${PROJECT_ROOT_PATH}/db_proxy/")
INCLUDE_DIRECTORIES("${PROJECT_ROOT_PATH}/common/")
INCLUDE_DIRECTORIES("${PROJECT_ROOT_PATH}/vm/")
INCLUDE_DIRECTORIES("${PROJECT_ROOT_PATH}/util/")
INCLUDE_DIRECTORIES("${PROJECT_ROOT_PATH}/protobuf/")
INCLUDE_DIRECTORIES("${PROJECT_ROOT_PATH}/tcp/")
#增加子路径
ADD_SUBDIRECTORY(./db_proxy)
ADD_SUBDIRECTORY(./common)
ADD_SUBDIRECTORY(./vm)
ADD_SUBDIRECTORY(./util)
ADD_SUBDIRECTORY(./protobuf)
ADD_SUBDIRECTORY(./tcp)
#设置链接时搜索的库文件路径
LINK_DIRECTORIES("${PROJECT_ROOT_PATH}/lib/centos/")
LINK_DIRECTORIES("${PROJECT_ROOT_PATH}/db_proxy/")
LINK_DIRECTORIES("${PROJECT_ROOT_PATH}/common/")
LINK_DIRECTORIES("${PROJECT_ROOT_PATH}/vm/")
LINK_DIRECTORIES("${PROJECT_ROOT_PATH}/util/")
LINK_DIRECTORIES("${PROJECT_ROOT_PATH}/protobuf/")
LINK_DIRECTORIES("${PROJECT_ROOT_PATH}/tcp/")
#执行构建逻辑服
ADD_EXECUTABLE(logic ./logic/main.cpp ./vm/lua_engine.cpp
db_proxy/db_client.cpp  db_proxy/db_client_manager.cpp
db_proxy/mysql_client.cpp  db_proxy/redis_client.cpp common/db_buffer.cpp
common/knetpacket.cpp  common/ktimer.cpp  common/net_buffer.cpp
util/file_util.cpp protobuf/google.pb.cc tcp/center_client.cpp
tcp/game_logic_server.cpp  tcp/gateway_server.cpp   tcp/tcp_client.cpp
tcp/center_server.cpp  tcp/gateway_client.cpp     tcp/tcp_base_server.cpp
tcp/tcp_session.cpp)
#执行文件链接库
TARGET_LINK_LIBRARIES(logic lua dl uv mysqlclient protobuf hiredis db_proxy common vm util proto_message tcp)
#执行构建网关
ADD_EXECUTABLE(gateway ./gateway/main.cpp ./vm/lua_engine.cpp
db_proxy/db_client.cpp  db_proxy/db_client_manager.cpp
db_proxy/mysql_client.cpp  db_proxy/redis_client.cpp common/db_buffer.cpp
common/knetpacket.cpp  common/ktimer.cpp  common/net_buffer.cpp
util/file_util.cpp protobuf/google.pb.cc tcp/center_client.cpp
tcp/game_logic_server.cpp  tcp/gateway_server.cpp   tcp/tcp_client.cpp
tcp/center_server.cpp  tcp/gateway_client.cpp     tcp/tcp_base_server.cpp
tcp/tcp_session.cpp)
#执行文件链接库
TARGET_LINK_LIBRARIES(gateway lua dl uv mysqlclient protobuf hiredis db_proxy common vm util proto_message tcp)
#执行构建中心服
ADD_EXECUTABLE(center ./center/main.cpp ./vm/lua_engine.cpp
db_proxy/db_client.cpp  db_proxy/db_client_manager.cpp
db_proxy/mysql_client.cpp  db_proxy/redis_client.cpp common/db_buffer.cpp
common/knetpacket.cpp  common/ktimer.cpp  common/net_buffer.cpp
util/file_util.cpp protobuf/google.pb.cc tcp/center_client.cpp
tcp/game_logic_server.cpp  tcp/gateway_server.cpp   tcp/tcp_client.cpp
tcp/center_server.cpp  tcp/gateway_client.cpp     tcp/tcp_base_server.cpp
tcp/tcp_session.cpp)
#执行文件链接库
TARGET_LINK_LIBRARIES(center lua dl uv mysqlclient protobuf hiredis db_proxy common vm util proto_message tcp)


