HALO_AO =
{
	params ["_vehicle"];

	if (isNil "HALO_MissionAdvance" || { count HALO_MissionAdvance == 0 }) exitWith { ["", [0,0,0], 0] };

	private _startPosition = getPos player;

	private _distanceToBase = _startPosition distance (getPos Headquarters);
	private _distanceToDropPosition = (_startPosition distance (HALO_MissionAdvance select 0)) - (HALO_MissionAdvance select 1);

	private _vectorToDropPosition = _startPosition vectorFromTo (HALO_MissionAdvance select 0);
	private _dropPosition = _startPosition vectorAdd (_vectorToDropPosition vectorMultiply _distanceToDropPosition);

	_dropPosition set [2, 2000];

	// Assume a 200km/h trip
	private _nominalVehicleSpeedKMH = 200; // km/h
	private _nominalVehicleSpeedMS = _nominalVehicleSpeedKMH / 3600 * 1000; // m/s

	private _delayInSeconds = (_distanceToBase + _distanceToDropPosition) / _nominalVehicleSpeedMS;

	private _description = [_dropPosition] call SPM_Util_PositionDescription;

	[_description, _dropPosition, _delayInSeconds]
};

HALO_Base =
{
	params ["_vehicle"];

	private _startPosition = getPos player;

	private _distanceToBase = _startPosition distance (getPos Headquarters);
	private _distanceToDropPosition = _distanceToBase;

	private _dropPosition = getPos Headquarters;

	_dropPosition set [2, 2000];

	// Assume a 200km/h trip
	private _nominalVehicleSpeedKMH = 200; // km/h
	private _nominalVehicleSpeedMS = _nominalVehicleSpeedKMH / 3600 * 1000; // m/s

	private _delayInSeconds = (_distanceToBase + _distanceToDropPosition) / _nominalVehicleSpeedMS;

	["base", _dropPosition, _delayInSeconds]
};

if (not isServer) exitWith {};

#include "..\..\..\SPM\strongpoint.h"

HALO_S_MonitorMissionAdvance =
{
	_this spawn
	{
		scriptName "spawnHALO_S_MonitorMissionAdvance";

		private _advanceOperation = OO_NULL;
		private _code =
			{
				if (OO_GET(_x,Mission,MissionState) == "unresolved") exitWith { _advanceOperation = _x; true };
				false
			};

		private _advanceOperationPosition = [];

		while { true } do
		{
			// Find the advance operation by searching through MissionAdvances that are not resolved.  There should be only one.
			_advanceOperation = OO_NULL;
			OO_FOREACHINSTANCE(MissionAdvance,[],_code);

			if (OO_ISNULL(_advanceOperation)) then
			{
				if (count _advanceOperationPosition > 0) then
				{
					_advanceOperationPosition = [];
					missionNamespace setVariable ["HALO_MissionAdvance", [], true];
				};
			}
			else
			{
				private _strongpointPosition = OO_GET(_advanceOperation,Strongpoint,Position);
				if (count _strongpointPosition > 0) then
				{
					if (count _advanceOperationPosition == 0 || { _advanceOperationPosition distance2D _strongpointPosition > 1.0 }) then
					{
						_advanceOperationPosition = _strongpointPosition;
						missionNamespace setVariable ["HALO_MissionAdvance", [_strongpointPosition, OO_GET(_advanceOperation,Strongpoint,ActivityRadius)], true];
					};
				};
			};

			sleep 5;
		};
	};
};

if (isNil "HALO_Monitor") then { HALO_Monitor = [] call HALO_S_MonitorMissionAdvance };

[_this select 0,
	{
		(_this select 0) allowDamage false;
		(_this select 0) lockDriver true;
		(_this select 0) lockTurret [[0], true];
		(_this select 0) animateDoor ["door_rear_source", 1];
		(_this select 0) setVariable ["AT_DONOTTOW", true, true];
		[_this select 0] call JB_fnc_containerClear;
		{ (_this select 0) removeMagazine (_x select 0) } forEach magazinesAllTurrets (_this select 0);
		[[_this select 0], HALO_AO] call JB_fnc_haloInit;
	}
] call JB_fnc_respawnVehicleInitialize;
[_this select 0, 60] call JB_fnc_respawnVehicleWhenKilled;