/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_HeadquartersGarrison_Delete) =
{
	params ["_objective"];

	[_objective] call SPM_HeadquartersGarrison_DeleteTraceObject;

	// If the operation didn't end normally, delete the flagpole
	if (not (OO_GET(_objective,MissionObjective,State) in ["succeeded", "failed"])) then
	{
		deleteVehicle OO_GET(_objective,HeadquartersCategory,Flagpole);
	};
};

OO_TRACE_DECL(SPM_HeadquartersGarrison_Command) =
{
	params ["_objective", "_command", "_parameters"];

	switch (_command) do
	{
		case "minimize":
		{
			[_objective] call SPM_HeadquartersGarrison_DeleteTraceObject;
		};
	};
};

OO_TRACE_DECL(SPM_HeadquartersGarrison_CreateTraceObject) =
{
	params ["_objective"];

	private _garrison = OO_GETREF(_objective,HeadquartersCategory,Garrison);
	private _area = OO_GET(_garrison,ForceCategory,Area);
	private _traceObject = "Land_FirePlace_F" createVehicle (OO_GET(_area,StrongpointArea,Position) vectorAdd ([0,1,0] vectorMultiply OO_GET(_area,StrongpointArea,OuterRadius)));
	_traceObject hideObjectGlobal true;
	OO_SET(_objective,HeadquartersGarrisonCategory,_TraceObject,_traceObject);

	[_traceObject, "C0", format [" %1 garrison", OO_GET(_garrison,ForceCategory,SideEast)]] call TRACE_SetObjectString;
};

OO_TRACE_DECL(SPM_HeadquartersGarrison_DeleteTraceObject) =
{
	params ["_objective"];

	private _traceObject = OO_GET(_objective,HeadquartersGarrisonCategory,_TraceObject);
	if (not isNull _traceObject) then
	{
		deleteVehicle _traceObject;
		OO_SET(_objective,HeadquartersGarrisonCategory,_TraceObject,objNull);
	};
};

OO_TRACE_DECL(SPM_HeadquartersGarrison_Update) =
{
	params ["_objective"];

	[] call OO_METHOD_PARENT(_objective,Category,Update,HeadquartersCategory);

	private _garrison = OO_GETREF(_objective,HeadquartersCategory,Garrison);

	if (OO_GET(_objective,MissionObjective,State) == "starting") then
	{
		[_objective] call SPM_HeadquartersGarrison_CreateTraceObject;
		private _description = [] call OO_METHOD(_objective,MissionObjective,GetDescription);
		[_objective, _description, "objective-description"] call OO_METHOD(_objective,Category,SendNotification);
		OO_SET(_objective,MissionObjective,State,"active");
	};

	if (not OO_GET(_garrison,InfantryGarrisonCategory,InitialForceCreated)) exitWith {};

	private _highwater = OO_GET(_objective,HeadquartersGarrisonCategory,HighwaterRating);
	if (_highwater == -1) then
	{
		_highwater = OO_GET(_garrison,InfantryGarrisonCategory,InitialReserves) + OO_GET(_garrison,ForceCategory,Reserves);
		OO_SET(_objective,HeadquartersGarrisonCategory,HighwaterRating,_highwater);
	};

	private _eastForce = [-1] call OO_METHOD(_garrison,ForceCategory,GetForceLevelsEast); // East infantry anywhere
	_eastForce = _eastForce select { not fleeing OO_GET(_x,ForceRating,Vehicle) }; // East infantry anywhere, not fleeing
	private _eastRating = 0; { _eastRating = _eastRating + OO_GET(_x,ForceRating,Rating) } forEach _eastForce;

	private _traceObject = OO_GET(_objective,HeadquartersGarrisonCategory,_TraceObject);
	if (not isNull _traceObject) then
	{
		[_traceObject, "C1", format ["%1 (%2 reserves, surrender at %3)", floor _eastRating, floor OO_GET(_garrison,ForceCategory,Reserves), floor OO_GET(_objective,HeadquartersGarrisonCategory,SurrenderRating)]] call TRACE_SetObjectString;
	};

	_eastRating = _eastRating + OO_GET(_garrison,ForceCategory,Reserves);

	private _flagpole = OO_GET(_objective,HeadquartersCategory,Flagpole);
	if (isNull _flagpole) then
	{
		private _area = OO_GET(_garrison,ForceCategory,Area);
		private _position = OO_GET(_area,StrongpointArea,Position);

		private _housedUnits = OO_GET(_garrison,InfantryGarrisonCategory,HousedUnits);
		if (count _housedUnits > 0) then { _position = getPos selectRandom _housedUnits };

		_flagpole = [_position, 60, OO_GET(_objective,HeadquartersCategory,FlagpoleType)] call SPM_Util_CreateFlagpole;
		OO_SET(_objective,HeadquartersCategory,Flagpole,_flagpole);

		// Request air defense if available, using the flag as a reference point
		private _mission = OO_GETREF(_objective,Category,Strongpoint);
		{
			[getPos _flagpole] call OO_METHOD(_x,AirDefenseCategory,RequestSupport);
		} forEach (OO_GET(_mission,Strongpoint,Categories) select { OO_INSTANCE_ISOFCLASS(_x,AirDefenseCategory) });
	};

	private _flagPosition = 0.0;

	if (_eastRating > OO_GET(_objective,HeadquartersGarrisonCategory,SurrenderRating)) then
	{
		_flagPosition = linearConversion [OO_GET(_objective,HeadquartersGarrisonCategory,SurrenderRating), _highwater, _eastRating, 0.0, 1.0, true];
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

		_flagpole forceFlagTexture "\A3\Data_F\Flags\Flag_NATO_CO.paa";
		_flagPosition = 1.0;
	};

	[_flagpole, _flagPosition, 0.5] call BIS_fnc_animateFlag;
};

OO_BEGIN_SUBCLASS(HeadquartersGarrisonCategory,HeadquartersCategory);
	OO_OVERRIDE_METHOD(HeadquartersGarrisonCategory,Root,Delete,SPM_HeadquartersGarrison_Delete);
	OO_OVERRIDE_METHOD(HeadquartersGarrisonCategory,Category,Command,SPM_HeadquartersGarrison_Command);
	OO_OVERRIDE_METHOD(HeadquartersGarrisonCategory,Category,Update,SPM_HeadquartersGarrison_Update);
	OO_DEFINE_PROPERTY(HeadquartersGarrisonCategory,SurrenderRating,"SCALAR",0);
	OO_DEFINE_PROPERTY(HeadquartersGarrisonCategory,HighwaterRating,"SCALAR",-1);
	OO_DEFINE_PROPERTY(HeadquartersGarrisonCategory,_TraceObject,"OBJECT",objNull);
OO_END_SUBCLASS(HeadquartersGarrisonCategory);
