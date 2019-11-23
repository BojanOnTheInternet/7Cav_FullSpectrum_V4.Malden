/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#include "strongpoint.h"

#define INTERACTION_DISTANCE 2

SPM_ObjectiveMarkAmmoCaches_MarkCacheCondition =
{
	params ["_object"];

	if (_object != cursorObject) exitWith { false };

	if (vehicle player != player) exitWith { false };

	if (not (lifeState player in ["HEALTHY", "INJURED"])) exitWith { false };

	if (player distance _object > 2) exitWith { false };

	// Don't show action if a cache marker is already nearby
	private _data = _object getVariable "SPM_ObjectiveMarkAmmoCaches_Data";
	private _objectiveReference = _data select 0;
	private _markRadius = _data select 1;

	private _prefix = format ["SPM_OMAC_%1", _objectiveReference];

	private _markerIndex = allMapMarkers findIf { _x find _prefix == 0 && { (markerPos _x) distance2D _object < _markRadius } };

	_markerIndex == -1
};

SPM_ObjectiveMarkAmmoCaches_HoldActionInterval =
{
	params ["_elapsedTime", "_progress", "_passthrough"];

	if (([JB_HA_STATE] call JB_fnc_holdActionGetValue) == "keyup") exitWith { };

	if (_progress == 1.0) then
	{
		private _object = _passthrough select 0;
		private _objectiveReference = (_object getVariable "SPM_ObjectiveMarkAmmoCaches_Data") select 0;

		[_objectiveReference, _object] remoteExec ["SPM_ObjectiveMarkAmmoCaches_S_InteractionComplete", 2];
		titletext ["Ammunition cache marked", "plain down", 0.3];

		[] call JB_fnc_holdActionStop;
	};
};

OO_TRACE_DECL(SPM_ObjectiveMarkAmmoCaches_MarkCacheHoldAction) =
{
	params ["_object", "_action"];

	private _data = _object getVariable "SPM_ObjectiveMarkAmmoCaches_Data";
	private _actionIcon = _data select 2;
	private _actionIconScale = _data select 3;

	[actionKeys "action", 2.0, 1.0, SPM_ObjectiveMarkAmmoCaches_HoldActionInterval, [_object]] call JB_fnc_holdActionStart;
	[JB_HA_LABEL, str parseText ((_object actionParams _action) select 0)] call JB_fnc_holdActionSetValue;
	[JB_HA_FOREGROUND_ICON, _actionIcon] call JB_fnc_holdActionSetValue;
	[JB_HA_FOREGROUND_ICON_SCALE, _actionIconScale] call JB_fnc_holdActionSetValue;
};

OO_TRACE_DECL(SPM_ObjectiveMarkAmmoCaches_C_AddActions) =
{
	params ["_objectiveReference", "_actionTest", "_markRadius", "_actionIcon", "_actionIconScale", "_object"];

	if (not hasInterface) exitWith {};

	if (isNull _object) exitWith {};

	_object setVariable ["SPM_ObjectiveMarkAmmoCaches_Data", [_objectiveReference, _markRadius, _actionIcon, _actionIconScale]];

	if ([player] call _actionTest) then
	{
		private _action = _object addAction ["Mark ammunition cache", { [_this select 0, _this select 2] call SPM_ObjectiveMarkAmmoCaches_MarkCacheHoldAction }, nil, 9, true, true, "", "[_target] call SPM_ObjectiveMarkAmmoCaches_MarkCacheCondition"];
		[_object, _action, _actionIcon, _actionIconScale] call JB_fnc_holdActionSetText;
	};
};

if (not isServer && hasInterface) exitWith {};

OO_TRACE_DECL(SPM_ObjectiveMarkAmmoCaches_S_InteractionComplete) =
{
	params ["_objectiveReference", "_container"];

	private _objective = OO_INSTANCE(_objectiveReference);

	private _markerCounter = OO_GET(_objective,ObjectiveMarkAmmoCaches,_MarkerCounter);
	_markerCounter = _markerCounter + 1;
	OO_SET(_objective,ObjectiveMarkAmmoCaches,_MarkerCounter,_markerCounter);

	_marker = createMarker [format ["SPM_OMAC_%1_%2", _objectiveReference, _markerCounter], getPos _container];
	_marker setMarkerType OO_GET(_objective,ObjectiveMarkAmmoCaches,MarkerType);
	_marker setMarkerColor OO_GET(_objective,ObjectiveMarkAmmoCaches,MarkerColor);
};

OO_TRACE_DECL(SPM_ObjectiveMarkAmmoCaches_GetDescription) =
{
	params ["_objective"];

	["Mark ammunition caches for demolition", "Locate ammunition caches and use the scroll wheel action on the boxes to mark their locations on the map with a yellow triangle.  One mark can indicate multiple boxes.  If a box is represented by a map mark then you will not see the scroll wheel action to mark it."]
};

OO_TRACE_DECL(SPM_ObjectiveMarkAmmoCaches_UpdateAndGetFractionMarked) =
{
	params ["_objective"];

	private _ammoCaches = OO_GET(_objective,ObjectiveMarkAmmoCaches,_AmmoCaches);

	private _remainingContainers = [];

	private _allContainers = []; { _allContainers append (_x select 1) } forEach OO_GET(_ammoCaches,AmmoCachesCategory,_Caches);
	_remainingContainers = _allContainers;

	private _destroyedContainers = _remainingContainers select { not alive _x };
	_remainingContainers = _remainingContainers - _destroyedContainers;

	private _prefix = format ["SPM_OMAC_%1_", OO_REFERENCE(_objective)];
	private _markRadius = OO_GET(_objective,ObjectiveMarkAmmoCaches,MarkRadius);

	private _markedContainers = [];
	{
		private _marker = _x;
		private _markerPosition = getMarkerPos _marker;

		private _localContainers = _remainingContainers select { _x distance2D _markerPosition <= _markRadius };
		if (count _localContainers == 0) then
		{
			deleteMarker _marker;
		}
		else
		{
			_markedContainers append _localContainers;
			_remainingContainers = _remainingContainers - _localContainers;
		};
	} forEach (allMapMarkers select { _x find _prefix == 0 });

	//TODO: Optional: call AmmoCaches.SetContainerDetectable on _markedContainers and _remainingContainers so that they start or stop beeping depending on whether they're marked

	1 - (count _remainingContainers) / count _allContainers;
};

OO_TRACE_DECL(SPM_ObjectiveMarkAmmoCaches_Update) =
{
	params ["_objective"];

	[] call OO_METHOD_PARENT(_objective,Category,Update,MissionObjective);

	switch (OO_GET(_objective,MissionObjective,State)) do
	{
		case "starting":
		{
			private _ammoCaches = OO_GET(_objective,ObjectiveMarkAmmoCaches,_AmmoCaches);
			if (count OO_GET(_ammoCaches,AmmoCachesCategory,_Caches) > 0) then
			{
				private _reference = OO_REFERENCE(_objective);
				private _actionTest = OO_GET(_objective,ObjectiveMarkAmmoCaches,ActionTest);
				private _markRadius = OO_GET(_objective,ObjectiveMarkAmmoCaches,MarkRadius);
				private _actionIcon = OO_GET(_objective,ObjectiveMarkAmmoCaches,ActionIcon);
				private _actionIconScale = OO_GET(_objective,ObjectiveMarkAmmoCaches,ActionIconScale);

				{
					{
						[OO_REFERENCE(_objective), _actionTest, _markRadius, _actionIcon, _actionIconScale, _x] remoteExec ["SPM_ObjectiveMarkAmmoCaches_C_AddActions", 0, true]; //JIP
					} forEach ((_x select 1) select { not isNull _x });
				} forEach OO_GET(_ammoCaches,AmmoCachesCategory,_Caches);

				OO_SET(_objective,MissionObjective,State,"active");

				private _objectiveDescription = [] call OO_METHOD(_objective,MissionObjective,GetDescription);
				[_objective, _objectiveDescription, "objective-description"] call OO_METHOD(_objective,Category,SendNotification);
			};
		};

		case "active":
		{
			// If enough containers have been either destroyed or marked, the objective is complete
			if (([_objective] call SPM_ObjectiveMarkAmmoCaches_UpdateAndGetFractionMarked) >= OO_GET(_objective,ObjectiveMarkAmmoCaches,_FractionMarked)) then
			{
				OO_SET(_objective,MissionObjective,State,"succeeded");
			};
		};

		case "succeeded";
		case "failed":
		{
			if (not OO_GET(_objective,ObjectiveMarkAmmoCaches,_SentStatusNotification)) then
			{
				OO_SET(_objective,ObjectiveMarkAmmoCaches,_SentStatusNotification,true);
				[_objective, [format ["%1 (%2)", ([] call OO_METHOD(_objective,MissionObjective,GetDescription)) select 0, OO_GET(_objective,MissionObjective,State)]], "objective-status"] call OO_METHOD(_objective,Category,SendNotification);
			};

			// Keep the marks up to date after completion
			[_objective] call SPM_ObjectiveMarkAmmoCaches_UpdateAndGetFractionMarked;
		};
	};
};

OO_TRACE_DECL(SPM_ObjectiveMarkAmmoCaches_Create) =
{
	params ["_objective", "_ammoCaches", "_fractionMarked"];

	OO_SET(_objective,Category,GetUpdateInterval,{5});

	OO_SET(_objective,ObjectiveMarkAmmoCaches,_AmmoCaches,_ammoCaches);
	OO_SET(_objective,ObjectiveMarkAmmoCaches,_FractionMarked,_fractionMarked);
};

OO_TRACE_DECL(SPM_ObjectiveMarkAmmoCaches_Delete) =
{
	params ["_objective"];

	[] call OO_METHOD_PARENT(_objective,Root,Delete,MissionObjective);

	private _reference = OO_REFERENCE(_objective);
	for "_i" from OO_GET(_objective,ObjectiveMarkAmmoCaches,_MarkerCounter) to 1 step -1 do
	{
		deleteMarker format ["SPM_OMAC_%1_%2", _reference, _i];
	};
};

private _defaultContainersPerCache = [1,4];

OO_BEGIN_SUBCLASS(ObjectiveMarkAmmoCaches,MissionObjective);
	OO_OVERRIDE_METHOD(ObjectiveMarkAmmoCaches,Root,Create,SPM_ObjectiveMarkAmmoCaches_Create);
	OO_OVERRIDE_METHOD(ObjectiveMarkAmmoCaches,Root,Delete,SPM_ObjectiveMarkAmmoCaches_Delete);
	OO_OVERRIDE_METHOD(ObjectiveMarkAmmoCaches,Category,Update,SPM_ObjectiveMarkAmmoCaches_Update);
	OO_OVERRIDE_METHOD(ObjectiveMarkAmmoCaches,MissionObjective,GetDescription,SPM_ObjectiveMarkAmmoCaches_GetDescription);
	OO_DEFINE_PROPERTY(ObjectiveMarkAmmoCaches,_AmmoCaches,"#OBJ",OO_NULL); // The caches to mark
	OO_DEFINE_PROPERTY(ObjectiveMarkAmmoCaches,_FractionMarked,"SCALAR",1.0); // What fraction of the caches need to be marked
	OO_DEFINE_PROPERTY(ObjectiveMarkAmmoCaches,ActionTest,"CODE",{true}); // Run on clients to determine who can mark caches
	OO_DEFINE_PROPERTY(ObjectiveMarkAmmoCaches,ActionIcon,"STRING","\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\danger_ca.paa"); // The icon to show in the middle of the "hold action" while the player holds the space bar
	OO_DEFINE_PROPERTY(ObjectiveMarkAmmoCaches,ActionIconScale,"SCALAR",1.0); // The scaling of the icon to get it to fit in the "hold action" circle
	OO_DEFINE_PROPERTY(ObjectiveMarkAmmoCaches,MarkRadius,"SCALAR",3); // The area covered by a cache mark.  Any containers within that area are considered to be marked.
	OO_DEFINE_PROPERTY(ObjectiveMarkAmmoCaches,MarkerType,"STRING","mil_triangle"); // The type of marker to place on the map when a cache is marked
	OO_DEFINE_PROPERTY(ObjectiveMarkAmmoCaches,MarkerColor,"STRING","ColorOrange"); // MarkerType's color
	OO_DEFINE_PROPERTY(ObjectiveMarkAmmoCaches,_MarkerCounter,"SCALAR",0); // Index of markers that have been created
	OO_DEFINE_PROPERTY(ObjectiveMarkAmmoCaches,_SentStatusNotification,"BOOL",false); // We keep running after completion, so keep track of whether we sent our completion notification
OO_END_SUBCLASS(ObjectiveMarkAmmoCaches);
