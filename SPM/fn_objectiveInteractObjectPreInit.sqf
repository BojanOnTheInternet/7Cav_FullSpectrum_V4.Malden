/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#include "strongpoint.h"

#define INTERACTION_DISTANCE 5

SPM_ObjectiveInteractObject_InteractCondition =
{
	params ["_target", "_player"];

	if (vehicle _player != _player) exitWith { false };

	if (not (lifeState _player in ["HEALTHY", "INJURED"])) exitWith { false };

	private _data = _target getVariable "SPM_ObjectiveInteractObject_Data";

	if (_player distance2D _target > (_data select 7)) exitWith { false };

	if (not ([_target, _player] call (_data select 2))) exitWith { false };

	true
};

OO_TRACE_DECL(SPM_ObjectiveInteractObject_Interact) =
{
	params ["_object"];

	private _data = _object getVariable "SPM_ObjectiveInteractObject_Data";

	_object removeAction (_data select 1);

	[_object, player] call (_data select 3);

	[player, _data select 0] remoteExec ["SPM_ObjectiveInteractObject_S_InteractionComplete", 2];
};

SPM_ObjectiveInteractObject_InteractHoldInterval =
{
	params ["_elapsedTime", "_progress", "_passthrough"];

	if (([JB_HA_STATE] call JB_fnc_holdActionGetValue) == "keyup") exitWith { };

	if (_progress == 1.0) then
	{
		[] call JB_fnc_holdActionStop;

		[_passthrough select 0] spawn // Running the interaction without a spawn slows the responsiveness of the stop
		{
			[_this select 0] call SPM_ObjectiveInteractObject_Interact;
		};
	};
};

OO_TRACE_DECL(SPM_ObjectiveInteractObject_InteractHold) =
{
	params ["_object", "_action"];

	private _data = _object getVariable "SPM_ObjectiveInteractObject_Data";
	private _actionHold = _data select 4;
	private _actionIcon = _data select 5;
	private _actionIconScale = _data select 6;

	[actionKeys "action", _actionHold, 0.2, SPM_ObjectiveInteractObject_InteractHoldInterval, [_object]] call JB_fnc_holdActionStart;
	[JB_HA_LABEL, str parseText ((_object actionParams _action) select 0)] call JB_fnc_holdActionSetValue;
	[JB_HA_FOREGROUND_ICON, _actionIcon] call JB_fnc_holdActionSetValue;
	[JB_HA_FOREGROUND_ICON_SCALE, _actionIconScale] call JB_fnc_holdActionSetValue;
};

OO_TRACE_DECL(SPM_ObjectiveInteractObject_C_AddAction) =
{
	params ["_object", "_interactionDescription", "_interactionCondition", "_interaction", "_interactionFilter", "_actionHold", "_actionIcon", "_actionIconScale", "_objectiveReference"];

	if (not hasInterface) exitWith {};

	if (isNull _object) exitWith {};

	if (not ([player] call _interactionFilter)) exitWith {};

	private _code = if (_actionHold == 0.0) then { _code = { [_this select 0] call SPM_ObjectiveInteractObject_Interact } } else { { [_this select 0, _this select 2] call SPM_ObjectiveInteractObject_InteractHold } };

	// Use only the XY dimensions of the object to determine if we're close.  The action condition uses a distance2D check to decide if the player is close enough.  This allows us to interact intuitively with tall objects such as towers.
	private _interactionConditionDistance = (boundingBoxReal _object) select 0;
	_interactionConditionDistance set [2,0];
	_interactionConditionDistance = vectorMagnitude _interactionConditionDistance;
	_interactionConditionDistance = _interactionConditionDistance max 2.0; // Permit interactions from at least 2 meters

	private _action = _object addAction [_interactionDescription, _code,  [], 10, true, true, "", "[_target, _this] call SPM_ObjectiveInteractObject_InteractCondition", -1];
	[_object, _action, _actionIcon, _actionIconScale] call JB_fnc_holdActionSetText;

	_object setVariable ["SPM_ObjectiveInteractObject_Data", [_objectiveReference, _action, _interactionCondition, _interaction, _actionHold, _actionIcon, _actionIconScale, _interactionConditionDistance]];
};

if (not isServer && hasInterface) exitWith {};

OO_TRACE_DECL(SPM_ObjectiveInteractObject_S_InteractionComplete) =
{
	params ["_player", "_objectiveReference"];

	private _objective = OO_INSTANCE(_objectiveReference);

	[_player] call OO_METHOD(_objective,ObjectiveInteractObject,OnInteractionComplete);
};

OO_TRACE_DECL(SPM_ObjectiveInteractObject_OnInteractionComplete) =
{
	params ["_objective", "_interactor"];

	OO_SET(_objective,MissionObjective,State,"succeeded");
};

OO_TRACE_DECL(SPM_ObjectiveInteractObject_GetDescription) =
{
	params ["_objective"];

	OO_GET(_objective,ObjectiveInteractObject,ObjectiveDescription);
};

OO_TRACE_DECL(SPM_ObjectiveInteractObject_Update) =
{
	params ["_objective"];

	[] call OO_METHOD_PARENT(_objective,Category,Update,MissionObjective);

	switch (OO_GET(_objective,MissionObjective,State)) do
	{
		case "starting":
		{
			private _object = OO_GET(_objective,MissionObjective,ObjectiveObject);
			if (not isNull _object) then
			{
				private _interactionDescription = OO_GET(_objective,ObjectiveInteractObject,InteractionDescription);
				private _interactionCondition = OO_GET(_objective,ObjectiveInteractObject,InteractionCondition);
				private _interaction = OO_GET(_objective,ObjectiveInteractObject,Interaction);
				private _interactionFilter = OO_GET(_objective,ObjectiveInteractObject,InteractionFilter);
				private _actionHold = OO_GET(_objective,ObjectiveInteractObject,ActionHold);
				private _actionIcon = OO_GET(_objective,ObjectiveInteractObject,ActionIcon);
				private _actionIconScale = OO_GET(_objective,ObjectiveInteractObject,ActionIconScale);
				[_object, _interactionDescription, _interactionCondition, _interaction, _interactionFilter, _actionHold, _actionIcon, _actionIconScale, OO_REFERENCE(_objective)] remoteExec ["SPM_ObjectiveInteractObject_C_AddAction", 0, true]; //JIP

				OO_SET(_objective,MissionObjective,State,"active");
//				[_object, "OIO", "INTERACT"] call TRACE_SetObjectString;

				if (not OO_GET(_objective,ObjectiveInteractObject,ObjectiveAnnounced)) then
				{
					private _objectiveDescription = [] call OO_METHOD(_objective,MissionObjective,GetDescription);
					[_objective, _objectiveDescription, "objective-description"] call OO_METHOD(_objective,Category,SendNotification);
					OO_SET(_objective,ObjectiveInteractObject,ObjectiveAnnounced,true)
				};
			};
		};

		case "active":
		{
			private _object = OO_GET(_objective,MissionObjective,ObjectiveObject);
			if (isNull _object) exitWith { OO_SET(_objective,MissionObjective,State,"error") };
			if (not alive _object) exitWith
			{
				OO_SET(_objective,MissionObjective,State,"failed");
				[_objective, ["Interaction failed.  Target has been destroyed", ""], "event"] call OO_METHOD(_objective,Category,SendNotification);
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

OO_TRACE_DECL(SPM_ObjectiveInteractObject_Create) =
{
	params ["_objective"];

	OO_SET(_objective,Category,GetUpdateInterval,{1});
};

SPM_ObjectiveInteractObject_Description =
[
	"Deactivate object",
	"Deactivate the object"
];

OO_BEGIN_SUBCLASS(ObjectiveInteractObject,MissionObjective);
	OO_OVERRIDE_METHOD(ObjectiveInteractObject,Root,Create,SPM_ObjectiveInteractObject_Create);
	OO_OVERRIDE_METHOD(ObjectiveInteractObject,Category,Update,SPM_ObjectiveInteractObject_Update);
	OO_OVERRIDE_METHOD(ObjectiveInteractObject,MissionObjective,GetDescription,SPM_ObjectiveInteractObject_GetDescription);
	OO_DEFINE_METHOD(ObjectiveInteractObject,OnInteractionComplete,SPM_ObjectiveInteractObject_OnInteractionComplete);
	OO_DEFINE_PROPERTY(ObjectiveInteractObject,ObjectiveAnnounced,"BOOL",false);
	OO_DEFINE_PROPERTY(ObjectiveInteractObject,ObjectiveDescription,"ARRAY",SPM_ObjectiveInteractObject_Description);
	OO_DEFINE_PROPERTY(ObjectiveInteractObject,InteractionDescription,"STRING","Deactivate");
	OO_DEFINE_PROPERTY(ObjectiveInteractObject,InteractionCondition,"CODE",{true});
	OO_DEFINE_PROPERTY(ObjectiveInteractObject,Interaction,"CODE",{});
	OO_DEFINE_PROPERTY(ObjectiveInteractObject,InteractionFilter,"CODE",{true});
	OO_DEFINE_PROPERTY(ObjectiveInteractObject,ActionHold,"SCALAR",2.0);
	OO_DEFINE_PROPERTY(ObjectiveInteractObject,ActionIcon,"STRING","\a3\ui_f\data\IGUI\Cfg\HoldActions\holdAction_search_ca.paa");
	OO_DEFINE_PROPERTY(ObjectiveInteractObject,ActionIconScale,"SCALAR",1.7);
OO_END_SUBCLASS(ObjectiveInteractObject);
