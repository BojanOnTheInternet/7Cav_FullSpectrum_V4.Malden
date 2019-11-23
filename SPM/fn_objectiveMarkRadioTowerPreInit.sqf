/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#include "strongpoint.h"

SPM_ObjectiveMarkRadioTower_InteractionCondition =
{
	params ["_object"];

	// Don't show action if dump marker is already present
	getMarkerType format ["SPM_OMRT_%1", netID _object] == ""
};

SPM_ObjectiveMarkRadioTower_Interaction =
{
	titletext ["Radio tower marked", "plain down", 0.3];
};

if (not isServer && hasInterface) exitWith {};

OO_TRACE_DECL(SPM_ObjectiveMarkRadioTower_OnInteractionComplete) =
{
	params ["_objective", "_interactor"];

	private _object = OO_GET(_objective,MissionObjective,ObjectiveObject);

	private _marker = createMarker [format ["SPM_OMRT_%1", netID _object], getPos _object];
	_marker setMarkerType OO_GET(_objective,ObjectiveMarkRadioTower,MarkerType);
	_marker setMarkerColor OO_GET(_objective,ObjectiveMarkRadioTower,MarkerColor);

	OO_SET(_objective,ObjectiveMarkRadioTower,_Marker,_marker);

	_object addEventHandler ["Killed", compile format ["deleteMarker '%1'", _marker]];

	[_interactor] call OO_METHOD_PARENT(_objective,ObjectiveInteractObject,OnInteractionComplete,ObjectiveInteractObject);
};

OO_TRACE_DECL(SPM_ObjectiveMarkRadioTower_Update) =
{
	params ["_objective"];

	switch (OO_GET(_objective,MissionObjective,State)) do
	{
		case "starting":
		{
			if (isNull OO_GET(_objective,MissionObjective,ObjectiveObject)) then
			{
				private _category = OO_GET(_objective,ObjectiveMarkRadioTower,_RadioTower);
				private _radioTower = OO_GET(_category,RadioTowerCategory,RadioTower);

				if (not isNil "_radioTower") then
				{
					if (isNull _radioTower) then
					{
						OO_SET(_objective,MissionObjective,State,"error");
					}
					else
					{
						OO_SET(_objective,MissionObjective,ObjectiveObject,_radioTower);
					}
				};
			};
		};

		case "active":
		{
			// If the radio tower is destroyed, then the objective is completed
			private _object = OO_GET(_objective,MissionObjective,ObjectiveObject);
			if (not alive _object) then
			{
				private _marker = OO_GET(_objective,ObjectiveMarkRadioTower,_Marker);
				if (_marker != "") then { deleteMarker _marker };

				OO_SET(_objective,MissionObjective,State,"succeeded")
			};
		};
	};

	// Must be called after so that we can complete the objective if the tower is destroyed
	[] call OO_METHOD_PARENT(_objective,Category,Update,ObjectiveInteractObject);
};

OO_TRACE_DECL(SPM_ObjectiveMarkRadioTower_Delete) =
{
	params ["_objective"];

	[] call OO_METHOD_PARENT(_objective,Root,Delete,ObjectiveInteractObject);

	private _marker = OO_GET(_objective,ObjectiveMarkRadioTower,_Marker);
	if (_marker != "") then { deleteMarker _marker };
};

OO_TRACE_DECL(SPM_ObjectiveMarkRadioTower_Create) =
{
	params ["_objective", "_radioTower"];

	OO_SET(_objective,ObjectiveMarkRadioTower,_RadioTower,_radioTower);

	private _objectiveDescription = ["Mark radio tower for demolition", "Locate the radio tower and use its scroll wheel action to mark the location of the tower for the EOD team."];
	OO_SET(_objective,ObjectiveInteractObject,ObjectiveDescription,_objectiveDescription);
	OO_SET(_objective,ObjectiveInteractObject,InteractionDescription,"Mark radio tower");
	OO_SET(_objective,ObjectiveInteractObject,InteractionCondition,{_this call SPM_ObjectiveMarkRadioTower_InteractionCondition});
	OO_SET(_objective,ObjectiveInteractObject,Interaction,{_this call SPM_ObjectiveMarkRadioTower_Interaction});
	OO_SET(_objective,ObjectiveInteractObject,ActionIcon,"\a3\ui_f\data\IGUI\Cfg\simpleTasks\types\danger_ca.paa");
	OO_SET(_objective,ObjectiveInteractObject,ActionIconScale,1.5);
};

OO_BEGIN_SUBCLASS(ObjectiveMarkRadioTower,ObjectiveInteractObject);
	OO_OVERRIDE_METHOD(ObjectiveMarkRadioTower,Root,Create,SPM_ObjectiveMarkRadioTower_Create);
	OO_OVERRIDE_METHOD(ObjectiveMarkRadioTower,Root,Delete,SPM_ObjectiveMarkRadioTower_Delete);
	OO_OVERRIDE_METHOD(ObjectiveMarkRadioTower,Category,Update,SPM_ObjectiveMarkRadioTower_Update);
	OO_OVERRIDE_METHOD(ObjectiveMarkRadioTower,ObjectiveInteractObject,OnInteractionComplete,SPM_ObjectiveMarkRadioTower_OnInteractionComplete);
	OO_DEFINE_PROPERTY(ObjectiveMarkRadioTower,MarkerType,"STRING","mil_triangle"); // The type of marker to place on the map when the dump is marked
	OO_DEFINE_PROPERTY(ObjectiveMarkRadioTower,MarkerColor,"STRING","ColorYellow"); // MarkerType's color
	OO_DEFINE_PROPERTY(ObjectiveMarkRadioTower,_RadioTower,"#OBJ",OO_NULL);
	OO_DEFINE_PROPERTY(ObjectiveMarkRadioTower,_Marker,"STRING","");
OO_END_SUBCLASS(ObjectiveMarkRadioTower);