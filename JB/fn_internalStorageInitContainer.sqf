params ["_container", "_volume", ["_objectFilter", [["All",true]], [[]]]];

if (not isServer && hasInterface) exitWith {};

[_container, _volume, _objectFilter] call JB_IS_S_InitContainer;

[_container] remoteExec ["JB_IS_ContainerAddActions", 0, true]; //JIP