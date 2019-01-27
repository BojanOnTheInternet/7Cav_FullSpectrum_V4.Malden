// Requires JB_fnc_taruPodPreInit to be run in the mission pre-init

private _taru = param [0, objNull, [objNull]];
private _cargoTypes = param [1, [], [[]]];

if (not (_taru isKindOf "Heli_Transport_04_base_F")) exitWith {};

_this remoteExec ["JBTPI_SetupClient", 0, true] //JIP