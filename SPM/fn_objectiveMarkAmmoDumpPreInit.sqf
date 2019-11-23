/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#include "strongpoint.h"

SPM_ObjectiveMarkAmmoDump_InteractionCondition =
{
	params ["_object"];

	// Don't show action if dump marker is already present
	getMarkerType format ["SPM_OMAD_%1", netID _object] == ""
};

SPM_ObjectiveMarkAmmoDump_Interaction =
{
	titletext ["Ammunition dump marked", "plain down", 0.3];
};

if (not isServer && hasInterface) exitWith {};

OO_TRACE_DECL(SPM_ObjectiveMarkAmmoDump_OnInteractionComplete) =
{
	params ["_objective", "_interactor"];

	private _object = OO_GET(_objective,MissionObjective,ObjectiveObject);

	private _marker = createMarker [format ["SPM_OMAD_%1", netID _object], getPos _object];
	_marker setMarkerType OO_GET(_objective,ObjectiveMarkAmmoDump,MarkerType);
	_marker setMarkerColor OO_GET(_objective,ObjectiveMarkAmmoDump,MarkerColor);

	OO_SET(_objective,ObjectiveMarkAmmoDump,_Marker,_marker);

	_object addEventHandler ["Killed", compile format ["deleteMarker '%1'", _marker]];

	[_interactor] call OO_METHOD_PARENT(_objective,ObjectiveInteractObject,OnInteractionComplete,ObjectiveInteractObject);
};

OO_TRACE_DECL(SPM_ObjectiveMarkAmmoDump_Update) =
{
	params ["_objective"];

	switch (OO_GET(_objective,MissionObjective,State)) do
	{
		case "starting":
		{
			if (isNull OO_GET(_objective,MissionObjective,ObjectiveObject)) then
			{
				private _ammoDump = OO_GET(_objective,ObjectiveMarkAmmoDump,_AmmoDump);
				private _triggerObject = OO_GET(_ammoDump,AmmoDumpCategory,TriggerObject);

				if (not isNull _triggerObject) then
				{
					OO_SET(_objective,MissionObjective,ObjectiveObject,_triggerObject);
				};
			};
		};

		case "active":
		{
			// If the ammo dump trigger is destroyed, then the objective is completed
			private _object = OO_GET(_objective,MissionObjective,ObjectiveObject);
			if (not alive _object) then
			{
				private _marker = OO_GET(_objective,ObjectiveMarkAmmoDump,_Marker);
				if (_marker != "") then { deleteMarker _marker };

				OO_SET(_objective,MissionObjective,State,"succeeded");
			};
		};
	};

	// Must be called after so that we can complete the objective if the dump is destroyed
	[] call OO_METHOD_PARENT(_objective,Category,Update,ObjectiveInteractObject);
};

OO_TRACE_DECL(SPM_ObjectiveMarkAmmoDump_Delete) =
{
	params ["_objective"];

	[] call OO_METHOD_PARENT(_objective,Root,Delete,ObjectiveInteractObject);

	private _marker = OO_GET(_objective,ObjectiveMarkAmmoDump,_Marker);
	if (_marker != "") then { deleteMarker _marker };
};

OO_TRACE_DECL(SPM_ObjectiveMarkAmmoDump_Create) =
{
	params ["_objective", "_ammoDump"];

	OO_SET(_objective,ObjectiveMarkAmmoDump,_AmmoDump,_ammoDump);

	private _objectiveDescription = ["Mark ammunition dump for demolition", "Locate the barrel in the ammunition dump and use its scroll wheel action to mark the location of the dump for the EOD team."];
	OO_SET(_objective,ObjectiveInteractObject,ObjectiveDescription,_objectiveDescription);
	OO_SET(_objective,ObjectiveInteractObject,InteractionDescription,"Mark ammunition dump");
	OO_SET(_objective,ObjectiveInteractObject,InteractionCondition,{_this call SPM_ObjectiveMarkAmmoDump_InteractionCondition});
	OO_SET(_objective,ObjectiveInteractObject,Interaction,{_this call SPM_ObjectiveMarkAmmoDump_Interaction});
	OO_SET(_objective,ObjectiveInteractObject,ActionIcon,"\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\danger_ca.paa");
	OO_SET(_objective,ObjectiveInteractObject,ActionIconScale,1.5);
};

OO_BEGIN_SUBCLASS(ObjectiveMarkAmmoDump,ObjectiveInteractObject);
	OO_OVERRIDE_METHOD(ObjectiveMarkAmmoDump,Root,Create,SPM_ObjectiveMarkAmmoDump_Create);
	OO_OVERRIDE_METHOD(ObjectiveMarkAmmoDump,Root,Delete,SPM_ObjectiveMarkAmmoDump_Delete);
	OO_OVERRIDE_METHOD(ObjectiveMarkAmmoDump,Category,Update,SPM_ObjectiveMarkAmmoDump_Update);
	OO_OVERRIDE_METHOD(ObjectiveMarkAmmoDump,ObjectiveInteractObject,OnInteractionComplete,SPM_ObjectiveMarkAmmoDump_OnInteractionComplete);
	OO_DEFINE_PROPERTY(ObjectiveMarkAmmoDump,MarkerType,"STRING","mil_triangle"); // The type of marker to place on the map when the dump is marked
	OO_DEFINE_PROPERTY(ObjectiveMarkAmmoDump,MarkerColor,"STRING","ColorRed"); // MarkerType's color
	OO_DEFINE_PROPERTY(ObjectiveMarkAmmoDump,_AmmoDump,"#OBJ",OO_NULL);
	OO_DEFINE_PROPERTY(ObjectiveMarkAmmoDump,_Marker,"STRING","");
OO_END_SUBCLASS(ObjectiveMarkAmmoDump);