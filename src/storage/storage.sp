#if defined _storage_methodmap_included
 #endinput
#endif
#define _storage_methodmap_included

enum FreeEvent_s {

    // memory is not freeing
    freeAfterRainOnThursday = 0,

    // memory freeing on success
    freeOnSuccess,
    
    // memory freeing anyway
    freeAnyway
}

#define JSON_INCLUDE_BUILDER

#include <jansson>

methodmap Storage < Handle {

    public Storage(const char[] location, const char[] auth, int duration, char[] error = NULL_STRING, int mlen = 0) {

        char path[PLATFORM_MAX_PATH];
        BuildPath(Path_SM, path, sizeof(path), "%s/%s.json", location, cleanAuth(auth));

        Json storage;
        if(!(storage = Json.JsonF(path, 0, error, mlen))) {
            storage = new Json("{}");
        }

        asJSONB(storage)
            .SetInt("expired", GetTime() + duration)
            .SetString("path", path);
        
        if(!storage.ToFile(path))
            LogMessage("Failed on write to: %s", path);

        return view_as<Storage>(storage);
    }

    public bool Write(const char[] key, const Json value, FreeEvent_s event = freeAfterRainOnThursday) {

        bool ok = asJSONO(this).Set(key, value);

        if(event == freeAnyway || (ok && event == freeOnSuccess))
            delete value;

        return ok;
    }

    public void Remove(const char[] key) {
        asJSONO(this).Remove(key);
    }

    public Json Read(const char[] key) {
        return asJSONO(this).Get(key);
    }

    public void Flush(const int flags = 0, const bool close = false) {
        
        char buffer[PLATFORM_MAX_PATH];
        
        if(asJSONO(this).GetString("path", buffer, sizeof(buffer)))
            asJSON(this).ToFile(buffer, flags, close);
    }

    property int Expired {
        public get() {
            return asJSONO(this).GetInt("expired");
        }
    }
}

char[] cleanAuth(const char[] auth) 
{
    static char buffer[PLATFORM_MAX_PATH];
    strcopy(buffer, sizeof(buffer), auth);

    ReplaceString(buffer, sizeof(buffer), ":", "");
    ReplaceString(buffer, sizeof(buffer), "[", "");
    ReplaceString(buffer, sizeof(buffer), "]", "");

    return buffer;
}