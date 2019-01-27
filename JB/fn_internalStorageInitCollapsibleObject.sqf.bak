// Initialize an object to be collapsible such that it is deleted when loaded into a container and recreated when unloaded
params [["_object", objNull, [objNull]], ["_init", {}, [{}]]];

if (isNull _object) exitWith {};

if (not isServer && hasInterface) exitWith {};

_object setVariable ["JB_IS_S_OBJECT_INIT", _init];
