#if defined _storage_included
 #endinput
#endif
#define _storage_included

enum FreeEvent_s {

    // memory is not freeing
    freeAfterRainOnThursday = 0,

    // memory freeing on success
    freeOnSuccess,
    
    // memory freeing anyway
    freeAnyway
}

#include <jansson>

forward Action OnStorageExpired(Storage& storage);

methodmap Storage < Handle {

    public native bool Write(const char[] key, const Json value, FreeEvent_s event = freeAfterRainOnThursday);

    public native Json Read(const char[] key);

    public native void Remove(const char[] key);

    public native void Save(const int flags = 0, const bool closeHandle = false);

    property int Expired {
        public native get();
    }
}

methodmap Storages {

    // must be freed via delete or CloseHandle
    public static native Storage GetStorage(const char[] auth, char[] error = NULL_STRING, int mlen = 0);

}


public SharedPlugin __pl_storage= 
{
    name = "storage",
    file = "storage.smx",
#if defined REQUIRE_PLUGIN
    required = 1
#else
    required = 0
#endif
};
