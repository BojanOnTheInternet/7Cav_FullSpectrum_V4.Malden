/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_Checkpoints_CreateCheckpoint) =
{
	params ["_category", "_checkpoint"];

	private _garrison = OO_GET(_category,CheckpointsCategory,Garrison);
	private _garrisonLimit = OO_GET(_category,CheckpointsCategory,GarrisonLimit);

	private _groupSize = _garrisonLimit min 3;
	_garrisonLimit = _garrisonLimit - _groupSize;

	OO_SET(_category,CheckpointsCategory,GarrisonLimit,_garrisonLimit);

	private _group = [_groupSize] call OO_METHOD(_garrison,InfantryGarrisonCategory,BeginTemporaryDuty);

	if (isNull _group) exitWith { false };

	OO_SET(_checkpoint,Checkpoint,Group,_group);

	private _position = OO_GET(_checkpoint,Checkpoint,Position);
	private _directionVector = OO_GET(_checkpoint,Checkpoint,Direction);

	private _direction = [0,0,0] getDir _directionVector;
	private _perpendicular1 = [_directionVector select 1, -(_directionVector select 0), 0];
	private _perpendicular2 = _perpendicular1 vectorMultiply -1.0;

	private _side1 = _position;
	while { isOnRoad _side1 } do { _side1 = _side1 vectorAdd _perpendicular1 };

	private _side2 = _position;
	while { isOnRoad _side2 } do { _side2 = _side2 vectorAdd _perpendicular2 };

	private _objects = [];
	private _gate = objNull;

	switch (true) do
	{
		case (_side1 distance _side2 < 12.0):
		{
			_gate = ["Land_BarGate_01_open_F", _position vectorAdd (_perpendicular1 vectorMultiply 0.5), _direction] call SPM_fnc_spawnVehicle;
			_gate allowDamage false;
			_objects pushBack _gate;
		};
		case (_side1 distance _side2 < 24.0):
		{
			_gate = ["Land_BarGate_01_open_F", _position vectorAdd (_perpendicular1 vectorMultiply 4.1), _direction] call SPM_fnc_spawnVehicle;
			_gate allowDamage false;
			_objects pushBack _gate;
			_side1 = _position vectorAdd (_perpendicular1 vectorMultiply (8.2 + 1.0));

			_gate = ["Land_BarGate_01_open_F", _position vectorAdd (_perpendicular2 vectorMultiply 4.1), _direction + 180] call SPM_fnc_spawnVehicle;
			_gate allowDamage false;
			_objects pushBack _gate;
			_side2 = _position vectorAdd (_perpendicular2 vectorMultiply (8.2 + 1.0));
		};
	};

	//TODO: Bunker and sandbags should be simple objects

	private _bunker = ["Land_BagBunker_Small_F", _side1 vectorAdd (_perpendicular1 vectorMultiply (4.5 / 2.0)), _direction + 90] call SPM_fnc_spawnVehicle;
	_objects pushBack _bunker;
	(_objects select (count _objects - 1)) enableSimulationGlobal false;

	_objects pushBack (["Land_BagFence_Long_F", _side1 vectorAdd (_perpendicular1 vectorMultiply (4.5 + 0.0)), _direction + 90] call SPM_fnc_spawnVehicle);
	(_objects select (count _objects - 1)) enableSimulationGlobal false;

	_objects pushBack (["Land_PortableLight_single_F", _bunker modelToWorld [-2.07,-2.37,-0.93], _direction + 135] call SPM_fnc_spawnVehicle);
	_objects pushBack (["Land_PortableLight_single_F", _bunker modelToWorld [ 2.37,-2.34,-0.88], _direction + 45] call SPM_fnc_spawnVehicle);
	_objects pushBack (["Land_PortableLight_single_F", _bunker modelToWorld [ 2.16, 1.85,-0.99], _direction - 45] call SPM_fnc_spawnVehicle);
	_objects pushBack (["Land_PortableLight_single_F", _bunker modelToWorld [-1.64, 2.20,-1.02], _direction - 135] call SPM_fnc_spawnVehicle);

	private _razorWire = [];
	private _positions = [];
	
	_razorWire pushBack (["Land_Razorwire_F", _side1 vectorAdd (_perpendicular1 vectorMultiply (5.4 + 8.7 / 2.0)), _direction] call SPM_fnc_spawnVehicle);
	_razorWire pushBack (["Land_Razorwire_F", _side2 vectorAdd (_perpendicular2 vectorMultiply (8.7 / 2.0)), _direction] call SPM_fnc_spawnVehicle);
	_razorWire pushBack (["Land_Razorwire_F", _side2 vectorAdd (_perpendicular2 vectorMultiply (8.7 + 8.7 / 2.0)), _direction] call SPM_fnc_spawnVehicle);

	{
		_positions = [getPos _x];
		[_positions, vectorMagnitude ((boundingBoxReal _x) select 0), ["WALL", "HOUSE"]] call SPM_Util_ExcludeSamplesByProximity;
		if (count _positions == 0) then { deleteVehicle _x } else { _x allowDamage false; _objects pushBack _x };
	} forEach _razorWire;

	OO_GET(_checkpoint,Checkpoint,Objects) append _objects;

	{
		private _blockingObjects = nearestTerrainObjects [getPos _x, ["TREE", "SMALL TREE", "BUSH", "HIDE", "FENCE"], vectorMagnitude ((boundingBoxReal _x) select 0), false, true];
		{
			_x hideObjectGlobal true;
		} forEach _blockingObjects;

		OO_GET(_checkpoint,Checkpoint,_BlockingObjects) append _blockingObjects;
	} forEach _objects;

	// Make sure the soldiers stand up in the bunker
	{ _x setUnitPos "up" } forEach units _group;

	// Put the soldiers at the checkpoint.  If this is the first update of the strongpoint, move them to their destination instantly.
	private _strongpoint = OO_GETREF(_category,Category,Strongpoint);
	if (OO_GET(_strongpoint,Strongpoint,UpdateIndex) == 1) then
	{
		[_group, _bunker, "instant"] call SPM_fnc_occupyEnterBuilding;
	}
	else
	{
		[_group, _bunker, "simultaneous"] call SPM_fnc_occupyEnterBuilding;
	};

	true
};

OO_TRACE_DECL(SPM_Checkpoints_DeleteCheckpoint) =
{
	params ["_category", "_checkpoint"];

	{
		deleteVehicle _x;
	} forEach OO_GET(_checkpoint,Checkpoint,Objects);

	{
		_x hideObjectGlobal false;
	} forEach OO_GET(_checkpoint,Checkpoint,_BlockingObjects);

	private _group = OO_GET(_checkpoint,Checkpoint,Group);
	if (not isNull _group) then
	{
		private _garrison = OO_GET(_category,CheckpointsCategory,Garrison);
		[_group] call OO_METHOD(_garrison,InfantryGarrisonCategory,EndTemporaryDuty);
	};
};

OO_TRACE_DECL(SPM_Checkpoints_IdentifyCheckpoints) =
{
	params ["_category"];

	private _area = OO_GET(_category,CheckpointsCategory,Area);
	private _center = OO_GET(_area,StrongpointArea,Position);
	private _outerRadius = OO_GET(_area,StrongpointArea,OuterRadius);
	private _coverage = OO_GET(_category,CheckpointsCategory,Coverage);

	private _road = [_center, 50] call BIS_fnc_nearestRoad;
	if (isNull _road) exitWith { [] };

	private _checkpoints = [];
	private _positions = [];
	private _exclusions = [];
	{
		_positions = [getPos (_x select 1)];
		_exclusions = [];

		[_positions, 20, ["WALL", "HOUSE"]] call SPM_Util_ExcludeSamplesByProximity;
		[_positions, _center, _coverage select 0, _coverage select 1, _exclusions] call SPM_Util_ExcludeSamplesByDirection;
		_positions = _exclusions;

		if (count _positions > 0) then
		{
			private _checkpoint = [] call OO_CREATE(Checkpoint);
			private _position = _positions select 0;

			OO_SET(_checkpoint,Checkpoint,Position,_position);

			private _direction = getPos (_x select 0) vectorFromTo getPos (_x select 1);
			OO_SET(_checkpoint,Checkpoint,Direction,_direction);

			_checkpoints pushBack _checkpoint;
		};
	} forEach ([_road, _center, _outerRadius] call SPM_Util_ExitRoads);

	_checkpoints
};

OO_TRACE_DECL(SPM_Checkpoints_Create) =
{
	params ["_category", "_area", "_garrison", "_garrisonLimit"];

	OO_SET(_category,CheckpointsCategory,Area,_area);
	OO_SET(_category,CheckpointsCategory,Garrison,_garrison);
	OO_SET(_category,CheckpointsCategory,GarrisonLimit,_garrisonLimit);
	OO_SET(_category,Category,GetUpdateInterval,{30});
};

OO_TRACE_DECL(SPM_Checkpoints_Delete) =
{
	params ["_category"];

	{
		[_category, _x] call SPM_Checkpoints_DeleteCheckpoint;
	} forEach OO_GET(_category,CheckpointsCategory,Checkpoints);
};

OO_TRACE_DECL(SPM_Checkpoints_Update) =
{
	params ["_category"];

	[] call OO_METHOD_PARENT(_category,Category,Update,Category);

	if (OO_GET(_category,Category,UpdateIndex) == 1) then
	{
		private _availableCheckpoints = [_category] call SPM_Checkpoints_IdentifyCheckpoints;

		while { count _availableCheckpoints > 0 && OO_GET(_category,CheckpointsCategory,GarrisonLimit) > 0 } do
		{
			private _checkpoint = _availableCheckpoints deleteAt (floor random count _availableCheckpoints);
			if ([_category, _checkpoint] call SPM_Checkpoints_CreateCheckpoint) then { OO_GET(_category,CheckpointsCategory,Checkpoints) pushBack _checkpoint };
		};
	};
};

OO_BEGIN_STRUCT(Checkpoint);
	OO_DEFINE_PROPERTY(Checkpoint,Position,"ARRAY",[]);
	OO_DEFINE_PROPERTY(Checkpoint,Direction,"ARRAY",[]); // Vector
	OO_DEFINE_PROPERTY(Checkpoint,Objects,"ARRAY",[]);
	OO_DEFINE_PROPERTY(Checkpoint,Group,"GROUP",grpNull);
	OO_DEFINE_PROPERTY(Checkpoint,_BlockingObjects,"ARRAY",[]);
OO_END_STRUCT(Checkpoint);

private _defaultCoverage = [0,360]; // All directions

OO_BEGIN_SUBCLASS(CheckpointsCategory,Category);
	OO_OVERRIDE_METHOD(CheckpointsCategory,Root,Create,SPM_Checkpoints_Create);
	OO_OVERRIDE_METHOD(CheckpointsCategory,Root,Delete,SPM_Checkpoints_Delete);
	OO_OVERRIDE_METHOD(CheckpointsCategory,Category,Update,SPM_Checkpoints_Update);
	OO_DEFINE_PROPERTY(CheckpointsCategory,Garrison,"#OBJ",OO_NULL);
	OO_DEFINE_PROPERTY(CheckpointsCategory,GarrisonLimit,"SCALAR",1e30); // Limit the number of infantry that can be used for checkpoints
	OO_DEFINE_PROPERTY(CheckpointsCategory,Area,"ARRAY",[]); // StrongpointArea structure
	OO_DEFINE_PROPERTY(CheckpointsCategory,Coverage,"ARRAY",_defaultCoverage); // Which angular range should be considered for placing checkpoints
	OO_DEFINE_PROPERTY(CheckpointsCategory,Checkpoints,"ARRAY",[]);
OO_END_SUBCLASS(CheckpointsCategory);
