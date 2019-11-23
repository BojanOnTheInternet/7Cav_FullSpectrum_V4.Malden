/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#include "strongpoint.h"

#define INTERACTION_DISTANCE 2.0

SPM_ObjectiveDebriefMan_DebriefCondition =
{
	params ["_target", "_caller"];

	if (not alive _target) exitWith { false };

	if (not (lifeState _caller in ["HEALTHY", "INJURED"])) exitWith { false };

	private _state = _target getVariable "ODM_C_State";

	[getPos _target, _state select 0] call SPM_Util_PositionInArea
};

OO_TRACE_DECL(SPM_ObjectiveDebriefMan_Debrief) =
{
	params ["_target", "_caller"];

	private _state = _target getVariable "ODM_C_State";
	_target removeAction (_state select 1);

	[_target] remoteExec ["SPM_ObjectiveDebriefMan_S_Debrief", 2];
};

OO_TRACE_DECL(SPM_ObjectiveDebriefMan_C_SetupActions) =
{
	params ["_target", "_targetDescription", "_debriefingArea", "_clientActionTest"];

	if (isNull _target) exitWith {};

	if (not ([] call _clientActionTest)) exitWith {};

	private _action = _target addAction ["Debrief " + _targetDescription, { [_this select 0, _this select 1] call SPM_ObjectiveDebriefMan_Debrief }, [], 10, true, true, "", "[_target, _this] call SPM_ObjectiveDebriefMan_DebriefCondition", INTERACTION_DISTANCE];

	_target setVariable ["ODM_C_State", [_debriefingArea, _action]];
};

if (not isServer && hasInterface) exitWith {};

OO_TRACE_DECL(SPM_ObjectiveDebriefMan_S_Debrief) =
{
	params ["_target"];

	_target setVariable ["ODM_S_State", true];
};

OO_TRACE_DECL(SPM_ObjectiveDebriefMan_GetDescription) =
{
	params ["_objective"];

	private _unitProvider = OO_GET(_objective,ObjectiveDebriefMan,UnitProvider);
	private _unitDescription = OO_GET(_unitProvider,UnitProvider,UnitDescription);

	["Debrief " + _unitDescription + " at " + OO_GET(_objective,ObjectiveDebriefMan,DebriefingAreaDescription), "Debrief the subject by stepping close and using the scroll wheel option."]
};

OO_TRACE_DECL(SPM_ObjectiveDebriefMan_Update) =
{
	params ["_objective"];

	[] call OO_METHOD_PARENT(_objective,Category,Update,MissionObjective);

	switch (OO_GET(_objective,MissionObjective,State)) do
	{
		case "starting":
		{
			private _unitProvider = OO_GET(_objective,ObjectiveDebriefMan,UnitProvider);
			private _unit = OO_GET(_unitProvider,UnitProvider,Unit);

			if (not isNil "_unit") then
			{
				OO_SET(_objective,MissionObjective,ObjectiveObject,_unit);

				private _debriefingArea = OO_GET(_objective,ObjectiveDebriefMan,DebriefingArea);
				private _unitDescription = OO_GET(_unitProvider,UnitProvider,UnitDescription);
				private _clientActionTest = OO_GET(_objective,ObjectiveDebriefMan,ClientActionTest);
				[_unit, _unitDescription, _debriefingArea, _clientActionTest] remoteExec ["SPM_ObjectiveDebriefMan_C_SetupActions", 0, true]; //JIP

				OO_SET(_objective,MissionObjective,State,"active");

				private _objectiveDescription = [] call OO_METHOD(_objective,MissionObjective,GetDescription);
				[_objective, _objectiveDescription, "objective-description"] call OO_METHOD(_objective,Category,SendNotification);
			};
		};

		case "active":
		{
			private _unitProvider = OO_GET(_objective,ObjectiveDebriefMan,UnitProvider);
			private _unit = OO_GET(_unitProvider,UnitProvider,Unit);
			
			if (not alive _unit) exitWith
			{
				OO_SET(_objective,MissionObjective,State,"failed");
				[_objective, ["Debrief failed.  Target has been killed", ""], "event"] call OO_METHOD(_objective,Category,SendNotification);
			};

			if (_unit getVariable ["ODM_S_State", false]) then
			{
				[_unit] spawn
				{
					params ["_unit"];

					// Salute the highest-rated specops player within interaction distance
					private _men = (_unit nearEntities ["Man", INTERACTION_DISTANCE]) select { [_x] call BOTH_IsSpecOpsMember };

					if (count _men > 0) then
					{
						_men = _men apply { [SPM_Util_Ranks find rank _x, _x] };
						_men sort false;

						_unit lookAt (_men select 0 select 1);
						sleep 1.5;
						_unit action ["salute"];
						sleep 1;
						_unit action ["salute"];

						private _group = createGroup [civilian, true];
						[_unit] join _group;

						doStop _unit;
					};
				};

				OO_SET(_objective,MissionObjective,State,"succeeded");
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

OO_TRACE_DECL(SPM_ObjectiveDebriefMan_Create) =
{
	params ["_objective", "_unitProvider", "_debriefingArea", "_debriefingAreaDescription"];

	OO_SET(_objective,Category,GetUpdateInterval,{1});
	OO_SET(_objective,ObjectiveDebriefMan,UnitProvider,_unitProvider);
	OO_SET(_objective,ObjectiveDebriefMan,DebriefingArea,_debriefingArea);
	OO_SET(_objective,ObjectiveDebriefMan,DebriefingAreaDescription,_debriefingAreaDescription);
};

OO_BEGIN_SUBCLASS(ObjectiveDebriefMan,MissionObjective);
	OO_OVERRIDE_METHOD(ObjectiveDebriefMan,Root,Create,SPM_ObjectiveDebriefMan_Create);
	OO_OVERRIDE_METHOD(ObjectiveDebriefMan,Category,Update,SPM_ObjectiveDebriefMan_Update);
	OO_OVERRIDE_METHOD(ObjectiveDebriefMan,MissionObjective,GetDescription,SPM_ObjectiveDebriefMan_GetDescription);
	OO_DEFINE_PROPERTY(ObjectiveDebriefMan,UnitProvider,"#OBJ",OO_NULL);
	OO_DEFINE_PROPERTY(ObjectiveDebriefMan,DebriefingArea,"ARRAY",[]);
	OO_DEFINE_PROPERTY(ObjectiveDebriefMan,DebriefingAreaDescription,"STRING","");
	OO_DEFINE_PROPERTY(ObjectiveDebriefMan,ClientActionTest,"CODE",{true}); // Run on clients to determine if the local player can see the capture action
OO_END_SUBCLASS(ObjectiveDebriefMan);
