#define LUA_LIB
#include "lua.h"
#include "lauxlib.h"

#include <windows.h>

static int lua_RegisterServiceCtrlHandler(lua_State *L)
{
    const char* svcname = luaL_checklstring(L, 1, NULL);
    int SvcCtrlHandler = luaL_ref(L, 2); // convert this to a c func
    SERVICE_STATUS_HANDLE h = RegisterServiceCtrlHandler(svcname, SvcCtrlHandler);
    if (h != 0)
    {
        lua_pushinteger(L, h);
        lua_pushnil(L);
    }
    else
    {
        lua_pushnil(L);
        lua_pushinteger(L, GetLastError());
    }
    return 2;
}

static const luaL_Reg winsvclib[] = {
        { "RegisterServiceCtrlHandler", lua_RegisterServiceCtrlHandler },
        { NULL, NULL }
};

#define SETLITERAL(v) (lua_pushliteral(L, #v), lua_pushliteral(L, v), lua_settable(L, -3))
#define SETINT(v) (lua_pushliteral(L, #v), lua_pushinteger(L, v), lua_settable(L, -3))

/*
** Open Windows service library
*/
LUALIB_API int luaopen_winsvc(lua_State *L) {
    luaL_register(L, "winsvc", winsvclib);

    SETINT(ERROR);
    SETINT(NO_ERROR);

    SETLITERAL(SERVICES_ACTIVE_DATABASE);
    SETLITERAL(SERVICES_FAILED_DATABASE);
    SETINT(SC_GROUP_IDENTIFIER);

    SETINT(SERVICE_NO_CHANGE);

    SETINT(SERVICE_ACTIVE);
    SETINT(SERVICE_INACTIVE);
    SETINT(SERVICE_STATE_ALL);
    return 1;
}
