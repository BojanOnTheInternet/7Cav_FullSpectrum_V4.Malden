/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

// Note that we don't use getHit or getHitIndex as the building object has no selections
SPM_RadioCommunicationCenter_HandleDamage_Urban =
{
	params ["_object", "_selection", "_damage", "_source", "_projectile", "_partIndex", "_instigator"];

	switch (true) do
	{
		// Attacks from vehicles are ignored
		case (not isNull _instigator && { vehicle _instigator != _instigator }): { _damage = damage _object };
		// Thrown grenades and launched smoke grenades
		case (_projectile isKindOf "Grenade"): { _damage = damage _object + (getNumber (configFile >> "CfgAmmo" >> _projectile >> "indirectHit")) * 0.04 };
		// Launched HE grenades
		case (_projectile isKindOf "GrenadeCore"): { _damage = damage _object + (getNumber (configFile >> "CfgAmmo" >> _projectile >> "indirectHit")) * 0.04 };
		// Explosives and rockets do normal damage
		case (_projectile isKindOf "TimeBombCore" || _projectile isKindOf "RocketBase"): { _damage = _damage };
		// Everything else does normal damage
		default { _damage = _damage };
	};

	_damage
};

// Destroying either tower or building will destroy the other as well
SPM_RadioCommunicationCenter_Killed_Urban =
{
	params ["_object"];

	private _partner = _object getVariable ["SPM_CommunicationCenter_Partner", objNull];
	if (not isNull _partner) then { _partner setDamage 1 };
};

OO_TRACE_DECL(SPM_RadioCommunicationCenter_CreateUrbanCenter) =
{
	params ["_category", "_area"];

	private _radius = OO_GET(_area,StrongpointArea,OuterRadius);
	private _buildings = nearestObjects [OO_GET(_area,StrongpointArea,Position), ["House"], _radius];
	private _isUrbanEnvironment = [_buildings, pi * _radius * _radius] call SPM_Util_IsUrbanEnvironment;

	if (not _isUrbanEnvironment) exitWith { false };

	private _clearing = [_area, 5.0] call SPM_CommunicationCenter_FindClearing;
	private _position = _clearing select 0;
	private _blockingObjects = _clearing select 1;

	OO_SET(_category,RadioCommunicationCenterCategory,_BlockingObjects,_blockingObjects);

	private _direction = [_position, 0] call SPM_Util_EnvironmentAlignedDirection;

	private _building = ["Land_TBox_F", _position, _direction] call SPM_fnc_spawnVehicle;
	[_category, _building] call OO_GET(_category,Category,InitializeObject);

	private _tower = ["Land_TTowerSmall_1_F", _building modelToWorld [2.32,-0.58,0.0], _direction] call SPM_fnc_spawnVehicle;
	[_category, _tower] call OO_GET(_category,Category,InitializeObject);

	_building addEventHandler ["HandleDamage", SPM_RadioCommunicationCenter_HandleDamage_Urban];
	_building addEventHandler ["Killed", SPM_RadioCommunicationCenter_Killed_Urban];
	_building setVariable ["SPM_CommunicationCenter_Partner", _tower];

	_tower addEventHandler ["HandleDamage", SPM_RadioCommunicationCenter_HandleDamage_Urban];
	_tower addEventHandler ["Killed", SPM_RadioCommunicationCenter_Killed_Urban];
	_tower setVariable ["SPM_CommunicationCenter_Partner", _building];

	[_building, "CRCC", "RADIO"] call TRACE_SetObjectString;

	[_category, _building] spawn
	{
		params ["_category", "_building"];

		scriptName "SPM_RadioCommunicationCenter_CreateUrbanCenter";

		private _buildingPosition = getPos _building;

		// Run comms chatter
		[_building, false] remoteExec ["SPM_CommunicationCenter_CommunicationChatter", 0, true];//JIP

		// Wait until building is destroyed
		waitUntil { sleep 0.5; not alive _building };

		private _ruins = _buildingPosition nearObjects ["Land_TBox_ruins_F", 2];
		if (count _ruins > 0) then { OO_GET(_category,RadioCommunicationCenterCategory,_CenterObjects) pushBack (_ruins select 0) };

		OO_SET(_category,CommunicationCenterCategory,CommunicationsOnline,false);
	};

	private _objects = [_building, _tower];
	OO_SET(_category,RadioCommunicationCenterCategory,_CenterObjects,_objects);

	OO_SET(_category,CommunicationCenterCategory,CommunicationDevice,_building);

	true
};

// One hit by an approved weapon from an attacker on foot will disable the generator
SPM_RadioCommunicationCenter_HandleDamage_Field_Vehicle =
{
	params ["_object", "_selection", "_damage", "_source", "_projectile", "_partIndex", "_instigator"];

	if (vehicle _instigator == _instigator && { _projectile isKindOf "Grenade" || _projectile isKindOf "GrenadeCore" || _projectile isKindOf "TimeBombCore" || _projectile isKindOf "RocketBase" }) then
	{
		private _generator = _object getVariable ["SPM_RadioCommunicationCenter_Generator", objNull];
		if (not isNull _generator) then { _generator setDamage 1 };
	};

	_damage
};

SPM_RadioCommunicationCenter_Killed_Field_Vehicle =
{
	params ["_vehicle"];

	{
		deleteVehicle _x;
	} forEach attachedObjects _vehicle;
};

OO_TRACE_DECL(SPM_RadioCommunicationCenter_CreateFieldCenter) =
{
	params ["_category", "_area"];

	private _clearing = [_area, 5.0] call SPM_CommunicationCenter_FindClearing;
	private _position = _clearing select 0;
	private _blockingObjects = _clearing select 1;

	OO_SET(_category,RadioCommunicationCenterCategory,_BlockingObjects,_blockingObjects);

	private _direction = [_position, random 360] call SPM_Util_EnvironmentAlignedDirection;

	private _vehicle = ["I_C_Van_02_vehicle_F", _position, _direction] call SPM_fnc_spawnVehicle;
	_vehicle setVehicleLock "locked";

	_vehicle animateDoor ["door_3_source", 1]; 
	_vehicle animateDoor ["door_4_source", 1]; 
	_vehicle animate ["spare_tyre_holder_hide", 0]; 
	_vehicle animate ["ladder_hide", 0]; 
	_vehicle animate ["roof_rack_hide", 0]; 
	_vehicle animate ["rearsteps_hide", 0]; 
	_vehicle animate ["front_protective_frame_hide", 0]; 

	private _generator = ["Land_PortableGenerator_01_F", call SPM_Util_RandomSpawnPosition, 0] call SPM_fnc_spawnVehicle;
	_generator attachto [_vehicle, [0,0,-0.55], ""];
	_generator setdir 270;
	[_category, _generator] call OO_GET(_category,Category,InitializeObject);

	[_generator, "CRCC", "RADIO"] call TRACE_SetObjectString;

	_vehicle setVariable ["SPM_RadioCommunicationCenter_Generator", _generator];
	_vehicle addEventHandler ["HandleDamage", SPM_RadioCommunicationCenter_HandleDamage_Field_Vehicle];
	_vehicle addEventHandler ["Killed", SPM_RadioCommunicationCenter_Killed_Field_Vehicle];
	_vehicle addEventHandler ["Deleted", SPM_RadioCommunicationCenter_Killed_Field_Vehicle];

	private _battery1 = ["Land_CarBattery_01_F", call SPM_Util_RandomSpawnPosition, 0, ""] call SPM_fnc_spawnVehicle;
	_battery1 attachto [_vehicle, [0.8,-2.6,-0.85], ""];
	_battery1 setdir 275;
	private _battery2 = ["Land_CarBattery_01_F", call SPM_Util_RandomSpawnPosition, 0, ""] call SPM_fnc_spawnVehicle;
	_battery2 attachto [_vehicle, [0.5,-2.55,-0.85], ""];
	_battery2 setdir 265;

	private _toolkit = ["Item_ToolKit", call SPM_Util_RandomSpawnPosition, 0, ""] call SPM_fnc_spawnVehicle;
	_toolkit attachto [_vehicle, [0.8,-2.63,-0.4], ""];
	_toolkit setvectordirandup [vectorNormalized [0,1,1], vectorNormalized [0,0,1]];

	private _crate = ["Land_WoodenCrate_01_F", call SPM_Util_RandomSpawnPosition, 0, ""] call SPM_fnc_spawnVehicle;
	_crate attachto [_vehicle, [-0.27,-2.3,-0.6], ""];
	_crate setDir 10;

	[_category, _generator] spawn
	{
		params ["_category", "_generator"];

		scriptName "SPM_RadioCommunicationCenter_CreateFieldCenter";

		// Run comms chatter
		[_generator, false] remoteExec ["SPM_CommunicationCenter_CommunicationChatter", 0, true];//JIP

		// Wait until building is destroyed
		waitUntil { sleep 0.5; not alive _generator };

		OO_SET(_category,CommunicationCenterCategory,CommunicationsOnline,false);
	};

	private _objects = [_vehicle, _generator, _battery1, _battery2, _toolkit, _crate];
	OO_SET(_category,RadioCommunicationCenterCategory,_CenterObjects,_objects);

	OO_SET(_category,CommunicationCenterCategory,CommunicationDevice,_generator);

	true
};

OO_TRACE_DECL(SPM_RadioCommunicationCenter_CreateCenter) =
{
	params ["_category"];

	private _garrison = OO_GETREF(_category,CommunicationCenterCategory,Garrison);

	if (not ([_category, OO_GET(_garrison,ForceCategory,Area)] call SPM_RadioCommunicationCenter_CreateUrbanCenter)) then
	{
		[_category, OO_GET(_garrison,ForceCategory,Area)] call SPM_RadioCommunicationCenter_CreateFieldCenter;
	};

	true
};

OO_TRACE_DECL(SPM_RadioCommunicationCenter_Create) =
{
	params ["_category", "_garrison"];

	OO_SETREF(_category,CommunicationCenterCategory,Garrison,_garrison);
};

OO_TRACE_DECL(SPM_RadioCommunicationCenter_Delete) =
{
	params ["_category"];

	private _objects = OO_GET(_category,RadioCommunicationCenterCategory,_CenterObjects);
	while { count _objects > 0 } do
	{
		deleteVehicle (_objects deleteAt 0);
	};

	// Put back the objects we hid to make room for the field center
	{
		_x hideObjectGlobal false;
	} forEach OO_GET(_category,RadioCommunicationCenterCategory,_BlockingObjects);
};

OO_TRACE_DECL(SPM_RadioCommunicationCenter_Update) =
{
	params ["_category"];

	[] call OO_METHOD_PARENT(_category,Category,Update,CommunicationCenterCategory);

	if (count OO_GET(_category,RadioCommunicationCenterCategory,_CenterObjects) == 0) then
	{
		if ([_category] call SPM_RadioCommunicationCenter_CreateCenter) then
		{
			OO_SET(_category,CommunicationCenterCategory,CommunicationsOnline,true);
			OO_SET(_category,Category,UpdateTime,1e30);
		};
	};
};

OO_BEGIN_SUBCLASS(RadioCommunicationCenterCategory,CommunicationCenterCategory);
	OO_OVERRIDE_METHOD(RadioCommunicationCenterCategory,Root,Create,SPM_RadioCommunicationCenter_Create);
	OO_OVERRIDE_METHOD(RadioCommunicationCenterCategory,Root,Delete,SPM_RadioCommunicationCenter_Delete);
	OO_OVERRIDE_METHOD(RadioCommunicationCenterCategory,Category,Update,SPM_RadioCommunicationCenter_Update);
	OO_DEFINE_PROPERTY(RadioCommunicationCenterCategory,_CenterObjects,"ARRAY",[]);
	OO_DEFINE_PROPERTY(RadioCommunicationCenterCategory,_BlockingObjects,"ARRAY",[]);
OO_END_SUBCLASS(RadioCommunicationCenterCategory);
