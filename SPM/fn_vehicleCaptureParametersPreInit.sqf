/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

OO_TRACE_DECL(SPM_VehicleCaptureParameters_GetInHandler) =
{
	params ["_vehicle", "_position", "_unit", "_turret"];

	private _parameters = _vehicle getVariable "SPM_VehicleCaptureParameters";

	// If non-west gets in, then reset the capture position
	if (side ((crew _vehicle) select 0) != OO_GET(_parameters,VehicleCaptureParameters,SideWest)) then
	{
		OO_SET(_parameters,VehicleCaptureParameters,_CapturePosition,[]);
	}
	else
	{
		// If west gets in, and it's the only character in the vehicle and we haven't set the capture position, set it
		if (count crew _vehicle == 1) then
		{
			if (count OO_GET(_parameters,VehicleCaptureParameters,_CapturePosition) == 0) then
			{
				OO_SET(_parameters,VehicleCaptureParameters,_CapturePosition,getPos _unit);
			};
		};
	};
};

OO_TRACE_DECL(SPM_VehicleCaptureParameters_Create) =
{
	params ["_parameters", "_vehicle", "_sideWest"];

	OO_SET(_parameters,VehicleCaptureParameters,Vehicle,_vehicle);
	OO_SET(_parameters,VehicleCaptureParameters,SideWest,_sideWest);

	private _getInHandler = _vehicle addEventHandler ["GetIn", SPM_VehicleCaptureParameters_GetInHandler];
	OO_SET(_parameters,VehicleCaptureParameters,_GetInHandler,_getInHandler);

	_vehicle setVariable ["SPM_VehicleCaptureParameters", _parameters];
};

OO_TRACE_DECL(SPM_VehicleCaptureParameters_Delete) =
{
	params ["_parameters"];

	private _vehicle = OO_GET(_parameters,VehicleCaptureParameters,Vehicle);
	_vehicle removeEventHandler ["GetIn", OO_GET(_parameters,VehicleCaptureParameters,_GetInHandler)];
	_vehicle setVariable ["SPM_VehicleCaptureParameters", nil];
};

OO_TRACE_DECL(SPM_VehicleCaptureParameters_IsCaptured) =
{
	params ["_parameters"];

	private _isCaptured = false;

	private _vehicle = OO_GET(_parameters,VehicleCaptureParameters,Vehicle);

	private _captureDistance = OO_GET(_parameters,VehicleCaptureParameters,CaptureDistance);
	if (_captureDistance < 1e30) then
	{
		private _capturePosition = OO_GET(_parameters,VehicleCaptureParameters,_CapturePosition);
		if (count _capturePosition > 0 && { _capturePosition distance _vehicle > _captureDistance }) then
		{
			_isCaptured = true;
		};
	};

	private _secureArea = OO_GET(_parameters,VehicleCaptureParameters,SecureArea);
	if (count _secureArea > 0 && { [getPos _vehicle, _secureArea] call SPM_Util_PositionInArea }) then
	{
		_isCaptured = true;
	};

	_isCaptured
};

OO_BEGIN_STRUCT(VehicleCaptureParameters);
	OO_OVERRIDE_METHOD(VehicleCaptureParameters,Root,Create,SPM_VehicleCaptureParameters_Create);
	OO_DEFINE_METHOD(VehicleCaptureParameters,Delete,SPM_VehicleCaptureParameters_Delete);
	OO_DEFINE_METHOD(VehicleCaptureParameters,IsCaptured,SPM_VehicleCaptureParameters_IsCaptured);
	OO_DEFINE_PROPERTY(VehicleCaptureParameters,Vehicle,"OBJECT",objNull);
	OO_DEFINE_PROPERTY(VehicleCaptureParameters,SideWest,"side",sideUnknown);
	OO_DEFINE_PROPERTY(VehicleCaptureParameters,SecureArea,"ARRAY",[]);
	OO_DEFINE_PROPERTY(VehicleCaptureParameters,CaptureDistance,"SCALAR",1000);
	OO_DEFINE_PROPERTY(VehicleCaptureParameters,_CapturePosition,"ARRAY",[]);
	OO_DEFINE_PROPERTY(VehicleCaptureParameters,_GetInHandler,"SCALAR",-1);
OO_END_STRUCT(VehicleCaptureParameters);