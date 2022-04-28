#pragma newdecls required

#include <jansson>
#include <packager>

public Plugin myinfo = 
{
	name = "Storage [json]",
	author = "rej.chev?",
	description = "...",
	version = "1.3.0",
	url = "discord.gg/ChTyPUG"
};

static const char artifact[] = "json_storage";

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{ 
    CreateNative("storage_WriteValue",  Native_Write);
    CreateNative("storage_ReadValue",   Native_Read);
    CreateNative("storage_RemoveValue", Native_Remove);

    RegPluginLibrary("storage");
    return APLRes_Success
}

public any Native_Write(Handle h, int a) 
{
    int iClient = GetNativeCell(1);

    Json storage;
    if(!Packager.HasPackage(iClient))
        return false;

    storage = getStorage(iClient);

    if(!storage)
        storage = (new JsonBuilder("{}"))
                    .SetInt(
                        "expired", 
                        ((iClient) 
                            ? (GetTime() + GetDuration()) 
                            : -1)
                    )
                    .Build();
    
    char key[64];
    GetNativeString(2, key, sizeof(key));

    asJSONO(storage).Set(key, asJSON(GetNativeCell(3)));
    storage.ToFile(getClientStoragePath(getAuth(iClient)), 0);

    delete storage;
    return true;
}

public any Native_Read(Handle h, int a) {
    int iClient = GetNativeCell(1);

    Json storage;
    if(!Packager.HasPackage(iClient))
        return storage;

    storage = getStorage(iClient);
    if(!storage)
        return storage;
    
    char key[64];
    GetNativeString(2, key, sizeof(key));

    if(!asJSONO(storage).HasKey(key) || (!JSONO_TYPE_EQUAL(storage, key, JSON_ARRAY) && !JSONO_TYPE_EQUAL(storage, key, JSON_OBJECT))) {
        delete storage;
        return storage;
    }

    Json value = asJSONO(storage).Get(key);
    delete storage;

    return value;
}

public any Native_Remove(Handle h, int a) {
    int iClient = GetNativeCell(1);

    Json storage;
    if(!Packager.HasPackage(iClient))
        return storage;

    storage = getStorage(iClient);
    if(!storage)
        return storage;
    
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

public void pckg_OnPackageAvailable(int iClient)
{
    if(!iClient)
    {
        static char obj[PLATFORM_MAX_PATH]  = "configs/storage/settings.json";

        if(obj[0] == 'c')
            BuildPath(Path_SM, obj, sizeof(obj), obj);
        
        if(!FileExists(obj))
            SetFailState("Config file is not exists: %s", obj);

        JsonObject jConfig = asJSONO(Json.JsonF(obj, 0));

        Packager.SetArtifact(iClient, artifact, jConfig);
        delete jConfig;
    }

    Json storage = getStorage(iClient);

    if(!storage)
        return;

    asJSONO(storage).SetInt(
        "expired",
        ((iClient) 
            ? (GetTime() + GetDuration())
            : -1)
    );

    storage.ToFile(getClientStoragePath(getAuth(iClient)), 0);
    delete storage;

    if(!iClient)
        CleanStoragePath();
}

stock char[] getAuth(int iClient) 
{
    char szAuth[66];
    JsonObject clientPackage;
    if((clientPackage = Packager.GetPackage(iClient)))
        clientPackage.GetString("auth", szAuth, sizeof(szAuth));

    delete clientPackage;

    return szAuth;
}

char[] getClientStoragePath(const char[] auth) 
{
    static char buffer[PLATFORM_MAX_PATH];
    strcopy(buffer, sizeof(buffer), auth);

    ReplaceString(buffer, sizeof(buffer), ":", "");
    ReplaceString(buffer, sizeof(buffer), "[", "");
    ReplaceString(buffer, sizeof(buffer), "]", "");

    Format(buffer, sizeof(buffer), "%s/%s.json", getLocation(), buffer);

    return buffer;
}

stock Json getStorage(int iClient) 
{
    Json j = null;

    if(FileExists(getClientStoragePath(getAuth(iClient))))
        j = Json.JsonF(getClientStoragePath(getAuth(iClient)), 0);
    
    return j;
}

char[] getLocation() {
    static char location[PLATFORM_MAX_PATH] = "data/ccprocessor/storage";

    if(location[0] == 'd')
        BuildPath(Path_SM, location, sizeof(location), location);

    if(!DirExists(location))
        CreateDirectory(location, 0x1ED);

    return location;
}

void CleanStoragePath() {
    DirectoryListing dirs;
    if(!(dirs = OpenDirectory(getLocation())))
        return;

    int time;
    JsonObject jsObject;
    FileType type;
    char path[PLATFORM_MAX_PATH];

    while(ReadDirEntry(dirs, path, sizeof(path), type)) {
        time = 0;

        if(type != FileType_File || path[0] == '.')
            continue;

        if(StrContains(path, "example", false) != -1 || strncmp(path[strlen(path) - strlen(".json")], ".json", strlen(".json")) != 0)
            continue;

        Format(path, sizeof(path), "%s/%s", getLocation(), path);

        jsObject = asJSONO(Json.JsonF(path, 0));
        if(!jsObject)
            continue;

        if(jsObject.HasKey("expired") && JSONO_TYPE_EQUAL(jsObject, "expired", JSON_INTEGER))
            time = jsObject.GetInt("expired");
    
        if(time != -1 && GetTime() >= time)
            DeleteFile(path);

        delete jsObject;
    }

    delete dirs;
}

stock int GetDuration()
{
    int duration;

    Json o;
    if(Packager.HasArtifact(0, artifact) && (o = asJSON(Packager.GetArtifact(0, artifact))))
        duration = asJSONO(o).GetInt("duration");

    delete o;

    return duration;
}