/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

OO_BEGIN_CLASS(GuardableObject);
	OO_DEFINE_METHOD(GuardableObject,GetObject,{objNull});
	OO_DEFINE_METHOD(GuardableObject,GetPositions,{[]});
OO_END_CLASS(GuardableObject);

OO_TRACE_DECL(SPM_GuardObject_WS_GuardArrived) =
{
	params ["_leader", "_units", "_guardGroup"];

	[_leader] call SPM_Occupy_ChainUnit;

	private _group = group _leader;
	if (group _leader != _guardGroup) then
	{
		[_leader] join _guardGroup;
		deleteGroup _group;
	}
	else
	{
		private _waypoint = [_guardGroup, getPos _leader] call SPM_AddPatrolWaypoint;
		_waypoint setWaypointType "hold";
	};
};

OO_TRACE_DECL(SPM_GuardObject_ObjectiveKilled) =
{
	params ["_object", "_killer", "_instigator"];

	private _objectData = _object getVariable "SPM_GuardObject_Objective";
	private _category = _objectData select 0;

	private _garrison = OO_GET(_category,GuardObjectCategory,Garrison);
	private _guards = OO_GET(_category,GuardObjectCategory,_Guards);

	{
		[_x] call SPM_Occupy_UnchainUnit;
	} forEach _guards;

	[group (_guards select 0)] call OO_METHOD(_garrison,InfantryGarrisonCategory,EndTemporaryDuty);
	OO_SET(_category,GuardObjectCategory,_Guards,[]);

	_object setVariable ["SPM_GuardObject_Objective", nil];
};

OO_TRACE_DECL(SPM_GuardObject_Update) =
{
	params ["_category"];

	[] call OO_METHOD_PARENT(_category,Category,Update,Category);

	private _guardableObject = OO_GET(_category,GuardObjectCategory,GuardableObject);
	private _object = [] call OO_METHOD(_guardableObject,GuardableObject,GetObject);
	if (not alive _object) exitWith {};

	private _numberGuards = OO_GET(_category,GuardObjectCategory,NumberGuards);

	private _garrison = OO_GET(_category,GuardObjectCategory,Garrison);
	private _group = [_numberGuards] call OO_METHOD(_garrison,InfantryGarrisonCategory,BeginTemporaryDuty);
	if (isNull _group) exitWith {};

	private _positions = [_numberGuards] call OO_METHOD(_guardableObject,GuardableObject,GetPositions);

	OO_SET(_category,GuardObjectCategory,_Guards,units _group);

	// Quick and dirty version of "building occupy" at spots around the objective
	//TODO: Allow the occupy stuff to work with a completely-manufactured concept of a building with building positions (like we do with campfires)

	private _strongpoint = OO_GETREF(_category,Category,Strongpoint);
	private _guardGroup = grpNull; // The group that all of the guards will join when they arrive

	{
		private _soloGroup = createGroup (side _x);

		[_x] join _soloGroup;
		_x setBehaviour "safe";
		_x setCombatMode "green";
		_x setSpeedMode "limited";

		if (isNull _guardGroup) then { _guardGroup = _soloGroup };

		private _guardPosition = if (count _positions == 0) then { getPos _object } else { _positions deleteAt floor random count _positions };

		// If the guards are being placed during the first two updates, move them to their destination instantly.  Otherwise, they walk.  (The value 2 is used to allow the object being guarded to be created)
		if (OO_GET(_strongpoint,Strongpoint,UpdateIndex) <= 2) then
		{
			_x setPos _guardPosition;
			[_x, [], _guardGroup] call SPM_GuardObject_WS_GuardArrived;
		}
		else
		{
			private _waypoint = [_soloGroup, _guardPosition] call SPM_AddPatrolWaypoint;
			[_waypoint, SPM_GuardObject_WS_GuardArrived, _guardGroup] call SPM_AddPatrolWaypointStatements;
		};
	} forEach units _group;

	// If the objective is killed, let the guards return to garrison duty
	_object addEventHandler ["Killed", SPM_GuardObject_ObjectiveKilled];
	_object setVariable ["SPM_GuardObject_Objective", [_category]];

	OO_SET(_category,Category,UpdateTime,1e30);
};

OO_TRACE_DECL(SPM_GuardObject_Delete) =
{
	params ["_category"];

	private _guards = OO_GET(_category,GuardObjectCategory,_guards);

	if (count _guards > 0) then
	{
		private _groups = [];
		{ _groups pushBackUnique group _x } forEach _guards;

		private _garrison = OO_GET(_category,GuardObjectCategory,Garrison);
		{
			[_x] call OO_METHOD(_garrison,InfantryGarrisonCategory,EndTemporaryDuty);
		} forEach _groups;
	};
};

OO_TRACE_DECL(SPM_GuardObject_Create) =
{
	params ["_category", "_guardableObject", "_garrison", "_numberGuards"];

	OO_SET(_category,GuardObjectCategory,GuardableObject,_guardableObject);
	OO_SET(_category,GuardObjectCategory,Garrison,_garrison);
	OO_SET(_category,GuardObjectCategory,NumberGuards,_numberGuards);
	OO_SET(_category,Category,GetUpdateInterval,{1});
};

OO_BEGIN_SUBCLASS(GuardObjectCategory,Category);
	OO_OVERRIDE_METHOD(GuardObjectCategory,Root,Create,SPM_GuardObject_Create);
	OO_OVERRIDE_METHOD(GuardObjectCategory,Root,Delete,SPM_GuardObject_Delete);
	OO_OVERRIDE_METHOD(GuardObjectCategory,Category,Update,SPM_GuardObject_Update);
	OO_DEFINE_PROPERTY(GuardObjectCategory,GuardableObject,"ARRAY",[]);
	OO_DEFINE_PROPERTY(GuardObjectCategory,Garrison,"#OBJ",OO_NULL);
	OO_DEFINE_PROPERTY(GuardObjectCategory,NumberGuards,"SCALAR",0);
	OO_DEFINE_PROPERTY(GuardObjectCategory,_Guards,"ARRAY",[]);
OO_END_SUBCLASS(GuardObjectCategory);
