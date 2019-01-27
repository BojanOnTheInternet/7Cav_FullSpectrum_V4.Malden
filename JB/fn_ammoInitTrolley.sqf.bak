/*

Initialize a trolley for use with the ammo transfer system.  This function builds on
JB_fnc_ammoInit, causing the trolley to show a pallet of ammo when transporting vehicle
ammo.

[vehicle] call JB_fnc_ammoInitTrolley;

	vehicle - the trolley to initialize.  Note that the trolley must be of types
			  Land_PalletTrolley_01_yellow_F or "Land_PalletTrolley_01_khaki_F"

See also JB_fnc_ammoInit and JB_fnc_ammoInitPlayer

*/

// The maximum weight that can be on the trolley (kg)
#define TROLLEY_LIMIT 2000
// The weight that can be on the trolley and still be pushed at a jog (kg)
#define TROLLEY_JOG_LIMIT 300

// state = [ammo-box]

JBAT_Start =
{
	params ["_unit"];

	private _state = [];

	private _ammoBox = "Land_Pallet_MilBoxes_F" createVehicle [random -10000, random -10000, 1000 + random 10000];
	_state set [0, _ammoBox];

	_ammoBox attachTo [_unit, [0.35, 0, -0.1]];
	_ammoBox setDir (-90);

	_state;
};

JBAT_Stop =
{
	params ["_unit", "_state"];

	private _ammoBox = _state select 0;
	if (not isNull _ammoBox) then
	{
		deleteVehicle _ammoBox;
		_state set [0, objNull];
	};
};

JBAT_StoresChanged =
{
	params ["_unit", "_stores"];

	private _state = _unit getVariable ["JBAT_State", nil];

	[_unit] call JBAT_SetTrolleyPushSpeed;

	if (count _stores == 0) then
	{
		if (!isNil "_state") then
		{
			[_unit, _state] call JBAT_Stop;
			_unit setVariable ["JBAT_State", nil];
		};
	}
	else
	{
		if (isNil "_state") then
		{
			_state = [_unit] call JBAT_Start;
			_unit setVariable ["JBAT_State", _state];
		};
	};
};

JBAT_TransportFilter =
{
	params ["_unit", "_candidate"];

	private _candidateType = typeOf _candidate;

	// Don't allow transport to a container unless the trolley is in the loading bay
	if (_candidateType == "B_Slingload_01_Ammo_F" && not (_unit inArea Base_Supply_Loading_Bay)) exitWith { false };

	// Only logistics specialists can transfer from trolley directly to other units
	if (not ([player] call JBA_IsLogisticsSpecialist) && _candidate != player) exitWith { false };
	
	// Otherwise, use the trolleys as desired
	([_candidate, _unit, 2] call JBA_IsNearUnit)
};

JBAT_PlayerTrolley =
{
	params ["_player"];

	private _trolley = objNull;
	{
		if (((typeOf _x) find "Land_PalletTrolley_01_") == 0) exitWith { _trolley = _x };
	} forEach (attachedObjects _player);

	_trolley;
};

JBAT_PushTrolleyCondition =
{
	params ["_unit", "_player"];

	if (not isNull (attachedTo _unit)) exitWith { false };

	if (vehicle _player != _player) exitWith { false };

	// Only the logistics class can use the trolleys
	if (not ([player] call JBA_IsLogisticsSpecialist)) exitWith { false };

	if ([_player] call JBA_PlayerIsTransportingAmmo) exitWith { false };

	true
};

JBAT_SetTrolleyPushSpeed =
{
	params ["_trolley"];

	private _stores = _trolley getVariable ["JBA_C_TransportStores", []];
	private _storesWeight = [_stores] call JBA_StoresMass;
	if (_storesWeight > TROLLEY_JOG_LIMIT) then
	{
		player forceWalk true;
	}
	else
	{
		player forceWalk false;
		player allowSprint false;
	};
};

JBAT_PushTrolley =
{
	params ["_trolley", "_player"];

	// Take ownership of the public trolley object.  Then wait for it to go local.  THEN attach and orient.
	if (not local _trolley) then
	{
		[[_trolley, _player], { (_this select 0) setOwner owner (_this select 1) }] remoteExec ["call", 2];
		[{ local _trolley }, 2.0] call JB_fnc_timeoutWaitUntil;
	};
	if (not local _trolley) exitWith {};

	_trolley attachTo [_player, [0,1,0.55]];
	_trolley setDir -90;

	[_trolley] call JBAT_SetTrolleyPushSpeed;

	private _releaseAction = _player addAction ["<t color='#FFFF99'>Release trolley</t>", { [_this select 0] call JBAT_ReleaseTrolley }, nil, 0];
	private _getInHandler = _player addEventHandler ["GetInMan", { [_this select 0] call JBAT_ReleaseTrolley }];
	private _killedHandler = _player addEventHandler ["Killed", { [_this select 0] call JBAT_ReleaseTrolley }];

	_player setVariable ["JBAT_TrolleyState", [_releaseAction, _getInHandler, _killedHandler]];
};

JBAT_ReleaseTrolley =
{
	params ["_player"];

	private _trolley = [_player] call JBAT_PlayerTrolley;

	if (not isNull _trolley) then
	{
		detach _trolley;
	};

	_player forceWalk false;
	_player allowSprint true;

	private _trolleyState = _player getVariable "JBAT_TrolleyState";
	_player setVariable ["JBAT_TrolleyState", nil];

	_player removeAction (_trolleyState select 0);
	_player removeEventHandler ["GetInMan", (_trolleyState select 1)];
	_player removeEventHandler ["Killed", (_trolleyState select 2)];
};

private _unit = param [0, objNull, [objNull]];

// A callback from the server when the _unit's stores are changed
_unit setVariable ["JBA_OnStoresChanged", JBAT_StoresChanged];

[_unit, TROLLEY_LIMIT, [10, { [_this select 0, _this select 1] call JBAT_TransportFilter }], []] call JB_fnc_ammoInit;

if (hasInterface) then
{
	_unit addAction ["<t color='#FFFF99'>Push trolley</t>", JBAT_PushTrolley, nil, 10, true, true, "", "[_target, _this] call JBAT_PushTrolleyCondition", 2];
};