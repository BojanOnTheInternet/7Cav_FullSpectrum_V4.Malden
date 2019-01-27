private _vehicles = param [0, [], [[]]];
private _targetCode = param [1, {}, [{}]];

if (count _vehicles == 0) exitWith {};

_this remoteExec ["HALO_SetupClient", 0, true]; //JIP
