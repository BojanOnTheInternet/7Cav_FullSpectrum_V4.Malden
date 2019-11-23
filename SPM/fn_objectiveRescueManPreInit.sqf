/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#include "strongpoint.h"

#define INTERACTION_DISTANCE 2.0

OO_TRACE_DECL(SPM_ObjectiveRescueMan_C_CutFree) =
{
	params ["_target"];

	_target playMove "Acts_AidlPsitMstpSsurWnonDnon_out";
};

SPM_ObjectiveRescueMan_CutFreeCondition =
{
	params ["_target", "_caller"];

	if (not alive _target) exitWith { false };

	if (not (lifeState _caller in ["HEALTHY", "INJURED"])) exitWith { false };

	(animationState _target) find "acts_aidlpsitmstpssur" == 0
};

OO_TRACE_DECL(SPM_ObjectiveRescueMan_CutFree) =
{
	params ["_target", "_caller"];

	[_target, _caller] remoteExec ["SPM_ObjectiveRescueMan_S_CutFree", 2];
};

OO_TRACE_DECL(SPM_ObjectiveRescueMan_C_SetupActions) =
{
	params ["_target", "_targetDescription", "_clientActionTest"];

	if (isNull _target) exitWith {};

	if (not ([] call _clientActionTest)) exitWith {};

	_target addAction ["Cut restraints of " + _targetDescription, { [_this select 0, _this select 1] call SPM_ObjectiveRescueMan_CutFree },  [], 10, true, true, "", "[_target, _this] call SPM_ObjectiveRescueMan_CutFreeCondition", INTERACTION_DISTANCE];
};

SPM_ObjectiveRescueMan_C_JoinTarget =
{
	params ["_target", "_group"];

	[_target] join _group;
	doStop _target;
};

if (not isServer && hasInterface) exitWith {};

OO_TRACE_DECL(SPM_ObjectiveRescueMan_S_CutFree) =
{
	params ["_target", "_caller"];

	[_target] remoteExec ["SPM_ObjectiveRescueMan_C_CutFree", 0, true]; //JIP

	_target enableAI "path";
	_target setCaptive false;

	[_target, group _caller] remoteExec ["SPM_ObjectiveRescueMan_C_JoinTarget", groupOwner group _caller];

	private _objective = (_target getVariable "ORM_S_State") select 0;
	OO_SET(_objective,MissionObjective,State,"succeeded");

	_target 
};

OO_TRACE_DECL(SPM_ObjectiveRescueMan_GetDescription) =
{
	params ["_objective"];

	private _unitProvider = OO_GET(_objective,ObjectiveRescueMan,UnitProvider);
	private _unitDescription = OO_GET(_unitProvider,UnitProvider,UnitDescription);

	["Rescue " + _unitDescription, SPM_ObjectiveRescueMan_Description]
};

SPM_ObjectiveRescueMan_Description =
"Cut the target's restraints using the scroll wheel option.  Once freed, the target will join your group.  Note that enemies will then treat the target as an enemy combatant.";

OO_TRACE_DECL(SPM_ObjectiveRescueMan_Update) =
{
	params ["_objective"];

	[] call OO_METHOD_PARENT(_objective,Category,Update,MissionObjective);

	switch (OO_GET(_objective,MissionObjective,State)) do
	{
		case "starting":
		{
			private _unitProvider = OO_GET(_objective,ObjectiveRescueMan,UnitProvider);
			private _unit = OO_GET(_unitProvider,UnitProvider,Unit);

			if (not isNil "_unit") then
			{
				OO_SET(_objective,MissionObjective,ObjectiveObject,_unit);

				_unit setVariable ["ORM_S_State", [_objective, false]];
				removeAllWeapons _unit;
				removeBackpack _unit;
				_unit switchMove "acts_aidlpsitmstpssurwnondnon_loop";

				private _unitDescription = OO_GET(_unitProvider,UnitProvider,UnitDescription);
				private _clientActionTest = OO_GET(_objective,ObjectiveRescueMan,ClientActionTest);
				[_unit, _unitDescription, _clientActionTest] remoteExec ["SPM_ObjectiveRescueMan_C_SetupActions", 0, true]; //JIP

				OO_SET(_objective,MissionObjective,State,"active");

				private _objectiveDescription = [] call OO_METHOD(_objective,MissionObjective,GetDescription);
				[_objective, _objectiveDescription, "objective-description"] call OO_METHOD(_objective,Category,SendNotification);
			};
		};

		case "active":
		{
			private _unitProvider = OO_GET(_objective,ObjectiveRescueMan,UnitProvider);
			private _unit = OO_GET(_unitProvider,UnitProvider,Unit);

			if (not alive _unit) exitWith
			{
				OO_SET(_objective,MissionObjective,State,"failed");
				[_objective, ["Rescue failed.  Target has been killed.", ""], "event"] call OO_METHOD(_objective,Category,SendNotification);
			};
		};

		case "succeeded";
		case "failed":
		{
			[_objective, [format ["%1 (%2)", ([] call OO_METHOD(_objective,MissionObjective,GetDescription)) select 0, OO_GET(_objective,MissionObjective,State)]], "objective-status"] call OO_METHOD(_objective,Category,SendNotification);
		
			OO_SET(_objective,Category,UpdateTime,1e30);
		};
	};
};

OO_TRACE_DECL(SPM_ObjectiveRescueMan_Create) =
{
	params ["_objective", "_unitProvider"];

	OO_SET(_objective,Category,GetUpdateInterval,{1});
	OO_SET(_objective,ObjectiveRescueMan,UnitProvider,_unitProvider);
};

OO_BEGIN_SUBCLASS(ObjectiveRescueMan,MissionObjective);
	OO_OVERRIDE_METHOD(ObjectiveRescueMan,Root,Create,SPM_ObjectiveRescueMan_Create);
	OO_OVERRIDE_METHOD(ObjectiveRescueMan,Category,Update,SPM_ObjectiveRescueMan_Update);
	OO_OVERRIDE_METHOD(ObjectiveRescueMan,MissionObjective,GetDescription,SPM_ObjectiveRescueMan_GetDescription);
	OO_DEFINE_PROPERTY(ObjectiveRescueMan,UnitProvider,"#OBJ",OO_NULL);
	OO_DEFINE_PROPERTY(ObjectiveRescueMan,ClientActionTest,"CODE",{true});
OO_END_SUBCLASS(ObjectiveRescueMan);
