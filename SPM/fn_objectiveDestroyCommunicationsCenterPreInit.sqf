/*
Copyright (c) 2017, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

SPM_CommunicationsCenter_RadioChatter =
[
	["a3\sounds_f\sfx\radio\ambient_radio2.wss", 9.733],
	["a3\sounds_f\sfx\radio\ambient_radio6.wss", 6.557],
	["a3\sounds_f\sfx\radio\ambient_radio8.wss", 11.638]
];

SPM_CommunicationsCenter_RadioNoise =
[
	["a3\dubbing_radio_f\sfx\radionoise1.ogg", 5.719],
	["a3\dubbing_radio_f\sfx\radionoise2.ogg", 5.719],
	["a3\dubbing_radio_f\sfx\radionoise3.ogg", 5.719]
];

OO_TRACE_DECL(SPM_ObjectiveDestroyCommunicationsCenter_CreateSatellitePhone) =
{
	params ["_objective", "_position", "_direction", "_indoor"];

	private _objectPosition = [];

	private _table = ["Land_CampingTable_small_F", _position, _direction, "can_collide"] call SPM_fnc_spawnVehicle;
	_table setMass (getMass _table * 0.5);

	_objectPosition = _position vectorAdd ([[0.000, 0.000, 0.845], _direction] call SPM_Util_RotatePosition2D);
	private _phone = ["Land_SatellitePhone_F", _objectPosition, _direction, "can_collide"] call SPM_fnc_spawnVehicle;
	_phone setMass (getMass _phone * 0.5);

	[_objective, _phone, _indoor] spawn
	{
		params ["_objective", "_phone", "_indoor"];

		scriptName "spawnSPM_ObjectiveDestroyCommunicationsCenter_CreateSatellitePhone";

		sleep 10; // Let the physics settle down before getting the phone's position
		private _startPosition = getPosASL _phone;

		private _noiseEndTime = 0;
		private _chatterEndTime = 0;
		private _radioNoise = [];
		private _radioChatter = [];

		while { alive _phone } do
		{
			if (diag_tickTime > _noiseEndTime) then
			{
				if (count _radioNoise == 0) then { _radioNoise = +SPM_CommunicationsCenter_RadioNoise };
				private _noise = _radioNoise deleteAt floor random count _radioNoise;
				playSound3D [_noise select 0, objNull, _indoor, _startPosition, 25, 1, 100];
				_noiseEndTime = diag_tickTime + (_noise select 1);
			};

			if (diag_tickTime > _chatterEndTime) then
			{
				if (count _radioChatter == 0) then { _radioChatter = +SPM_CommunicationsCenter_RadioChatter };
				private _chatter = _radioChatter deleteAt floor random count _radioChatter;
				playSound3D [_chatter select 0, objNull, _indoor, _startPosition, 5, 1, 100];
				_chatterEndTime = diag_tickTime + (_chatter select 1) + random 8;
			};

			if (getPosASL _phone distance _startPosition > 0.1) exitWith { };

			sleep 0.2;
		};

		OO_SET(_objective,ObjectiveDestroyCommunicationsCenter,_CommunicationsDeviceDestroyed,true);

		if (not isNull _phone) then
		{
			[_objective, [format ["%1 (%2)", ([] call OO_METHOD(_objective,MissionObjective,GetDescription)) select 0, "completed"]], "objective-status"] call OO_METHOD(_objective,Category,SendNotification);
		
			OO_SET(_objective,MissionObjective,State,"completed");

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

			waitUntil { sleep 1; isNull _phone }; // Keep it sparking and smoking until deleted

			{
				deleteVehicle _x;
			} forEach _particleObjects;
		};
	};

	OO_SET(_objective,ObjectiveDestroyCommunicationsCenter,_CommunicationsDevice,_phone);
	OO_GET(_objective,ObjectiveDestroyCommunicationsCenter,_CenterObjects) append [_table, _phone];

	_position
};

OO_TRACE_DECL(SPM_ObjectiveDestroyCommunicationsCenter_CreateSatelliteAntenna) =
{
	params ["_objective", "_position", "_direction", "_simulationEnabled"];

	private _antenna = ["Land_SatelliteAntenna_01_F", _position, _direction, "can_collide"] call SPM_fnc_spawnVehicle;
	_antenna enableSimulation _simulationEnabled;

	OO_GET(_objective,ObjectiveDestroyCommunicationsCenter,_CenterObjects) append [_antenna];

	_position
};

OO_TRACE_DECL(SPM_ObjectiveDestroyCommunicationsCenter_CreateSatellitePhoneAgainstWall) =
{
	params ["_objective", "_position", "_normal"];

	private _direction = -(_normal select 0) atan2 -(_normal select 1);

	[_objective, _position vectorAdd (_normal vectorMultiply 0.390), _direction, true] call SPM_ObjectiveDestroyCommunicationsCenter_CreateSatellitePhone;
};

OO_TRACE_DECL(SPM_ObjectiveDestroyCommunicationsCenter_CreateCamoflagedVehicle) =
{
	params ["_objective", "_position", "_direction"];

	private _objectPosition = [];

	_objectPosition = _position vectorAdd ([[0.000, 2.000, 0.000], _direction] call SPM_Util_RotatePosition2D);
	private _truck = ["O_Truck_02_box_F", _objectPosition, (_direction - 90) - 5 + random 10, "can_collide"] call SPM_fnc_spawnVehicle;
	_truck setRepairCargo 0; // Prevent players from repairing on the enemy vehicle
	[_objective, _truck] call OO_GET(_objective,Category,InitializeObject);

	private _camonet = ["CamoNet_OPFOR_big_F", _position, _direction, "can_collide"] call SPM_fnc_spawnVehicle;

	OO_GET(_objective,ObjectiveDestroyCommunicationsCenter,_CenterObjects) append [_camonet, _truck];

	_objectPosition = _position vectorAdd ([[3.275, -4.490, 0.000], _direction] call SPM_Util_RotatePosition2D);
	[_objective, _objectPosition, random 360, false] call SPM_ObjectiveDestroyCommunicationsCenter_CreateSatellitePhone;

	_objectPosition = _position vectorAdd ([[6.411, -5.500, 0.000], _direction] call SPM_Util_RotatePosition2D);
	[_objective, _objectPosition, 180, true] call SPM_ObjectiveDestroyCommunicationsCenter_CreateSatelliteAntenna;

	_position
};

OO_TRACE_DECL(SPM_ObjectiveDestroyCommunicationsCenter_CreateBuildingCenter) =
{
	params ["_objective"];

	private _garrison = OO_GETREF(_objective,ObjectiveDestroyCommunicationsCenter,Garrison);
	private _housedUnits = +OO_GET(_garrison,InfantryGarrisonCategory,HousedUnits);

	private _foundWall = false;
	private _wallPosition = [];
	private _wallNormal = [];
	private _roofPosition = [];

	private _building = objNull;

	while { not _foundWall && count _housedUnits > 0 } do
	{
		private _keyUnit = _housedUnits deleteAt floor random count _housedUnits;
		_building = [_keyUnit] call SPM_GetOccupyingUnitBuilding;

		if (not isNull _building) then
		{
			private _keyPositionASL = (getPosASL _keyUnit) vectorAdd [0, 0, 1];

			private _direction = 0;
			while { not _foundWall && _direction < 271 } do
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

				_direction = _direction + 90;
			};
		};
	};

	if (not _foundWall) exitWith { [] };

	[_objective, ASLtoATL _roofPosition vectorAdd [0, 0, -0.5], 180, false] call SPM_ObjectiveDestroyCommunicationsCenter_CreateSatelliteAntenna;
	[_objective, ASLtoATL _wallPosition, _wallNormal] call SPM_ObjectiveDestroyCommunicationsCenter_CreateSatellitePhoneAgainstWall;
};

OO_TRACE_DECL(SPM_ObjectiveDestroyCommunicationsCenter_CreateFieldCenter) =
{
	params ["_objective", "_area"];

	private _clearingRadius = 12.0;

	private _center = OO_GET(_area,StrongpointArea,Position);
	private _innerRadius = OO_GET(_area,StrongpointArea,InnerRadius);
	private _outerRadius = OO_GET(_area,StrongpointArea,OuterRadius);

	private _positions = [];
	while { _innerRadius <= _outerRadius } do
	{
		_positions = [_center, _innerRadius, _innerRadius + (_clearingRadius * 3.0), (_clearingRadius * 0.5)] call SPM_Util_SampleAreaGrid;
		[_positions, ["#GdtRoad", "#GdtWater"]] call SPM_Util_ExcludeSamplesBySurfaceType;
		[_positions, 10, 90] call SPM_Util_ExcludeSamplesBySurfaceIncline;
		[_positions, _clearingRadius, ["WALL", "BUILDING", "HOUSE", "ROCK", "ROAD"]] call SPM_Util_ExcludeSamplesByProximity;

		if (count _positions > 0) exitWith { };

		_innerRadius = _innerRadius + (_clearingRadius * 3.0);
	};

	private _position = if (count _positions == 0) then { _center } else { selectRandom _positions };

	private _blockingObjects = nearestTerrainObjects [_position, ["TREE", "SMALL TREE", "BUSH", "HIDE", "FENCE"], _clearingRadius, false, true];
	{
		_x hideObjectGlobal true;
	} forEach _blockingObjects;

	OO_SET(_objective,ObjectiveDestroyCommunicationsCenter,_BlockingObjects,_blockingObjects);

	[_objective, _position, -45 + random 90] call SPM_ObjectiveDestroyCommunicationsCenter_CreateCamoflagedVehicle
};

OO_TRACE_DECL(SPM_ObjectiveDestroyCommunicationsCenter_CreateCenter) =
{
	params ["_objective"];

	private _garrison = OO_GETREF(_objective,ObjectiveDestroyCommunicationsCenter,Garrison);
	if (OO_ISNULL(_garrison)) exitWith { false };

	if (count OO_GET(_garrison,ForceCategory,ForceUnits) == 0) exitWith { false };

	// Turn one of the members into an officer
	[_garrison] call SPM_Util_PromoteMemberToOfficer;

	private _strongpoint = OO_GETREF(_objective,Category,Strongpoint);

	// Try to put the center into a building occupied by the center infantry.  If that fails, create a field communications unit
	[_objective] call SPM_ObjectiveDestroyCommunicationsCenter_CreateBuildingCenter;

	if (count OO_GET(_objective,ObjectiveDestroyCommunicationsCenter,_CenterObjects) == 0) then
	{
		private _position = [_objective, OO_GET(_garrison,ForceCategory,Area)] call SPM_ObjectiveDestroyCommunicationsCenter_CreateFieldCenter;

		private _communicationsDevice = OO_GET(_objective,ObjectiveDestroyCommunicationsCenter,_CommunicationsDevice);

		private _guardableObject = [] call OO_CREATE(HeadquartersGuardableObject);
		OO_SET(_guardableObject,HeadquartersGuardableObject,Object,_communicationsDevice);

		private _guard = [_guardableObject, _garrison, -1] call OO_CREATE(GuardObjectCategory);
		[_guard] call OO_METHOD(_strongpoint,Strongpoint,AddCategory);
	};

	// Set up a flag
	private _centerObjects = OO_GET(_objective,ObjectiveDestroyCommunicationsCenter,_CenterObjects);
	private _flagpole = [_objective, getPos (_centerObjects select 0), 60] call SPM_Util_CreateFlagpole;
	OO_SET(_objective,ObjectiveDestroyCommunicationsCenter,_Flagpole,_flagpole);

	true
};

OO_TRACE_DECL(SPM_ObjectiveDestroyCommunicationsCenter_GetDescription) =
{
	params ["_objective"];

	OO_GET(_objective,ObjectiveDestroyCommunicationsCenter,_Description);
};

OO_TRACE_DECL(SPM_ObjectiveDestroyCommunicationsCenter_Create) =
{
	params ["_objective", "_garrison"];

	OO_SETREF(_objective,ObjectiveDestroyCommunicationsCenter,Garrison,_garrison);
};

OO_TRACE_DECL(SPM_ObjectiveDestroyCommunicationsCenter_Delete) =
{
	params ["_objective"];

	private _objects = OO_GET(_objective,ObjectiveDestroyCommunicationsCenter,_CenterObjects);
	while { count _objects > 0 } do
	{
		deleteVehicle (_objects deleteAt 0);
	};

	// Put back the objects we hid to make room for the field center
	{
		_x hideObjectGlobal false;
	} forEach OO_GET(_objective,ObjectiveDestroyCommunicationsCenter,_BlockingObjects);
};

SPM_ObjectiveDestroyCommunicationsCenter_Description =
"Communications centers rely on a satellite phone setup to maintain contact with their command infrastructure.  Use a grenade or other explosive to destroy the satellite phone.  Note that there are two types of communications centers.  The first is an urban center, which can be found inside a building.  The satellite dish
will be mounted to the roof and the satellite phone will be somewhere inside the building.  The second is a field center, which can be found under a large camoflaged netting next to a Zamak repair truck.  In both cases, you should be able to hear radio chatter when near the communications center.";

OO_TRACE_DECL(SPM_ObjectiveDestroyCommunicationsCenter_Update) =
{
	params ["_objective"];

	[] call OO_METHOD_PARENT(_objective,Category,Update,Category);

	switch (OO_GET(_objective,MissionObjective,State)) do
	{
		case "starting":
		{
			if ([_objective] call SPM_ObjectiveDestroyCommunicationsCenter_CreateCenter) then
			{
				OO_SET(_objective,MissionObjective,State,"active");

				private _objectiveDescription = [] call OO_METHOD(_objective,MissionObjective,GetDescription);
				[_objective, _objectiveDescription, "objective-description"] call OO_METHOD(_objective,Category,SendNotification);
			};
		};

		case "active": {};

		case "completed":
		{
			OO_SET(_objective,Category,UpdateTime,1e30);
		};
	};
};

private _description = ["Destroy communications center", "The enemy is using a satellite phone to contact their headquarters and request mobilization of reinforcements.  Destroy the phone with a hand grenade or other explosive."];

OO_BEGIN_SUBCLASS(ObjectiveDestroyCommunicationsCenter,MissionObjective);
	OO_OVERRIDE_METHOD(ObjectiveDestroyCommunicationsCenter,Root,Create,SPM_ObjectiveDestroyCommunicationsCenter_Create);
	OO_OVERRIDE_METHOD(ObjectiveDestroyCommunicationsCenter,Root,Delete,SPM_ObjectiveDestroyCommunicationsCenter_Delete);
	OO_OVERRIDE_METHOD(ObjectiveDestroyCommunicationsCenter,Category,Update,SPM_ObjectiveDestroyCommunicationsCenter_Update);
	OO_OVERRIDE_METHOD(ObjectiveDestroyCommunicationsCenter,MissionObjective,GetDescription,SPM_ObjectiveDestroyCommunicationsCenter_GetDescription);
	OO_DEFINE_PROPERTY(ObjectiveDestroyCommunicationsCenter,Garrison,"#REF",OO_NULL);
	OO_DEFINE_PROPERTY(ObjectiveDestroyCommunicationsCenter,_CommunicationsDevice,"OBJECT",objNull);
	OO_DEFINE_PROPERTY(ObjectiveDestroyCommunicationsCenter,_CommunicationsDeviceDestroyed,"BOOL",false);
	OO_DEFINE_PROPERTY(ObjectiveDestroyCommunicationsCenter,_CenterObjects,"ARRAY",[]);
	OO_DEFINE_PROPERTY(ObjectiveDestroyCommunicationsCenter,_BlockingObjects,"ARRAY",[]);
	OO_DEFINE_PROPERTY(ObjectiveDestroyCommunicationsCenter,_Flagpole,"OBJECT",objNull);
	OO_DEFINE_PROPERTY(ObjectiveDestroyCommunicationsCenter,_Description,"STRING",_description);
OO_END_SUBCLASS(ObjectiveDestroyCommunicationsCenter);