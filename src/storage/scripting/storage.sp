#pragma newdecls required

#include <jansson>

public Plugin myinfo = 
{
	name = "Storage [json]",
	author = "rej.chev?",
	description = "...",
	version = "1.1.0",
	url = "discord.gg/ChTyPUG"
};

JsonObject jConfig;
int lastClean;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{ 
    CreateNative("storage_WriteValue",  Native_Write);
    CreateNative("storage_ReadValue",   Native_Read);
    CreateNative("storage_RemoveValue", Native_Remove);

    RegPluginLibrary("storage");
    return APLRes_Success
}

public any Native_Write(Handle h, int a) {
    int iClient = GetNativeCell(1);

    if(!jConfig)
        return false;

    Json storage;
    if(!(storage = getStorage(iClient))) {
        storage = new Json("{}");
        asJSONO(storage).SetInt("expired", (iClient) ? (GetTime() + jConfig.GetInt("duration")) : -1);
    }
    
    char key[64];
    GetNativeString(2, key, sizeof(key));

    Json value = asJSON(GetNativeCell(3));

    asJSONO(storage).Set(key, value);
    storage.ToFile(getClientStoragePath(getAuth(iClient)), 0);

    delete storage;
    return 1;
}

public any Native_Read(Handle h, int a) {
    int iClient = GetNativeCell(1);

    Json storage;
    if((storage = getStorage(iClient)) == null)
        return storage;
    
    char key[64];
    GetNativeString(2, key, sizeof(key));

    if(!asJSONO(storage).HasKey(key)) {
        delete storage;
        return storage;
    }

    Json value;

    value = asJSONO(storage).Get(key);
    delete storage;

    return value;
}

public any Native_Remove(Handle h, int a) {
    int iClient = GetNativeCell(1);

    Json storage;

    if((storage = getStorage(iClient)) == null)
        return false;
    
    char key[64];
    GetNativeString(2, key, sizeof(key));

    if(!asJSONO(storage).HasKey(key)) {
        delete storage;
        return false;
    }

    asJSONO(storage).Remove(key);
    storage.ToFile(getClientStoragePath(getAuth(iClient)), 0);
    delete storage;

    return true;
}

public void OnMapStart() {
    if(jConfig)
        delete jConfig;
    
    static char obj[PLATFORM_MAX_PATH]  = "configs/storage/settings.json";

    if(obj[0] == 'c')
        BuildPath(Path_SM, obj, sizeof(obj), obj);
    
    if(!FileExists(obj))
        SetFailState("Config file is not exists: %s", obj);

    jConfig = asJSONO(Json.JsonF(obj, 0));

    lastClean = GetGameTickCount();
}

public void OnClientPutInServer(int iClient) {
    static char path[PLATFORM_MAX_PATH];
    path = getClientStoragePath(getAuth(iClient));

    Json storage;
    if((storage = getStorage(iClient)) == null)
        return;

    asJSONO(storage).SetInt("expired", (iClient) ? (GetTime() + jConfig.GetInt("duration")) : -1);

    storage.ToFile(path, 0);
    delete storage;

    if(lastClean <= GetGameTickCount()) {
        lastClean = GetGameTickCount() + (10 * GetTicks());
        CleanStoragePath();
    }
}

stock char[] getAuth(int iClient) {
    char auth[66];
    GetClientAuthId(iClient, AuthId_Engine, auth, sizeof(auth));
    return auth;
}

char[] getClientStoragePath(const char[] auth) {
    static char buffer[PLATFORM_MAX_PATH];
    strcopy(buffer, sizeof(buffer), auth);

    ReplaceString(buffer, sizeof(buffer), ":", "");
    ReplaceString(buffer, sizeof(buffer), "[", "");
    ReplaceString(buffer, sizeof(buffer), "]", "");

    Format(buffer, sizeof(buffer), "%s/%s.json", getLocation(), buffer);

    return buffer;
}

stock Json getStorage(int iClient) {
    char path[PLATFORM_MAX_PATH];
    path = getClientStoragePath(getAuth(iClient));

    if(!FileExists(path))
        return null;

    return Json.JsonF(path, 0);
}

char[] getLocation() {
    static char location[PLATFORM_MAX_PATH] = "data/ccprocessor/storage";

    if(location[0] == 'd')
        BuildPath(Path_SM, location, sizeof(location), location);

    if(!DirExists(location))
        CreateDirectory(location, 0x1ED);

    return location;
}

int GetTicks() {
    return RoundFloat(1/GetTickInterval());
}

void CleanStoragePath() {
    DirectoryListing dirs;
    if(!(dirs = OpenDirectory(getLocation())))
        return;

    static int time;
    static JsonObject jsObject;
    static FileType type;
    static char path[PLATFORM_MAX_PATH];

    while(ReadDirEntry(dirs, path, sizeof(path), type)) {
        if(type != FileType_File || path[0] == '.')
            continue;

        if(StrContains(path, "example", false) != -1)
            continue;

        Format(path, sizeof(path), "%s/%s", getLocation(), path);

        if(!(jsObject = asJSONO(Json.JsonF(path, 0))))
            continue;

        time = (jsObject.HasKey("expired")) ? jsObject.GetInt("expired") : 0;
        
        if(time != -1 && GetTime() >= time)
            DeleteFile(path);

        delete jsObject;
    }

    delete dirs;
}