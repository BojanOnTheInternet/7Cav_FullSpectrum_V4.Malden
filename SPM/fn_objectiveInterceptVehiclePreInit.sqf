/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_ObjectiveInterceptVehicle_TransportOnLoad) =
{
	params ["_request"];

	private _forceUnit = OO_GET(_request,TransportRequest,ForceUnit);
	private _vehicle = OO_GET(_forceUnit,ForceUnit,Vehicle);

	private _clientData = OO_GET(_request,TransportRequest,ClientData);
	private _objective = _clientData select 1;

	OO_SET(_objective,ObjectiveInterceptVehicle,Vehicle,_vehicle);

	[_vehicle, "OIV", "OBJECTIVE"] call TRACE_SetObjectString;

	true
};

OO_TRACE_DECL(SPM_ObjectiveInterceptVehicle_ModifyConvoyOperation) =
{
	params ["_objective", "_convoyOperation"];

	private _mission = OO_GETREF(_objective,Category,Strongpoint);

	private _convoyVehicle = OO_GET(_objective,ObjectiveInterceptVehicle,ConvoyVehicle);
	private _request = [_convoyVehicle] call OO_METHOD(_mission,MissionInterceptConvoy,CreateRequest);
	private _clientData = OO_GET(_request,TransportRequest,ClientData);
	_clientData set [1, _objective];

	private _destination = OO_GET(_mission,Strongpoint,Position);
	OO_SET(_request,TransportRequest,Destination,_destination);
	OO_SET(_request,TransportRequest,OnLoad,SPM_ObjectiveInterceptVehicle_TransportOnLoad);

	private _requestCount = count OO_GET(_convoyOperation,TransportOperation,Requests);
	[_request, floor (_requestCount / 2)] call OO_METHOD(_convoyOperation,TransportOperation,AddRequest);

	OO_SETREF(_objective,ObjectiveInterceptVehicle,_VehicleRequest,_request);
	OO_SET(_objective,MissionObjective,State,"succeeded");

	private _objectiveDescription = [] call OO_METHOD(_objective,MissionObjective,GetDescription);
	[_objective, _objectiveDescription, "objective-description"] call OO_METHOD(_objective,Category,SendNotification);
};

OO_TRACE_DECL(SPM_ObjectiveInterceptVehicle_GetDescription) =
{
	params ["_objective"];

	OO_GET(_objective,ObjectiveInterceptVehicle,ObjectiveDescription);
};

OO_TRACE_DECL(SPM_ObjectiveInterceptVehicle_Update) =
{
	params ["_objective"];

	[] call OO_METHOD_PARENT(_objective,Category,Update,ConvoyObjective);

	private _vehicle = OO_GET(_objective,ObjectiveInterceptVehicle,Vehicle);
	if (not isNil "_vehicle") then
	{
		if (isNull _vehicle) exitWith { OO_SET(_objective,MissionObjective,State,"error") };
		if (not alive _vehicle) exitWith
		{
			OO_SET(_objective,MissionObjective,State,"failed");
			[_objective, ["Interception failed.  Target has been destroyed", ""], "event"] call OO_METHOD(_objective,Category,SendNotification);
		};

		private _request = OO_GETREF(_objective,ObjectiveInterceptVehicle,_VehicleRequest);
		private _destination = OO_GET(_request,TransportRequest,Destination);

		if (_vehicle distance _destination < 100) exitWith
		{
			OO_SET(_objective,MissionObjective,State,"failed");
			[_objective, ["Interception failed.  Target has reached its destination", ""], "event"] call OO_METHOD(_objective,Category,SendNotification);
		};
	};
};

OO_TRACE_DECL(SPM_ObjectiveInterceptVehicle_Create) =
{
	params ["_objective", "_convoyVehicle", "_objectiveDescription"];

	OO_SET(_objective,Category,GetUpdateInterval,{5});
	OO_SET(_objective,ObjectiveInterceptVehicle,ConvoyVehicle,_convoyVehicle);
	OO_SET(_objective,ObjectiveInterceptVehicle,ObjectiveDescription,_objectiveDescription);
};

private _objectiveDescription = ["",""];

OO_BEGIN_SUBCLASS(ObjectiveInterceptVehicle,ConvoyObjective);
	OO_OVERRIDE_METHOD(ObjectiveInterceptVehicle,Root,Create,SPM_ObjectiveInterceptVehicle_Create);
	OO_OVERRIDE_METHOD(ObjectiveInterceptVehicle,Category,Update,SPM_ObjectiveInterceptVehicle_Update);
	OO_OVERRIDE_METHOD(ObjectiveInterceptVehicle,MissionObjective,GetDescription,SPM_ObjectiveInterceptVehicle_GetDescription);
	OO_OVERRIDE_METHOD(ObjectiveInterceptVehicle,ConvoyObjective,ModifyConvoyOperation,SPM_ObjectiveInterceptVehicle_ModifyConvoyOperation);
	OO_DEFINE_PROPERTY(ObjectiveInterceptVehicle,Vehicle,"OBJECT",nil);
	OO_DEFINE_PROPERTY(ObjectiveInterceptVehicle,ConvoyVehicle,"ARRAY",[]); // ConvoyVehicle structure
	OO_DEFINE_PROPERTY(ObjectiveInterceptVehicle,ObjectiveDescription,"ARRAY",_objectiveDescription);
	OO_DEFINE_PROPERTY(ObjectiveInterceptVehicle,_VehicleRequest,"#REF",OO_NULL);
OO_END_SUBCLASS(ObjectiveInterceptVehicle);
