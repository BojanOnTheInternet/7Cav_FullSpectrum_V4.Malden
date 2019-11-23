/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_ObjectiveCompound_SendNotification) =
{
	params ["_compound", "_origin", "_message", "_type"];

	if (not OO_ISEQUAL(_origin,_compound) && { not (_type in OO_GET(_compound,ObjectiveCompound,ChildNotificationTypes)) }) exitWith { };

	[_origin, _message, _type] call OO_METHOD_PARENT(_compound,Category,SendNotification,MissionObjective);
};

OO_TRACE_DECL(SPM_ObjectiveCompound_AddObjective) =
{
	params ["_compound", "_objective"];

	private _parent = OO_GETREF(_objective,MissionObjective,ObjectiveParent);
	if (not OO_ISNULL(_parent)) then { diag_log "ERROR: SPM_ObjectiveCompound_AddObjective: Adding a child with an existing parent." };
	
	OO_GET(_compound,ObjectiveCompound,Objectives) pushBack _objective;
	OO_SETREF(_objective,MissionObjective,ObjectiveParent,_compound);
};

// Fail if any objective is neither active nor in a completed state
OO_TRACE_DECL(SPM_ObjectiveCompound_ObjectiveHasFailed) =
{
	params ["_compound"];

	private _objectives = OO_GET(_compound,ObjectiveCompound,Objectives) select { not (OO_GET(_x,MissionObjective,State) in (["active"] + OO_GET(_x,MissionObjective,CompletionStates))) };

	count _objectives > 0
};

// Succeed if no objective is in any unacceptable final state
OO_TRACE_DECL(SPM_ObjectiveCompound_ObjectiveHasSucceeded) =
{
	params ["_compound"];

	private _objectives = OO_GET(_compound,ObjectiveCompound,Objectives) select { not (OO_GET(_x,MissionObjective,State) in OO_GET(_x,MissionObjective,CompletionStates)) };

	count _objectives == 0
};

OO_TRACE_DECL(SPM_ObjectiveCompound_GetDescription) =
{
	params ["_compound"];

	OO_GET(_compound,ObjectiveCompound,ObjectiveDescription);
};

OO_TRACE_DECL(SPM_ObjectiveCompound_Create) =
{
	params ["_compound", "_compoundDescription"];

	OO_SET(_compound,ObjectiveCompound,ObjectiveDescription,_compoundDescription);
};

OO_TRACE_DECL(SPM_ObjectiveCompound_Delete) =
{
	params ["_compound"];

	{
		[] call OO_DELETE(_x);
	} forEach OO_GET(_compound,ObjectiveCompound,Objectives);

	[] call OO_METHOD_PARENT(_compound,Root,Delete,MissionObjective);
};

OO_TRACE_DECL(SPM_ObjectiveCompound_Update) =
{
	params ["_compound"];

	private _updateTime = diag_tickTime + ([_compound] call OO_GET(_compound,Category,GetUpdateInterval));

	//TODO: Objectives may go to a complete or failed state, and we react immediately by shutting down.  However, those objectives may want to react
	// to their own transition to that new state and we don't ever call their Update.  "succeeded" and "failed" should probably be interpreted this way
	// with child objectives relying on another state to indicate that they want to go from "active" to some intermediate state to "succeeded" or "failed".

	private _objectives = OO_GET(_compound,ObjectiveCompound,Objectives);
	private _starting = 0;
	private _active = 0;
	{
		if (diag_tickTime > OO_GET(_x,Category,UpdateTime)) then
		{
			[] call OO_METHOD(_x,Category,Update);
			_updateTime = _updateTime min OO_GET(_x,Category,UpdateTime);
		};

		switch (OO_GET(_x,MissionObjective,State)) do
		{
			case "starting": { _starting = _starting + 1 };
			case "active": { _active = _active + 1 };
		};
	} forEach _objectives;

	OO_SET(_compound,Category,UpdateTime,_updateTime);

	switch (true) do
	{
		case (_starting > 0):
		{
			OO_SET(_compound,MissionObjective,State,"starting");
		};

		case (_active == count _objectives):
		{
			if (OO_GET(_compound,MissionObjective,State) == "starting") then
			{
				OO_SET(_compound,MissionObjective,State,"active");

				private _description = [] call OO_METHOD(_compound,MissionObjective,GetDescription);
				if ((_description select 0) != "") then { [_compound, _description, "objective-description"] call OO_METHOD(_compound,Category,SendNotification) };
			};
		};

		case ([] call OO_METHOD(_compound,ObjectiveCompound,ObjectiveHasFailed)):
		{
			OO_SET(_compound,MissionObjective,State,"failed");
		};

		case ([] call OO_METHOD(_compound,ObjectiveCompound,ObjectiveHasSucceeded)):
		{
			OO_SET(_compound,MissionObjective,State,"succeeded");
		};
	};

	if (OO_GET(_compound,MissionObjective,State) in ["succeeded", "failed"]) then
	{
		private _description = [] call OO_METHOD(_compound,MissionObjective,GetDescription);
		if ((_description select 0) != "") then { [_compound, [format ["%1 (%2)", _description select 0, OO_GET(_compound,MissionObjective,State)]], "objective-status"] call OO_METHOD(_compound,Category,SendNotification) };

		OO_SET(_compound,Category,UpdateTime,1e30);
	};

//	[] call OO_METHOD_PARENT(_compound,Category,Update,MissionObjective);
};

private _childNotificationTypes = ["objective-status","event"];
private _objectiveDescription = ["",""];

OO_BEGIN_SUBCLASS(ObjectiveCompound,MissionObjective);
	OO_OVERRIDE_METHOD(ObjectiveCompound,Root,Create,SPM_ObjectiveCompound_Create);
	OO_OVERRIDE_METHOD(ObjectiveCompound,Root,Delete,SPM_ObjectiveCompound_Delete);
	OO_OVERRIDE_METHOD(ObjectiveCompound,Category,Update,SPM_ObjectiveCompound_Update);
	OO_OVERRIDE_METHOD(ObjectiveCompound,Category,SendNotification,SPM_ObjectiveCompound_SendNotification);
	OO_OVERRIDE_METHOD(ObjectiveCompound,MissionObjective,GetDescription,SPM_ObjectiveCompound_GetDescription);
	OO_DEFINE_METHOD(ObjectiveCompound,AddObjective,SPM_ObjectiveCompound_AddObjective);
	OO_DEFINE_METHOD(ObjectiveCompound,ObjectiveHasFailed,SPM_ObjectiveCompound_ObjectiveHasFailed);
	OO_DEFINE_METHOD(ObjectiveCompound,ObjectiveHasSucceeded,SPM_ObjectiveCompound_ObjectiveHasSucceeded);
	OO_DEFINE_PROPERTY(ObjectiveCompound,ObjectiveDescription,"ARRAY",_objectiveDescription);
	OO_DEFINE_PROPERTY(ObjectiveCompound,Objectives,"ARRAY",[]);
	OO_DEFINE_PROPERTY(ObjectiveCompound,ChildNotificationTypes,"ARRAY",_childNotificationTypes);
OO_END_SUBCLASS(ObjectiveCompound);

// Objective fails if there aren't enough child objectives which have either resolved acceptably or are still active to meet the minimum requirement
OO_TRACE_DECL(SPM_ObjectiveCompoundAny_ObjectiveHasFailed) =
{
	params ["_compound"];

	private _objectives = OO_GET(_compound,ObjectiveCompound,Objectives) select { OO_GET(_x,MissionObjective,State) in (["active"] + OO_GET(_x,MissionObjective,CompletionStates)) };

	count _objectives < OO_GET(_compound,ObjectiveCompoundAny,MinimumRequiredCompleted)
};

// Objective succeeds when enough objectives have resolved acceptably
OO_TRACE_DECL(SPM_ObjectiveCompoundAny_ObjectiveHasSucceeded) =
{
	params ["_compound"];

	private _objectives = OO_GET(_compound,ObjectiveCompound,Objectives) select { OO_GET(_x,MissionObjective,State) in OO_GET(_x,MissionObjective,CompletionStates) };

	count _objectives >= OO_GET(_compound,ObjectiveCompoundAny,MinimumRequiredCompleted)
};

OO_BEGIN_SUBCLASS(ObjectiveCompoundAny,ObjectiveCompound);
	OO_OVERRIDE_METHOD(ObjectiveCompoundAny,ObjectiveCompound,ObjectiveHasFailed,SPM_ObjectiveCompoundAny_ObjectiveHasFailed);
	OO_OVERRIDE_METHOD(ObjectiveCompoundAny,ObjectiveCompound,ObjectiveHasSucceeded,SPM_ObjectiveCompoundAny_ObjectiveHasSucceeded);
	OO_DEFINE_PROPERTY(ObjectiveCompoundAny,MinimumRequiredCompleted,"SCALAR",1); // How many of the required sub-objectives must be completed to declare this compound objective completed
OO_END_SUBCLASS(ObjectiveCompoundAny);
