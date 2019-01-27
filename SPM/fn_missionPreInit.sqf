/*
Copyright (c) 2017, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_Mission_AddObjective) =
{
	params ["_mission", "_objective"];

	[_objective] call OO_METHOD(_mission,Strongpoint,AddCategory);

	OO_GET(_mission,Mission,Objectives) pushBack _objective;
};

OO_TRACE_DECL(SPM_Mission_Update) =
{
	params ["_mission"];

	[] call OO_METHOD_PARENT(_mission,Strongpoint,Update,Strongpoint);

	if (OO_GET(_mission,Mission,MissionState) == "unresolved") then
	{
		private _objectiveStates = OO_GET(_mission,Mission,Objectives) select { OO_ISNULL(OO_GET(_x,MissionObjective,ObjectiveParent)) && { not (OO_GET(_x,MissionObjective,State) in OO_GET(_x,MissionObjective,CompletionStates)) } } apply { OO_GET(_x,MissionObjective,State)  };

		switch (true) do
		{
			case (count _objectiveStates == 0): { OO_SET(_mission,Mission,MissionState,"completed-success") };
			case (_objectiveStates findIf { _x == "error" } >= 0): { OO_SET(_mission,Mission,MissionState,"completed-error") };
			case (_objectiveStates findIf { _x == "failed" } >= 0): { OO_SET(_mission,Mission,MissionState,"completed-failure") };
		};
	};
};

OO_TRACE_DECL(SPM_Mission_Create) =
{
	params ["_mission", "_center", "_controlRadius", "_activityRadius"];

	[_center, _controlRadius, _activityRadius] call OO_METHOD_PARENT(_mission,Root,Create,Strongpoint);
};

OO_TRACE_DECL(SPM_Mission_Delete) =
{
	params ["_mission"];

	[] call OO_METHOD_PARENT(_mission,Root,Delete,Strongpoint);
};

OO_BEGIN_SUBCLASS(Mission,Strongpoint);
	OO_OVERRIDE_METHOD(Mission,Root,Create,SPM_Mission_Create);
	OO_OVERRIDE_METHOD(Mission,Root,Delete,SPM_Mission_Delete);
	OO_OVERRIDE_METHOD(Mission,Strongpoint,Update,SPM_Mission_Update);
	OO_DEFINE_METHOD(Mission,AddObjective,SPM_Mission_AddObjective);
	OO_DEFINE_PROPERTY(Mission,Name,"STRING","");
	OO_DEFINE_PROPERTY(Mission,ParticipantFilter,"CODE",{hasInterface});
	OO_DEFINE_PROPERTY(Mission,Objectives,"ARRAY",[]);
	OO_DEFINE_PROPERTY(Mission,Announced,"STRING","none"); // none, start-of-mission, end-of-mission
	OO_DEFINE_PROPERTY(Mission,MissionState,"STRING","unresolved"); // unresolved, command-terminated, completed-failed, completed-success, completed-error
	OO_DEFINE_PROPERTY(Mission,NotificationsAccumulator,"ARRAY",[]);
	OO_DEFINE_PROPERTY(Mission,Buildings,"ARRAY",[]);
OO_END_SUBCLASS(Mission);

OO_TRACE_DECL(SPM_MissionObjective_SendNotification) =
{
	params ["_objective", "_origin", "_message", "_type"];

	private _parent = OO_GETREF(_objective,MissionObjective,ObjectiveParent);
	if (not OO_ISNULL(_parent)) exitWith { [_origin, _message, _type] call OO_METHOD(_parent,Category,SendNotification) };

	[_origin, _message, _type] call OO_METHOD_PARENT(_objective,Category,SendNotification,Category);
};

OO_TRACE_DECL(SPM_MissionObjective_GetDescription) =
{
	["",""]
};

OO_TRACE_DECL(SPM_MissionObjective_Update) =
{
	params ["_objective"];

	[] call OO_METHOD_PARENT(_objective,Category,Update,Category);
};

SPM_MissionObjective_CompletionStates_Default = ["succeeded"];
SPM_MissionObjective_CompletionStates_Required = ["succeeded"];
SPM_MissionObjective_CompletionStates_Optional = ["succeeded", "failed"];

OO_BEGIN_SUBCLASS(MissionObjective,Category);
	OO_OVERRIDE_METHOD(MissionObjective,Category,Update,SPM_MissionObjective_Update);
	OO_OVERRIDE_METHOD(MissionObjective,Category,SendNotification,SPM_MissionObjective_SendNotification);
	OO_DEFINE_METHOD(MissionObjective,GetDescription,SPM_MissionObjective_GetDescription);
	OO_DEFINE_PROPERTY(MissionObjective,State,"STRING","starting"); // starting, active, failed, completed, error
	OO_DEFINE_PROPERTY(MissionObjective,CompletionStates,"ARRAY",SPM_MissionObjective_CompletionStates_Default); // States acceptable as resolution of the objective.  ("succeeded", "failed" and/or "error")
	OO_DEFINE_PROPERTY(MissionObjective,ObjectiveObject,"OBJECT",objNull);
	OO_DEFINE_PROPERTY(MissionObjective,ObjectiveParent,"#REF",OO_NULL);
OO_END_SUBCLASS(MissionObjective);