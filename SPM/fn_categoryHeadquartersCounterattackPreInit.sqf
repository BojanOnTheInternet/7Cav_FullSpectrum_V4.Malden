/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_HeadquartersCounterattack_Create) =
{
	params ["_objective"];
};

OO_TRACE_DECL(SPM_HeadquartersCounterattack_Delete) =
{
	params ["_objective"];

	[_objective] call SPM_HeadquartersCounterattack_DeleteTraceObject;
	[_objective] call SPM_HeadquartersCounterattack_DeleteMarkers;
};

OO_TRACE_DECL(SPM_HeadquartersCounterattack_Command) =
{
	params ["_objective", "_command", "_parameters"];

	switch (_command) do
	{
		case "minimize":
		{
			[_objective] call SPM_HeadquartersCounterattack_DeleteTraceObject;
			[_objective] call SPM_HeadquartersCounterattack_DeleteMarkers;
		};
	};
};

OO_TRACE_DECL(SPM_HeadquartersCounterattack_CreateMarkers) =
{
	params ["_objective"];

	private _garrison = OO_GETREF(_objective,HeadquartersCategory,Garrison);

	// Place a marker indicating the area controlled by the garrison
	private _garrisonArea = OO_GET(_garrison,ForceCategory,Area);
	private _operationMarker = createMarker [format ["Headquarters-Counterattack%1", OO_REFERENCE(_objective)], OO_GET(_garrisonArea,StrongpointArea,Position)];
	_operationMarker setMarkerShape "ellipse";
	_operationMarker setMarkerColor "colorblue";
	_operationMarker setMarkerBrush "border";
	_operationMarker setMarkerSize [OO_GET(_garrisonArea,StrongpointArea,OuterRadius), OO_GET(_garrisonArea,StrongpointArea,OuterRadius)];

	OO_SET(_objective,HeadquartersCounterattackCategory,_Markers,[_operationMarker]);
};

OO_TRACE_DECL(SPM_HeadquartersCounterattack_DeleteMarkers) =
{
	params ["_objective"];

	// Delete the markers indicating the location of the headquarters area
	private _markers = OO_GET(_objective,HeadquartersCounterattackCategory,_Markers);
	while { count _markers > 0 } do
	{
		deleteMarker (_markers deleteAt 0);
	};
};

OO_TRACE_DECL(SPM_HeadquartersCounterattack_CreateTraceObject) =
{
	params ["_objective"];

	private _garrison = OO_GETREF(_objective,HeadquartersCategory,Garrison);
	private _garrisonArea = OO_GET(_garrison,ForceCategory,Area);

	// Put down a trace object to show mission controllers useful information
	private _traceObject = "Land_FirePlace_F" createVehicle (OO_GET(_garrisonArea,StrongpointArea,Position) vectorAdd ([-1,0,0] vectorMultiply OO_GET(_garrisonArea,StrongpointArea,OuterRadius)));
	_traceObject hideObjectGlobal true;
	OO_SET(_objective,HeadquartersCounterattackCategory,_TraceObject,_traceObject);

	[_traceObject, "C0", format [" %1 counterattack", OO_GET(_garrison,ForceCategory,SideEast)]] call TRACE_SetObjectString;
};

OO_TRACE_DECL(SPM_HeadquartersCounterattack_DeleteTraceObject) =
{
	params ["_objective"];

	private _traceObject = OO_GET(_objective,HeadquartersCounterattackCategory,_TraceObject);
	if (not isNull _traceObject) then
	{
		deleteVehicle _traceObject;
		OO_SET(_objective,HeadquartersCounterattackCategory,_TraceObject,objNull);
	};
};

OO_TRACE_DECL(SPM_HeadquartersCounterattack_FindFlagpole) =
{
	params ["_objective"];

	private _garrison = OO_GETREF(_objective,HeadquartersCategory,Garrison);
	private _garrisonArea = OO_GET(_garrison,ForceCategory,Area);

	private _flagpoles = OO_GET(_garrisonArea,StrongpointArea,Position) nearObjects ["Flag_CSAT_F", OO_GET(_garrisonArea,StrongpointArea,OuterRadius)];
	private _flagpole = if (count _flagpoles == 0) then { objNull } else { _flagpoles select 0 };

	OO_SET(_objective,HeadquartersCategory,Flagpole,_flagpole);
};

OO_TRACE_DECL(SPM_HeadquartersCounterattack_Update) =
{
	params ["_objective"];

	[] call OO_METHOD_PARENT(_objective,Category,Update,HeadquartersCategory);

	if (OO_GET(_objective,MissionObjective,State) == "starting") then
	{
		[_objective] call SPM_HeadquartersCounterattack_CreateMarkers;
		[_objective] call SPM_HeadquartersCounterattack_CreateTraceObject;
		[_objective] call SPM_HeadquartersCounterattack_FindFlagpole;
		private _description = [] call OO_METHOD(_objective,MissionObjective,GetDescription);
		[_objective, _description, "objective-description"] call OO_METHOD(_objective,Category,SendNotification);
		OO_SET(_objective,MissionObjective,State,"active");
	};

	private _garrison = OO_GETREF(_objective,HeadquartersCategory,Garrison);
	private _garrisonReserves = OO_GET(_garrison,ForceCategory,Reserves);
	private _garrisonArea = OO_GET(_garrison,ForceCategory,Area);
	private _garrisonPosition = OO_GET(_garrisonArea,StrongpointArea,Position);
	private _garrisonRadius = OO_GET(_garrisonArea,StrongpointArea,OuterRadius);

	// Track the highwater mark of the garrison reserves so we can show progress on the flag
	private _garrisonHighwater = OO_GET(_objective,HeadquartersCounterattackCategory,_GarrisonHighwater);
	if (_garrisonHighwater == -1 && _garrisonReserves > 0) then
	{
		_garrisonHighwater = _garrisonReserves;
		OO_SET(_objective,HeadquartersCounterattackCategory,_GarrisonHighwater,_garrisonHighwater);
	};

	// If we cannot form a unit from the available reserve set the reserves to zero
	if (_garrisonReserves > 1e-4) then
	{
		if (_garrisonReserves < selectMin (OO_GET(_garrison,ForceCategory,CallupsEast) apply { (_x select 1 select 0) * (_x select 1 select 1) })) then
		{
			_garrisonReserves = 0.0;
			OO_SET(_garrison,ForceCategory,Reserves,_garrisonReserves);
		};
	};

	private _activityBorder = OO_GET(_garrison,InfantryGarrisonCategory,ActivityBorder);

	private _eastForce = [-1] call OO_METHOD(_garrison,ForceCategory,GetForceLevelsEast); // East infantry anywhere in this operation
	private _eastRating = 0;
	{ _eastRating = _eastRating + ([_x, _garrisonPosition, _garrisonRadius, _activityBorder] call SPM_Headquarters_UnitRating) } forEach _eastForce;

	private _westForce = [_garrisonRadius] call OO_METHOD(_garrison,ForceCategory,GetForceLevelsWest); // West infantry in infantry area plus the border
	private _westRating = 0;
	{ _westRating = _westRating + ([_x, _garrisonPosition, _garrisonRadius, _activityBorder] call SPM_Headquarters_UnitRating) } forEach _westForce;

#ifdef TEST_COUNTERATTACK
	_westRating = 10;
#endif

	private _traceObject = OO_GET(_objective,HeadquartersCounterattackCategory,_TraceObject);
	if (not isNull _traceObject) then
	{
		[_traceObject, "C1", format ["%1 vs %2", floor _westRating, floor _eastRating]] call TRACE_SetObjectString;
		[_traceObject, "C2", format ["reserve: %1", floor _garrisonReserves]] call TRACE_SetObjectString;
	};

	private _flagpole = OO_GET(_objective,HeadquartersCategory,Flagpole);
	private _flagPosition = 0.0;

	// If the east's reserves are depleted and west force in the infantry area holds an appropriate force superiority of infantry (no matter where the east infantry is), then west wins
	if (_garrisonReserves < 1e-4 && { _westRating >= _eastRating * OO_GET(_objective,HeadquartersCounterattackCategory,WestEastVictoryRatio) || _eastRating <= OO_GET(_objective,HeadquartersCounterattackCategory,EastVictoryRating) }) then
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

		_flagPosition = 1.0;
	}
	else
	{
		_eastForce = _eastForce select { (vehicle OO_GET(_x,ForceRating,Vehicle)) == OO_GET(_x,ForceRating,Vehicle) }; // East infantry on foot
		private _eastRating = 0;
		{ _eastRating = _eastRating + ([_x, _garrisonPosition, _garrisonRadius, _activityBorder] call SPM_Headquarters_UnitRating) } forEach _eastForce;

		// If the east has boots on the ground and west doesn't have at least 1 point of presence, east wins
		if (_eastRating > 0.0 && _westRating < 1.0) then
		{
			OO_SET(_objective,Category,UpdateTime,1e30);
			OO_SET(_objective,MissionObjective,State,"failed");
			[_objective, ["Defend marked area (failed)"], "objective-status"] call OO_METHOD(_objective,Category,SendNotification);

			if (not isNull _flagpole) then { _flagpole forceFlagTexture "\A3\Data_F\Flags\Flag_CSAT_CO.paa" };
			_flagPosition = 1.0;
		};
	};

	if (_flagPosition == 0.0) then
	{
		private _eastRating = 0;
		{ _eastRating = _eastRating + OO_GET(_x,ForceRating,Rating) } forEach _eastForce;
		_flagPosition = (_eastRating + OO_GET(_garrison,ForceCategory,Reserves)) / _garrisonHighwater;
	};

	if (not isNull _flagpole) then { [_flagpole, _flagPosition, 0.5] call BIS_fnc_animateFlag; };
};

OO_BEGIN_SUBCLASS(HeadquartersCounterattackCategory,HeadquartersCategory);
	OO_OVERRIDE_METHOD(HeadquartersCounterattackCategory,Root,Create,SPM_HeadquartersCounterattack_Create);
	OO_OVERRIDE_METHOD(HeadquartersCounterattackCategory,Root,Delete,SPM_HeadquartersCounterattack_Delete);
	OO_OVERRIDE_METHOD(HeadquartersCounterattackCategory,Category,Command,SPM_HeadquartersCounterattack_Command);
	OO_OVERRIDE_METHOD(HeadquartersCounterattackCategory,Category,Update,SPM_HeadquartersCounterattack_Update);
	OO_DEFINE_PROPERTY(HeadquartersCounterattackCategory,WestEastVictoryRatio,"SCALAR",2.0); // The ratio of west:east forces where the west wins
	OO_DEFINE_PROPERTY(HeadquartersCounterattackCategory,EastVictoryRating,"SCALAR",3.0); // The east numeric rating where west wins
	OO_DEFINE_PROPERTY(HeadquartersCounterattackCategory,_GarrisonHighwater,"SCALAR",-1);
	OO_DEFINE_PROPERTY(HeadquartersCounterattackCategory,_Markers,"ARRAY",[]);
	OO_DEFINE_PROPERTY(HeadquartersCounterattackCategory,_TraceObject,"OBJECT",objNull);
OO_END_SUBCLASS(HeadquartersCounterattackCategory);