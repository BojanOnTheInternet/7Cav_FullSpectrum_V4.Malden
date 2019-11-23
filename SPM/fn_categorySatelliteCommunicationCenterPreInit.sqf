/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

// The box is invulnerable, but if the box is struck by damage from a grenade or an explosive, that's a signal that the phone should be knocked out.
SPM_SatelliteCommunicationCenter_HandleDamage_Box =
{
	params ["_object", "_selection", "_damage", "_source", "_projectile", "_partIndex", "_instigator"];

	if (_projectile isKindOf "Grenade" || _projectile isKindOf "GrenadeCore" || _projectile isKindOf "TimeBombCore") then
	{
		private _phone = _object getVariable ["SPM_SatelliteCommunicationCenter_Phone", objNull];
		if (not isNull _phone) then { _phone setDamage 1 };
	};

	0 // Invulnerable
};

// If the box is killed, then the phone is killed.  This should only happen if Zeus kills the box.
SPM_SatelliteCommunicationCenter_Killed_Box =
{
	params ["_object"];

	private _phone = _object getVariable ["SPM_SatelliteCommunicationCenter_Phone", objNull];
	if (not isNull _phone) then { _phone setDamage 1 };
};

SPM_SatelliteCommunicationCenter_Deleted_Phone =
{
	params ["_object"];

	{
		deleteVehicle _x;
	} forEach (_object getVariable ["SPM_SatelliteCommunicationCenter_Particles", []]);
};

OO_TRACE_DECL(SPM_SatelliteCommunicationCenter_CreateSatellitePhone) =
{
	params ["_category", "_position", "_direction", "_indoor"];

	private _objectPosition = [];

	private _box = ["Box_CSAT_Equip_F", call SPM_Util_RandomSpawnPosition, _direction + 270] call SPM_fnc_spawnVehicle;
	[_category, _box] call OO_GET(_category,Category,InitializeObject);

	private _phone = ["Land_SatellitePhone_F", call SPM_Util_RandomSpawnPosition, 0] call SPM_fnc_spawnVehicle;
	[_category, _phone] call OO_GET(_category,Category,InitializeObject);

	[_box] call JB_fnc_containerClear;
	[_box] call JB_fnc_containerLock;
	_box setVariable ["SPM_SatelliteCommunicationCenter_Phone", _phone];
	_box addEventHandler ["HandleDamage", SPM_SatelliteCommunicationCenter_HandleDamage_Box];
	_box addEventHandler ["Killed", SPM_SatelliteCommunicationCenter_Killed_Box];

	_phone attachTo [_box, [0, -0.1 + random 0.2, 0.55], ""];
	_phone setDir (85 + random 10);

	[_phone, "CSCC", "SATELLITE"] call TRACE_SetObjectString;

	_box setPos _position;

	[_category, _phone, _indoor] spawn
	{
		params ["_category", "_phone", "_indoor"];

		scriptName "SPM_SatelliteCommunicationCenter_CreateSatellitePhone";

		// Run comms chatter
		[_phone, _indoor] remoteExec ["SPM_CommunicationCenter_CommunicationChatter", 0, true];//JIP

		// Wait until building is destroyed
		waitUntil { sleep 0.5; not alive _phone };

		OO_SET(_category,CommunicationCenterCategory,CommunicationsOnline,false);

		if (not isNull _phone) then
		{
			detach _phone;

			private _particleObject = objNull;
			private _particleObjects = [];

			_particleObject = "#particlesource" createVehicle (getPos _phone);
			_particleObject setParticleClass "Flare1"; // Flare1 or WreckSmokeSmall
			_particleObject attachTo [_phone, [0,0,0]];
			_particleObjects pushBack _particleObject;

			for "_i" from 1 to 3 do
			{
				_particleObject = "#particlesource" createVehicle (getPos _phone);
				_particleObject setParticleClass "AvionicsSparks";
				_particleObject attachTo [_phone, [-0.20 + random 0.4, -0.15 + random 0.3, 0.0]];
				_particleObjects pushBack _particleObject;
			};

			_phone setVariable ["SPM_SatelliteCommunicationCenter_Particles", _particleObjects];
			_phone addEventHandler ["Deleted", SPM_SatelliteCommunicationCenter_Deleted_Phone];
		};
	};

	OO_SET(_category,CommunicationCenterCategory,CommunicationDevice,_phone);
	OO_GET(_category,SatelliteCommunicationCenterCategory,_CenterObjects) append [_box, _phone];

	_position
};

OO_TRACE_DECL(SPM_SatelliteCommunicationCenter_CreateSatelliteAntenna) =
{
	params ["_category", "_position", "_direction", "_simulationEnabled"];

	private _antenna = ["Land_SatelliteAntenna_01_F", _position, _direction] call SPM_fnc_spawnVehicle;
	_antenna enableSimulation _simulationEnabled;

	OO_GET(_category,SatelliteCommunicationCenterCategory,_CenterObjects) append [_antenna];

	_position
};

OO_TRACE_DECL(SPM_SatelliteCommunicationCenter_CreateSatellitePhoneAgainstWall) =
{
	params ["_category", "_position", "_normal"];

	private _direction = -(_normal select 0) atan2 -(_normal select 1);

	[_category, _position vectorAdd (_normal vectorMultiply 0.390), _direction, true] call SPM_SatelliteCommunicationCenter_CreateSatellitePhone;
};

OO_TRACE_DECL(SPM_SatelliteCommunicationCenter_CreateCamoflagedVehicle) =
{
	params ["_category", "_position", "_direction"];

	private _objectPosition = [];

	private _truckType = OO_GET(_category,SatelliteCommunicationCenterCategory,TruckType);
	private _camoNetType = OO_GET(_category,SatelliteCommunicationCenterCategory,CamoNetType);

	_objectPosition = _position vectorAdd ([[0.000, 2.000, 0.000], _direction] call SPM_Util_RotatePosition2D);
	private _truck = [_truckType, _objectPosition, (_direction - 90) - 5 + random 10] call SPM_fnc_spawnVehicle;
	_truck setRepairCargo 0; // Prevent players from repairing on the enemy vehicle
	[_category, _truck] call OO_GET(_category,Category,InitializeObject);

	private _camoNet = [_camoNetType, _position, _direction] call SPM_fnc_spawnVehicle;

	OO_GET(_category,SatelliteCommunicationCenterCategory,_CenterObjects) append [_camoNet, _truck];

	_objectPosition = _position vectorAdd ([[3.275, -4.490, 0.000], _direction] call SPM_Util_RotatePosition2D);
	[_category, _objectPosition, random 360, false] call SPM_SatelliteCommunicationCenter_CreateSatellitePhone;

	_objectPosition = _position vectorAdd ([[6.411, -5.500, 0.000], _direction] call SPM_Util_RotatePosition2D);
	[_category, _objectPosition, 180, true] call SPM_SatelliteCommunicationCenter_CreateSatelliteAntenna;

	_position
};

OO_TRACE_DECL(SPM_SatelliteCommunicationCenter_CreateBuildingCenter) =
{
	params ["_category"];

	private _garrison = OO_GETREF(_category,CommunicationCenterCategory,Garrison);
	private _garrisonSize = count OO_GET(_garrison,ForceCategory,ForceUnits);
	private _group = [2 max round (_garrisonSize * 0.064)] call OO_METHOD(_garrison,InfantryGarrisonCategory,BeginHouseDuty);
	if (isNull _group) exitWith { false };

	[_garrison, leader _group] call SPM_Util_PromoteMemberToOfficer;
	OO_SET(_category,SatelliteCommunicationCenterCategory,_HouseDutyGroup,_group);

	private _housedUnits = units _group;

	private _foundWall = false;
	private _wallPosition = [];
	private _wallNormal = [];
	private _roofPosition = [];

	private _building = [_housedUnits select 0] call SPM_Occupy_GetOccupierBuilding;

	while { not _foundWall && count _housedUnits > 0 } do
	{
		private _keyUnit = _housedUnits deleteAt floor random count _housedUnits;
		private _keyPositionASL = (getPosASL _keyUnit) vectorAdd [0, 0, 1];

		for "_direction" from 0 to 270 step 90 do
		{
			private _ray = [0, (cos ((getDir _building) + _direction)) * 10, 0];

			private _intersections = lineIntersectsSurfaces [_keyPositionASL, _keyPositionASL vectorAdd _ray, _keyUnit];
			if (count _intersections > 0 && { _intersections select 0 select 2 == _building }) then
			{
				private _width = 2.0;
				private _depth = 1.5;

				private _intersection = _intersections select 0 select 0;
				private _normal = _intersections select 0 select 1;
				private _parallel = [-(_normal select 1), _normal select 0, _normal select 2];

				private _clear = true;
				private _scan = _intersection vectorAdd (_parallel vectorMultiply -(_width / 2.0)) vectorAdd (_normal vectorMultiply _depth);
				for "_i" from 1 to 5 do
				{
					_intersections = lineIntersectsSurfaces [_scan, _scan vectorAdd _ray];
					if (count _intersections == 0 || { _intersections select 0 select 2 != _building }) exitWith { _clear = false };
					_scan = _scan vectorAdd (_parallel vectorMultiply (_width / 4.0));
				};

				if (_clear) then
				{
					private _insideBuilding = _intersection vectorAdd (_normal vectorMultiply 3.0);

					_intersections = lineIntersectsSurfaces [_insideBuilding vectorAdd [0,0,30], _insideBuilding];
					if (count _intersections > 0 && { _intersections select 0 select 2 == _building }) then
					{
						_foundWall = true;
						_wallPosition = _intersection vectorAdd [0, 0, -1] vectorAdd (_normal vectorMultiply 0.1);
						_wallNormal = _normal;
						_roofPosition = _intersections select 0 select 0;
					};
				};
			};

			if (_foundWall) exitWith {};
		};
	};

	if (not _foundWall) exitWith
	{
		[_group] call OO_METHOD(_garrison,InfantryGarrisonCategory,EndHouseDuty);
		OO_SET(_category,SatelliteCommunicationCenterCategory,_HouseDutyGroup,grpNull);
		false
	};

	[_category, ASLtoATL _roofPosition vectorAdd [0, 0, -0.5], 180, false] call SPM_SatelliteCommunicationCenter_CreateSatelliteAntenna;
	[_category, ASLtoATL _wallPosition, _wallNormal] call SPM_SatelliteCommunicationCenter_CreateSatellitePhoneAgainstWall;

	true
};

OO_TRACE_DECL(SPM_SatelliteCommunicationCenter_CreateFieldCenter) =
{
	params ["_category", "_area"];

	private _clearing = [_area, 12.0] call SPM_CommunicationCenter_FindClearing;
	private _position = _clearing select 0;
	private _blockingObjects = _clearing select 1;

	OO_SET(_category,SatelliteCommunicationCenterCategory,_BlockingObjects,_blockingObjects);

	[_category, _position, -45 + random 90] call SPM_SatelliteCommunicationCenter_CreateCamoflagedVehicle
};

OO_TRACE_DECL(SPM_SatelliteCommunicationCenter_CreateCenter) =
{
	params ["_category"];

	private _garrison = OO_GETREF(_category,CommunicationCenterCategory,Garrison);
	if (OO_ISNULL(_garrison)) exitWith { false };

	if (count OO_GET(_garrison,ForceCategory,ForceUnits) == 0) exitWith { false };

	private _strongpoint = OO_GETREF(_category,Category,Strongpoint);

	// Try to put the center into a building occupied by the center infantry.  If that fails, create a field communications unit
	if (not ([_category] call SPM_SatelliteCommunicationCenter_CreateBuildingCenter)) then
	{
		[_category, OO_GET(_garrison,ForceCategory,Area)] call SPM_SatelliteCommunicationCenter_CreateFieldCenter;
	};

	true
};

OO_TRACE_DECL(SPM_SatelliteCommunicationCenter_Create) =
{
	params ["_category", "_garrison"];

	OO_SETREF(_category,CommunicationCenterCategory,Garrison,_garrison);
};

OO_TRACE_DECL(SPM_SatelliteCommunicationCenter_Delete) =
{
	params ["_category"];

	private _objects = OO_GET(_category,SatelliteCommunicationCenterCategory,_CenterObjects);
	while { count _objects > 0 } do
	{
		deleteVehicle (_objects deleteAt 0);
	};

	// Put back the objects we hid to make room for the field center
	{
		_x hideObjectGlobal false;
	} forEach OO_GET(_category,SatelliteCommunicationCenterCategory,_BlockingObjects);
};

OO_TRACE_DECL(SPM_SatelliteCommunicationCenter_Update) =
{
	params ["_category"];

	[] call OO_METHOD_PARENT(_category,Category,Update,CommunicationCenterCategory);

	if (count OO_GET(_category,SatelliteCommunicationCenterCategory,_CenterObjects) == 0) then
	{
		if ([_category] call SPM_SatelliteCommunicationCenter_CreateCenter) then
		{
			OO_SET(_category,CommunicationCenterCategory,CommunicationsOnline,true);
			OO_SET(_category,Category,UpdateTime,1e30);
		};
	};
};

OO_BEGIN_SUBCLASS(SatelliteCommunicationCenterCategory,CommunicationCenterCategory);
	OO_OVERRIDE_METHOD(SatelliteCommunicationCenterCategory,Root,Create,SPM_SatelliteCommunicationCenter_Create);
	OO_OVERRIDE_METHOD(SatelliteCommunicationCenterCategory,Root,Delete,SPM_SatelliteCommunicationCenter_Delete);
	OO_OVERRIDE_METHOD(SatelliteCommunicationCenterCategory,Category,Update,SPM_SatelliteCommunicationCenter_Update);
	OO_DEFINE_PROPERTY(SatelliteCommunicationCenterCategory,TruckType,"STRING","O_Truck_02_box_F");
	OO_DEFINE_PROPERTY(SatelliteCommunicationCenterCategory,CamoNetType,"STRING","CamoNet_OPFOR_big_F");
	OO_DEFINE_PROPERTY(SatelliteCommunicationCenterCategory,_HouseDutyGroup,"GROUP",grpNull);
	OO_DEFINE_PROPERTY(SatelliteCommunicationCenterCategory,_CenterObjects,"ARRAY",[]);
	OO_DEFINE_PROPERTY(SatelliteCommunicationCenterCategory,_BlockingObjects,"ARRAY",[]);
OO_END_SUBCLASS(SatelliteCommunicationCenterCategory);
