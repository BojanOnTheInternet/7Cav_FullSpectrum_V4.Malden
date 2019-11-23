/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_ObjectiveInteractObjectConvoyVehicle_Update) =
{
	params ["_objective"];

	[] call OO_METHOD_PARENT(_objective,Category,Update,ObjectiveInteractObject);

	// Announce immediately because the convoy mission will announce before it creates the convoy vehicles
	if (not OO_GET(_objective,ObjectiveInteractObject,ObjectiveAnnounced)) then
	{
		private _objectiveDescription = [] call OO_METHOD(_objective,MissionObjective,GetDescription);
		[_objective, _objectiveDescription, "objective-description"] call OO_METHOD(_objective,Category,SendNotification);
		OO_SET(_objective,ObjectiveInteractObject,ObjectiveAnnounced,true)
	};

	if (OO_GET(_objective,MissionObjective,State) == "starting") then
	{
		private _mission = OO_GETREF(_objective,Category,Strongpoint);
		private _operation = OO_GET(_mission,MissionInterceptConvoy,ConvoyOperation);
		private _requests = OO_GET(_operation,TransportOperation,Requests);
		if (count _requests > 0) then
		{
			private _request = _requests select OO_GET(_objective,ObjectiveInteractObjectConvoyVehicle,RequestNumber);
			private _forceUnit = OO_GET(_request,TransportRequest,ForceUnit);
			if (count _forceUnit > 0) then
			{
				private _vehicle = OO_GET(_forceUnit,ForceUnit,Vehicle);
				if (not isNull _vehicle) then
				{
					OO_SET(_objective,MissionObjective,ObjectiveObject,_vehicle);
				};
			};
		};
	};
};

OO_TRACE_DECL(SPM_ObjectiveInteractObjectConvoyVehicle_Create) =
{
	params ["_objective", "_requestNumber"];

	[] call OO_METHOD_PARENT(_objective,Root,Create,ObjectiveInteractObject);

	OO_SET(_objective,ObjectiveInteractObjectConvoyVehicle,RequestNumber,_requestNumber);
};

OO_BEGIN_SUBCLASS(ObjectiveInteractObjectConvoyVehicle,ObjectiveInteractObject);
	OO_OVERRIDE_METHOD(ObjectiveInteractObjectConvoyVehicle,Root,Create,SPM_ObjectiveInteractObjectConvoyVehicle_Create);
	OO_OVERRIDE_METHOD(ObjectiveInteractObjectConvoyVehicle,Category,Update,SPM_ObjectiveInteractObjectConvoyVehicle_Update);
	OO_DEFINE_PROPERTY(ObjectiveInteractObjectConvoyVehicle,RequestNumber,"SCALAR",-1);
OO_END_SUBCLASS(ObjectiveInteractObjectConvoyVehicle);
