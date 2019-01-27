#define TRANSPORT_LIST_UPDATE_INTERVAL 1
#define TRANSPORT_LOAD_RANGE 10

TRANSPORT_C_UpdateTransports =
{
	params ["_cargo"];

	private _updateTime = _cargo getVariable ["TRANSPORT_TransportUpdateTime", 0];
	if (diag_tickTime > _updateTime) then
	{
		private _transports = (_cargo nearEntities TRANSPORT_LOAD_RANGE) select { count (_x getVariable ["TRANSPORT_InternalStorage", []]) > 0 };
		_transports apply { [getText (configFile > "CfgVehicles" >> typeOf _x >> "displayName"), _x ] };
		_transports sort true;

		_cargo setVariable ["TRANSPORT_Transports", _transports]
		_cargo setVariable ["TRANSPORT_TransportUpdateTime", diag_tickTime + TRANSPORT_LIST_UPDATE_INTERVAL];
	};
};

TRANSPORT_C_LoadCargoCondition =
{
	params ["_target", "_caller", "_index"];

	[_target] call TRANSPORT_C_UpdateTransports;

	private _transports = _target getVariable ["TRANSPORT_Transports", []];

	if (_index >= _transports) exitWith { false };

	private _ui = _target getVariable "TRANSPORT_UI";
	_target setUserActionText [_ui select 1 select _index, format ["Load %1 into %2", _ui select 0, _transports select _index select 0]];

	true
};

TRANSPORT_C_LoadCargo =
{
	params ["_target", "_caller", "_id", "_arguments"];

	_arguments params ["_index"];

	private _transports = _target getVariable "TRANSPORT_Transports";

	if (_index >= count _transports) exitWith {};

	[_target, _transports select _index select 1] remoteExec ["TRANSPORT_S_LoadCargo", 2] }
};

TRANSPORT_C_SetupCargoActions =
{
	private ["_cargo", "_description"];

	private _actions = [];
	_actions pushBack (_cargo addAction ["", TRANSPORT_C_LoadCargo, [count _actions], 5, false, true, '', format ["[_target, _caller, %1] call TRANSPORT_C_LoadCargoCondition", count _actions], 2]);
	_actions pushBack (_cargo addAction ["", TRANSPORT_C_LoadCargo, [count _actions], 5, false, true, '', format ["[_target, _caller, %1] call TRANSPORT_C_LoadCargoCondition", count _actions], 2]);
	_actions pushBack (_cargo addAction ["", TRANSPORT_C_LoadCargo, [count _actions], 5, false, true, '', format ["[_target, _caller, %1] call TRANSPORT_C_LoadCargoCondition", count _actions], 2]);
	_actions pushBack (_cargo addAction ["", TRANSPORT_C_LoadCargo, [count _actions], 5, false, true, '', format ["[_target, _caller, %1] call TRANSPORT_C_LoadCargoCondition", count _actions], 2]);

	_cargo setVariable ["TRANSPORT_UI", [_description, _actions]]
};

// Server maintains list on the transport vehicle indicating which locations have which cargo objects. (put a capacity on the locations)
// When that list changes, it notifies all clients (JIP) of the new configuration via a variable on the transport vehicle (alternately, a routine to add or remove cargo from the list and JIP that)
// List should include capacities so that the client can at least skip vehicles that would never have room for a cargo object of a given capacity.
// Clients work off the client list that the server gives them to know what's available to offload, but always assume they can load more into a transport vehicle and just let server reject attempts

// Per spot in a transport: [position, capacity, contents]
// TRANSPORT_C_AlterTransportContents(_transport, _index, true/false)

TRANSPORT_C_SetupTransportActions =
{
	private ["_transport"];

	private _storage = _target getVariable "TRANSPORT_InternalStorage";

	private _actions = [];
	{
		// "Offload"
		_actions pushBack (_transport addAction ["", TRANSPORT_C_UnloadCargo, [_forEachIndex], 5, false, true, '', format ["[_target, _caller, %1] call TRANSPORT_C_UnloadCargoCondition", count _actions], 2]);
	} forEach _storage;

	_transport setVariable ["TRANSPORT_UI", [_actions]]
};