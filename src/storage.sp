#pragma newdecls required

#include "storage/storage.sp"

public Plugin myinfo = 
{
	name = "Storage [json]",
	author = "rej.chev?",
	description = "...",
	version = "2.0.1",
	url = "discord.gg/ChTyPUG"
};

int iDuration;

GlobalForward onStorageExpired;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{ 
    CreateNative("Storages.GetStorage",     Native_GetStorage);

    CreateNative("Storage.Write",           Native_Write);
    CreateNative("Storage.Read",            Native_Read);
    CreateNative("Storage.Remove",          Native_Remove);
    CreateNative("Storage.Save",            Native_Flush);
    CreateNative("Storage.Expired.get",     Native_Expired);

    onStorageExpired = new GlobalForward(
        "OnStorageExpired", ET_Hook, Param_CellByRef
    );

    RegPluginLibrary("storage");
    return APLRes_Success
}

public any Native_GetStorage(Handle h, int a) 
{
    char auth[64];
    GetNativeString(1, auth, sizeof(auth));

    Storage storage;
    int mlen = GetNativeCell(3);
    char error[MAX_NAME_LENGTH];
    
    if(!(storage = new Storage("data/storage", auth, iDuration, error, (mlen < MAX_NAME_LENGTH) ? mlen : MAX_NAME_LENGTH)) && mlen)
        SetNativeString(2, error, (mlen < MAX_NAME_LENGTH) ? mlen : MAX_NAME_LENGTH);

    return storage;
}

public any Native_Write(Handle h, int a) 
{
    Storage storage;
    
    if(!(storage = view_as<Storage>(GetNativeCell(1))))
        return false;

    char key[PLATFORM_MAX_PATH];
    GetNativeString(2, key, sizeof(key));

    return storage.Write(key, view_as<Json>(GetNativeCell(3)), view_as<FreeEvent_s>(GetNativeCell(4)));
}

public any Native_Read(Handle h, int a) 
{
    Storage storage;
    
    if(!(storage = view_as<Storage>(GetNativeCell(1))))
        return storage;

    char key[PLATFORM_MAX_PATH];
    GetNativeString(2, key, sizeof(key));

    return storage.Read(key);
}

public any Native_Remove(Handle h, int a) 
{
    Storage storage;
    
    if(!(storage = view_as<Storage>(GetNativeCell(1))))
        return 0;

    char key[PLATFORM_MAX_PATH];
    GetNativeString(2, key, sizeof(key));

    storage.Remove(key);

    return 0;
}

public any Native_Flush(Handle h, int a) 
{
    Storage storage;
    
    if(!(storage = view_as<Storage>(GetNativeCell(1))))
        return 0;

    storage.Flush(GetNativeCell(2), GetNativeCell(3));

    return 0;
}

public any Native_Expired(Handle h, int a) 
{
    Storage storage;
    
    if(!(storage = view_as<Storage>(GetNativeCell(1))))
        return -1;

    return storage.Expired;
}

Action OnStorageExpired(const GlobalForward fwd, Storage& storage) 
{
    Action what;

    Call_StartForward(fwd);
    Call_PushCellRef(storage);
    Call_Finish(what);

    return what;
}

public void OnMapStart() {
    
    static char path[PLATFORM_MAX_PATH] = "configs/storage/settings.json";

    if(path[0] == 'c')
        BuildPath(Path_SM, path, sizeof(path), "%s", path);
    
    Json json;
    char error[PLATFORM_MAX_PATH];

    if(!(json = Json.JsonF(path, 0, error, sizeof(error)))) {

        if(error[0])
            SetFailState(error);

        return;
    }

    iDuration = asJSONO(json).GetInt("duration", true);

    CleanStorages();
}


void CleanStorages()  {

    static char dir[PLATFORM_MAX_PATH] = "data/storage";

    if(dir[0] == 'd')
        BuildPath(Path_SM, dir, sizeof(dir), dir);

    if(!DirExists(dir))
        return;

    DirectoryListing dirs;
    if(!(dirs = OpenDirectory(dir)))
        return;

    int time = GetTime();

    FileType type;
    Storage storage;
    char path[PLATFORM_MAX_PATH];

    while(ReadDirEntry(dirs, path, sizeof(path), type)) {
        
        if(type != FileType_File || path[0] == '.')
            continue;

        if(StrContains(path, "example", false) != -1 || strncmp(path[strlen(path) - strlen(".json")], ".json", strlen(".json")) != 0)
            continue;

        Format(path, sizeof(path), "%s/%s", dir, path);
    
        if(!(storage = view_as<Storage>(Json.JsonF(path))) || (time >= storage.Expired && OnStorageExpired(onStorageExpired, storage) == Plugin_Continue))
            DeleteFile(path);

        delete storage;
    }

    delete dirs;
}