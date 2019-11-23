/*
Copyright (c) 2019, John Buehler & Bojan
Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"


OO_TRACE_DECL(SPM_SAMCategory_CreateSAMUnit) = 
{
	params ["_type", "_position", "_direction", "_special"];

	// Need to spawn the vehicle in to get it assigned to the right side
	private _vehicle = ([call SPM_Util_RandomSpawnPosition, 0, _type, EAST] call bis_fnc_spawnvehicle) select 0;

	// Enable datalink for radar -> SAM comms
	_vehicle setVehicleRadar 1;
	_vehicle setVehicleReceiveRemoteTargets true;
	_vehicle setVehicleReportRemoteTargets true;

	_vehicle setCombatMode "RED";

	_vehicle setDir _direction;
	[_vehicle, _position] call SPM_Util_SetPosition;

	[[_vehicle]] call SERVER_CurateEditableObjects;


	_vehicle setVariable ["SPM_SpawnTime", diag_tickTime];
	_vehicle addEventHandler ["Fired", {
		params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_gunner"];
		_unit setVehicleAmmo 1;	
		
		// Limit how fast the launcher will fire
		[_unit] spawn {
			params ["_v"];
			_v setCombatMode "BLUE";
			sleep random [5, 20, 30];
			_v setCombatMode "RED";
		};	
	}];

	_vehicle
};

OO_TRACE_DECL(SPM_SAMCategory_CreateSamSiteObjects) =
{
	params ["_position", "_direction", "_samObjects"];

	private _objectPosition = [];

	_objectPosition = _position vectorAdd ([[7,7,0.2], _direction] call SPM_Util_RotatePosition2D);
	_samObjects pushBack (["O_SAM_System_04_F", _objectPosition, _direction, ""] call SPM_SAMCategory_CreateSAMUnit);

	_objectPosition = _position vectorAdd ([[-7,-7,0.2], _direction] call SPM_Util_RotatePosition2D);
	_samObjects pushBack (["O_SAM_System_04_F", _objectPosition, _direction + 180, ""] call SPM_SAMCategory_CreateSAMUnit);

	_objectPosition = _position vectorAdd ([[7,-7,0.2], _direction] call SPM_Util_RotatePosition2D);
	_samObjects pushBack (["O_Radar_System_02_F", _objectPosition, _direction + 60, ""] call SPM_SAMCategory_CreateSAMUnit);

	_objectPosition = _position vectorAdd ([[-7,7,0.2], _direction] call SPM_Util_RotatePosition2D);
	_samObjects pushBack (["O_Radar_System_02_F", _objectPosition, _direction - 60, ""] call SPM_SAMCategory_CreateSAMUnit);
};

OO_TRACE_DECL(SPM_SAMCategory_CreateSamSite) =
{
	params ["_category"];

	private _area = OO_GET(_category,SAMCategory,Area);
	private _center = OO_GET(_area,StrongpointArea,Position);
	private _innerRadius = OO_GET(_area,StrongpointArea,InnerRadius);
	private _outerRadius = OO_GET(_area,StrongpointArea,OuterRadius);

	private _positions = [];
	while { true } do
	{
		// Find a spot clear of this stuff
		_positions = [_center, _innerRadius, _outerRadius, 10] call SPM_Util_SampleAreaGrid;
		[_positions, ["#GdtRoad", "#GdtWater", "#GdtConcrete"]] call SPM_Util_ExcludeSamplesBySurfaceType;
		[_positions, 20, 90] call SPM_Util_ExcludeSamplesBySurfaceIncline;
		[_positions, 20.0, ["FENCE", "WALL", "BUILDING", "HOUSE", "ROCK", "ROAD", "LANDVEHICLE", "TREE"]] call SPM_Util_ExcludeSamplesByProximity;

		if (count _positions > 0) exitWith {};

		diag_log format ["SPM_SAMCategory_CreateSamSite: Unable to create SAM site %1, %2, %3", _center, _innerRadius, _outerRadius];
		_innerRadius = _outerRadius;
		_outerRadius = _outerRadius + 50;
	};

	if (count _positions == 0) exitWith { };

	private _position = [_positions, _center] call SPM_Util_ClosestPosition;

	// Remove miscellaneous items
	private _blockingObjects = nearestTerrainObjects [_position, ["TREE", "SMALL TREE", "BUSH", "HIDE"], 10, false, true];
	{
		_x hideObjectGlobal true;
	} forEach _blockingObjects;
	OO_SET(_category,SAMCategory,_BlockingObjects,_blockingObjects);

	private _direction = [_position, 0] call SPM_Util_EnvironmentAlignedDirection;

	private _samObjects = [];
	private _return = [_position, _direction,_samObjects] call SPM_SAMCategory_CreateSamSiteObjects;
	OO_SET(_category,SAMCategory,SAMObjects,_samObjects);

};

OO_TRACE_DECL(SPM_SAMCategory_Update) =
{
	params ["_category"];

	[] call OO_METHOD_PARENT(_category,Category,Update,Category);

	if (count OO_GET(_category,SAMCategory,SAMObjects) == 0) then
	{
		[_category] call SPM_SAMCategory_CreateSamSite;

		OO_SET(_category,Category,UpdateTime,1e30);
	};

};

OO_TRACE_DECL(SPM_SAMCategory_Delete) =
{
	params ["_category"];

	[] call OO_METHOD_PARENT(_category,Root,Delete,Category);

	{
		if (not isNull _x) then { deleteVehicle _x };
	} forEach OO_GET(_category,SAMCategory,SAMObjects);

	private _blockingObjects = OO_GET(_category,SAMCategory,_BlockingObjects);
	{
		_x hideObjectGlobal false;
	} forEach _blockingObjects;

};

OO_TRACE_DECL(SPM_SAMCategory_Create) =
{
	params ["_category", "_area"];
	OO_SET(_category,SAMCategory,Area,_area);
};

OO_BEGIN_SUBCLASS(SAMCategory,Category);
	OO_OVERRIDE_METHOD(SAMCategory,Root,Create,SPM_SAMCategory_Create);
	OO_OVERRIDE_METHOD(SAMCategory,Root,Delete,SPM_SAMCategory_Delete);
	OO_OVERRIDE_METHOD(SAMCategory,Category,Update,SPM_SAMCategory_Update);
	OO_DEFINE_PROPERTY(SAMCategory,Area,"ARRAY",[]); // StrongpointArea structure
	OO_DEFINE_PROPERTY(SAMCategory,SAMObjects,"ARRAY",[]);
	OO_DEFINE_PROPERTY(SAMCategory,_BlockingObjects,"ARRAY",[]);
OO_END_SUBCLASS(SAMCategory); 