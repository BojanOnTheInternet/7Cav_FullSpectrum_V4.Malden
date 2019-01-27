private _unit = param [0, objNull, [objNull]];
private _fuelLinePositions = param [1, [], [[]]];
private _fuelCapacity = param [2, 1000, [0]];
private _fuelFlowRate = param [3, 4.5, [0]];

if (not isServer) exitWith {};

_unit setVariable ["JBF_FuelCapacity", _fuelCapacity, true]; // global
_unit setVariable ["JBF_FuelRemaining", _fuelCapacity, true]; // global

_this remoteExec ["JBF_SetupClient", 0, true]; //JIP
