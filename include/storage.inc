#if defined _storage_included
 #endinput
#endif
#define _storage_included

native Json     storage_ReadValue(int iClient, const char[] key);
native bool     storage_WriteValue(int iClient, const char[] key, Json value);
native bool     storage_RemoveValue(int iClient, const char[] key);

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

#if !defined REQUIRE_PLUGIN
public void __pl__storage_SetNTVOptional()
{
    MarkNativeAsOptional("storage_WriteValue");
    MarkNativeAsOptional("storage_ReadValue");
    MarkNativeAsOptional("storage_RemoveValue");
}
#endif
