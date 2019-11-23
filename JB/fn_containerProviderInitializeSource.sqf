params ["_source", "_containerType", "_abandonDistance", "_abandonDelay"];

if (not isServer) exitWith {};

[_source, _containerType, _abandonDistance, _abandonDelay] remoteExec ["JB_CG_SourceSetupClient", 0, true];