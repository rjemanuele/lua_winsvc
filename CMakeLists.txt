cmake_minimum_required(VERSION 3.0)

project (lua_winsvc)

find_package (lua)

set(winsvc_srcdir ${CMAKE_CURRENT_SOURCE_DIR}/src)

add_library (lua_winsvc ${winsvc_srcdir}/winsvc_mod.c)
add_library (lua_winsvcaux ${winsvc_srcdir}/winsvcaux_mod.c)

target_include_directories (lua_winsvc PUBLIC ${LUA_INCLUDE_DIR} ${winsvc_srcdir})
target_include_directories (lua_winsvcaux PUBLIC ${LUA_INCLUDE_DIR} ${winsvc_srcdir})
