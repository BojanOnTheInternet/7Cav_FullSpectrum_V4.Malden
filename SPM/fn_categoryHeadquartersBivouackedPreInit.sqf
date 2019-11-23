/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_HeadquartersBivouacked_Create) =
{
	params ["_objective"];
};

OO_TRACE_DECL(SPM_HeadquartersBivouacked_Delete) =
{
	params ["_objective"];

	[_objective] call SPM_HeadquartersBivouacked_DeleteTraceObject;

	private _objects = OO_GET(_objective,HeadquartersBivouackedCategory,_StaticObjects);
	while { count _objects > 0 } do
	{
		deleteVehicle (_objects deleteAt 0);
	};

	// If the operation didn't end normally, delete the flagpole
	if (not (OO_GET(_objective,MissionObjective,State) in ["succeeded", "failed"])) then
	{
		deleteVehicle OO_GET(_objective,HeadquartersCategory,Flagpole);
	};

	// Put back the objects we hid to make room for the tents
	{
		_x hideObjectGlobal false;
	} forEach OO_GET(_objective,HeadquartersBivouackedCategory,_BlockingObjects);
};

OO_TRACE_DECL(SPM_HeadquartersBivouacked_Command) =
{
	params ["_objective", "_command", "_parameters"];

	switch (_command) do
	{
		case "minimize":
		{
			[_objective] call SPM_HeadquartersBivouacked_DeleteTraceObject;
		};
	};
};

SPM_HeadquartersBivouacked_TentTextures = ["a3\soft_f_epc\truck_03\data\truck_03_ext01_co.paa", "a3\soft_f_epc\truck_03\data\truck_03_ammo_co.paa", "a3\soft_f_beta\truck_02\data\truck_02_kuz_opfor_co.paa"];

OO_TRACE_DECL(SPM_HeadquartersBivouacked_CreateHeadquarters) =
{
	params ["_objective", "_area"];

	private _garrison = OO_GETREF(_objective,HeadquartersCategory,Garrison);

	// One tent for every 16 men (2 squads) in the associated garrison.
	private _numberTents = round (OO_GET(_garrison,InfantryGarrisonCategory,InitialReserves) / 16); //BUG: This is cheating.  InitialReserves is a rating value, not a count. But east infantry is rated at 1 point per soldier so we can get away with it for now

	private _tentRadius = 9;

	private _center = OO_GET(_area,StrongpointArea,Position);
	private _innerRadius = OO_GET(_area,StrongpointArea,InnerRadius);
	private _outerRadius = OO_GET(_area,StrongpointArea,OuterRadius);

	private _positions = [];
	private _tentPositions = [];
	while { _innerRadius <= _outerRadius } do
	{
		_positions = [_center, _innerRadius, _innerRadius + (_tentRadius * 4), _tentRadius * 2] call SPM_Util_SampleAreaGrid;
		[_positions, ["#GdtRoad", "#GdtWater"]] call SPM_Util_ExcludeSamplesBySurfaceType;
		[_positions, 10, 90] call SPM_Util_ExcludeSamplesBySurfaceIncline;
		[_positions, _tentRadius + 4, ["WALL", "BUILDING", "HOUSE", "ROCK", "ROAD"]] call SPM_Util_ExcludeSamplesByProximity;

		_tentPositions append _positions;
		if (count _tentPositions >= _numberTents) exitWith { };

		_innerRadius = _innerRadius + (_tentRadius * 4);
	};

	_tentPositions = _tentPositions select [0, _numberTents];

	private _blockingObjects = [];
	{
		_blockingObjects append nearestTerrainObjects [_x, ["TREE", "SMALL TREE", "BUSH", "HIDE", "FENCE"], _tentRadius, false, true];
	} forEach _tentPositions;

	{
		_x hideObjectGlobal true;
	} forEach _blockingObjects;
	OO_SET(_objective,HeadquartersBivouackedCategory,_BlockingObjects,_blockingObjects);

	{
		private _direction = [_x, random 360, 40] call SPM_Util_EnvironmentAlignedDirection;

		private _tent = ["Land_MedicalTent_01_white_generic_open_F", _x, _direction] call SPM_fnc_spawnVehicle;
		_tent setObjectTextureGlobal [0, selectRandom SPM_HeadquartersBivouacked_TentTextures];

		OO_GET(_objective,HeadquartersBivouackedCategory,_StaticObjects) pushBack _tent;
	} forEach (_tentPositions select [0, _numberTents]);

	if (count OO_GET(_objective,HeadquartersBivouackedCategory,_StaticObjects) == 0) exitWith
	{
		private _fire = ["Land_FirePlace_F", _center, 0] call SPM_fnc_spawnVehicle;
		OO_GET(_objective,HeadquartersBivouackedCategory,_StaticObjects) pushBack _fire;
		_center
	};

	_tentPositions select 0
};

OO_TRACE_DECL(SPM_HeadquartersBivouacked_CreateTraceObject) =
{
	params ["_objective"];

	private _garrison = OO_GETREF(_objective,HeadquartersCategory,Garrison);
	private _area = OO_GET(_garrison,ForceCategory,Area);
	private _traceObject = "Land_FirePlace_F" createVehicle (OO_GET(_area,StrongpointArea,Position) vectorAdd ([1,0,0] vectorMultiply OO_GET(_area,StrongpointArea,OuterRadius)));
	_traceObject hideObjectGlobal true;
	OO_SET(_objective,HeadquartersBivouackedCategory,_TraceObject,_traceObject);

	[_traceObject, "C0", format [" %1 bivouac", OO_GET(_garrison,ForceCategory,SideEast)]] call TRACE_SetObjectString;
};

OO_TRACE_DECL(SPM_HeadquartersBivouacked_DeleteTraceObject) =
{
	params ["_objective"];

	private _traceObject = OO_GET(_objective,HeadquartersBivouackedCategory,_TraceObject);
	if (not isNull _traceObject) then
	{
		deleteVehicle _traceObject;
		OO_SET(_objective,HeadquartersBivouackedCategory,_TraceObject,objNull);
	};
};

OO_TRACE_DECL(SPM_HeadquartersBivouacked_CreateStaticObjects) =
{
	params ["_objective"];

	private _mission = OO_GETREF(_objective,Category,Strongpoint);
	private _garrison = OO_GETREF(_objective,HeadquartersCategory,Garrison);

	private _position = [_objective, OO_GET(_garrison,ForceCategory,Area)] call SPM_HeadquartersBivouacked_CreateHeadquarters;

	// Set up a flag
	private _flagpole = [_position, 60, OO_GET(_objective,HeadquartersCategory,FlagpoleType)] call SPM_Util_CreateFlagpole;
	OO_SET(_objective,HeadquartersCategory,Flagpole,_flagpole);

	[_objective] call SPM_HeadquartersBivouacked_CreateTraceObject;

	// Request air defense if available
	{
		[_position] call OO_METHOD(_x,AirDefenseCategory,RequestSupport);
	} forEach (OO_GET(_mission,Strongpoint,Categories) select { OO_INSTANCE_ISOFCLASS(_x,AirDefenseCategory) });
};

OO_TRACE_DECL(SPM_HeadquartersBivouacked_Update) =
{
	params ["_objective"];

	[] call OO_METHOD_PARENT(_objective,Category,Update,HeadquartersCategory);

	if (OO_GET(_objective,MissionObjective,State) == "starting") then
	{
		[_objective] call SPM_HeadquartersBivouacked_CreateStaticObjects;
		private _description = [] call OO_METHOD(_objective,MissionObjective,GetDescription);
		[_objective, _description, "objective-description"] call OO_METHOD(_objective,Category,SendNotification);
		OO_SET(_objective,MissionObjective,State,"active");
	};

	private _garrison = OO_GETREF(_objective,HeadquartersCategory,Garrison);
	if (not OO_GET(_garrison,InfantryGarrisonCategory,InitialForceCreated)) exitWith {};

	private _eastForce = [-1] call OO_METHOD(_garrison,ForceCategory,GetForceLevelsEast); // East infantry from the garrison anywhere
	_eastForce = _eastForce select { not fleeing OO_GET(_x,ForceRating,Vehicle) }; // East infantry anywhere, not fleeing
	private _eastRating = 0; { _eastRating = _eastRating + OO_GET(_x,ForceRating,Rating) } forEach _eastForce;

	private _traceObject = OO_GET(_objective,HeadquartersBivouackedCategory,_TraceObject);
	if (not isNull _traceObject) then
	{
		[_traceObject, "C1", format ["%1 (surrender at %2)", floor _eastRating, floor OO_GET(_objective,HeadquartersBivouackedCategory,SurrenderRating)]] call TRACE_SetObjectString;
	};

	private _flagPosition = 0.0;
	private _flagpole = OO_GET(_objective,HeadquartersCategory,Flagpole);

	if (_eastRating > OO_GET(_objective,HeadquartersBivouackedCategory,SurrenderRating)) then
	{
		_flagPosition = linearConversion [OO_GET(_objective,HeadquartersBivouackedCategory,SurrenderRating), OO_GET(_garrison,InfantryGarrisonCategory,InitialReserves), _eastRating, 0.0, 1.0, true];
	}
	else
	{
		OO_SET(_objective,Category,UpdateTime,1e30);
		OO_SET(_objective,MissionObjective,State,"succeeded");
		private _description = [] call OO_METHOD(_objective,MissionObjective,GetDescription);
		[_objective, [format ["%1 (completed)", _description select 0]], "objective-status"] call OO_METHOD(_objective,Category,SendNotification);

		private _commanded = OO_NULL;
		{
			_commanded = OO_INSTANCE(_x);
			["surrender", 10] call OO_METHOD(_commanded,Category,Command);
		} forEach OO_GET(_objective,HeadquartersCategory,Commanded);

		_flagpole forceFlagTexture "\A3\Data_F\Flags\Flag_NATO_CO.paa"; //TODO: West side
		_flagPosition = 1.0;
	};

	[_flagpole, _flagPosition, 0.5] call BIS_fnc_animateFlag;
};

OO_BEGIN_SUBCLASS(HeadquartersBivouackedCategory,HeadquartersCategory);
	OO_OVERRIDE_METHOD(HeadquartersBivouackedCategory,Root,Create,SPM_HeadquartersBivouacked_Create);
	OO_OVERRIDE_METHOD(HeadquartersBivouackedCategory,Root,Delete,SPM_HeadquartersBivouacked_Delete);
	OO_OVERRIDE_METHOD(HeadquartersBivouackedCategory,Category,Command,SPM_HeadquartersBivouacked_Command);
	OO_OVERRIDE_METHOD(HeadquartersBivouackedCategory,Category,Update,SPM_HeadquartersBivouacked_Update);
	OO_DEFINE_PROPERTY(HeadquartersBivouackedCategory,SurrenderRating,"SCALAR",0);
	OO_DEFINE_PROPERTY(HeadquartersBivouackedCategory,_StaticObjects,"ARRAY",[]);
	OO_DEFINE_PROPERTY(HeadquartersBivouackedCategory,_BlockingObjects,"ARRAY",[]);
	OO_DEFINE_PROPERTY(HeadquartersBivouackedCategory,_TraceObject,"OBJECT",objNull);
OO_END_SUBCLASS(HeadquartersBivouackedCategory);
