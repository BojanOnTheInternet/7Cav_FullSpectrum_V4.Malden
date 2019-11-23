/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_Headquarters_GetGuardableObject) =
{
	params ["_guardableObject"];

	OO_GET(_guardableObject,HeadquartersGuardableObject,Object);
};

OO_TRACE_DECL(SPM_Headquarters_GetGuardablePositions) =
{
	params ["_guardableObject"];

	private _object = OO_GET(_guardableObject,HeadquartersGuardableObject,Object);

	_positions = [getPos _object, 0, 20.0, 4.0] call SPM_Util_SampleAreaGrid;
	[_positions, ["#GdtRoad", "#GdtWater"]] call SPM_Util_ExcludeSamplesBySurfaceType;
	[_positions, 1.0, ["WALL", "BUILDING", "HOUSE", "ROCK", "ROAD"]] call SPM_Util_ExcludeSamplesByProximity;

	_positions
};

OO_BEGIN_SUBCLASS(HeadquartersGuardableObject,GuardableObject);
	OO_OVERRIDE_METHOD(HeadquartersGuardableObject,GuardableObject,GetObject,SPM_Headquarters_GetGuardableObject);
	OO_OVERRIDE_METHOD(HeadquartersGuardableObject,GuardableObject,GetPositions,SPM_Headquarters_GetGuardablePositions);
	OO_DEFINE_PROPERTY(HeadquartersGuardableObject,Object,"OBJECT",OO_NULL);
OO_END_SUBCLASS(HeadquartersGuardableObject);

OO_TRACE_DECL(SPM_Headquarters_RecallPatrols) =
{
	params ["_objective"];

	private _mission = OO_GETREF(_objective,Category,Strongpoint);
	private _garrison = OO_GETREF(_objective,HeadquartersCategory,Garrison);

	// Find patrols using our commanded garrison
	{
		private _category = _x;
		if (OO_INSTANCE_ISOFCLASS(_category,InfantryPatrolCategory) && { (OO_ISEQUAL(OO_GET(_category,InfantryPatrolCategory,Garrison),_garrison)) }) then
		{
			private _patrols = OO_GET(_category,InfantryPatrolCategory,Patrols);
			{ [_x select 3] call OO_METHOD(_category,InfantryPatrolCategory,RemovePatrol) } forEach _patrols;
		};
	} forEach OO_GET(_mission,Strongpoint,Categories);
};

// The time that a group is given to move towards their objective after dismounting a vehicle.  After this time, a unit's rating can be reduced according to its distance from the operation.
#define ARRIVAL_GRACE_TIME 120

// Compute a rating for a unit based on where it is relative to a circular area.
OO_TRACE_DECL(SPM_Headquarters_UnitRating) =
{
	params ["_forceRating", "_center", "_radius", "_attenuation"];

	private _unit = OO_GET(_forceRating,ForceRating,Vehicle);

	// If mounted, assume that the unit is inbound to the operation via some transport (including parachute)
	if (vehicle _unit != _unit) exitWith { OO_GET(_forceRating,ForceRating,Rating) };

	// If not mounted, give the unit some time to get where he's going.  He could start outside the operation, and we want to give him time to advance.
	private _onGroundTime = (group _unit) getVariable ["SPM_InfantryGarrison_OnGroundTime", 0];
	if (diag_tickTime - _onGroundTime < ARRIVAL_GRACE_TIME) exitWith { OO_GET(_forceRating,ForceRating,Rating) };

	// If he's on foot and old enough, assign a rating.  Inside the indicated area, he gets his full rating.  Then there's a ramp to zero based on _attenuation (expressed in meters).
	OO_GET(_forceRating,ForceRating,Rating) * linearConversion [0.0, _attenuation, (_unit distance _center) - _radius, 1.0, 0.0, true];
};

OO_TRACE_DECL(SPM_Headquarters_Update) =
{
	params ["_objective"];

	[] call OO_METHOD_PARENT(_objective,Category,Update,MissionObjective);
};

OO_TRACE_DECL(SPM_HeadquartersCategory_GetDescription) =
{
	params ["_objective"];

	OO_GET(_objective,HeadquartersCategory,Description);
};

private _description = ["",""];

OO_BEGIN_SUBCLASS(HeadquartersCategory,MissionObjective);
	OO_OVERRIDE_METHOD(HeadquartersCategory,Category,Update,SPM_Headquarters_Update);
	OO_OVERRIDE_METHOD(HeadquartersCategory,MissionObjective,GetDescription,SPM_HeadquartersCategory_GetDescription);
	OO_DEFINE_PROPERTY(HeadquartersCategory,Garrison,"#REF",OO_NULL);
	OO_DEFINE_PROPERTY(HeadquartersCategory,Commanded,"ARRAY",[]); // Categories that the HQ commands.  Array of #REF
	OO_DEFINE_PROPERTY(HeadquartersCategory,Description,"ARRAY",_description);
	OO_DEFINE_PROPERTY(HeadquartersCategory,FlagpoleType,"STRING","Flag_CSAT_F");
	OO_DEFINE_PROPERTY(HeadquartersCategory,Flagpole,"OBJECT",objNull);
OO_END_SUBCLASS(HeadquartersCategory);