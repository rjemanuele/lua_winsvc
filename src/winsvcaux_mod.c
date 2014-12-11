#define LUA_LIB
#include "lua.h"
#include "lauxlib.h"

#include <windows.h>

static int dbgSleep(lua_State *L)
{
    DWORD t = luaL_checkunsigned(L, 1);
    Sleep(t);
    return 0;
}

static int lua_GetModuleFileName(lua_State *L)
{
    const char* handle = lua_tolstring(L, 1, NULL);
    TCHAR name[MAX_PATH + 1];
    DWORD ret = GetModuleFileName((HMODULE)handle, name, MAX_PATH + 1);
    if (ret > 0)
    {
        lua_pushstring(L, name);
        lua_pushnil(L);
    }
    else
    {
        lua_pushnil(L);
        lua_pushinteger(L, GetLastError());
    }
    return 2;
}

static const luaL_Reg winsvcauxlib[] = {
        { "dbgSleep", dbgSleep },
        { "GetModuleFileName", lua_GetModuleFileName },
        { NULL, NULL }
};

/*
** Open Windows Service Aux library
*/
LUALIB_API int luaopen_winsvcaux(lua_State *L) {
    luaL_register(L, "winsvcaux", winsvcauxlib);
    return 1;
}
