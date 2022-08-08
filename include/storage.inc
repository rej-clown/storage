#if defined _storage_included
 #endinput
#endif
#define _storage_included

/*
 * @desc 
 * 
 * @param iClient   - Client index
 * @param key       - Key
 *
 * @return Json object(must be freed) or null
 */
native Json     storage_ReadValue(int iClient, const char[] key);

/*
 * @desc 
 * 
 * @param iClient   - Client index
 * @param key       - Key
 * @param value     - Json object with any data
 *
 * @return true on success
 */
native bool     storage_WriteValue(int iClient, const char[] key, Json value);

/*
 * @desc 
 * 
 * @param iClient   - Client index
 * @param key       - Key
 *
 * @return true on success?
 */
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
