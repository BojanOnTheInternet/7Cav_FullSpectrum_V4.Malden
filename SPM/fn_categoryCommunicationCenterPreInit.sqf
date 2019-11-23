/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#include "strongpoint.h"

SPM_CommunicationCenter_CommChatter =
[
	["SPM_AmbientRadio2", 9.733],
	["SPM_AmbientRadio6", 6.557],
	["SPM_AmbientRadio8", 11.638]
];

SPM_CommunicationCenter_CommNoise =
[
	["SPM_RadioNoise1", 5.719],
	["SPM_RadioNoise2", 5.719],
	["SPM_RadioNoise3", 5.719]
];

OO_TRACE_DECL(SPM_CommunicationCenter_CommunicationChatter) =
{
	params ["_device", "_indoor"];

	scriptName "SPM_CommunicationCenter_CommunicationChatter";

	private _noiseEndTime = 0;
	private _chatterEndTime = 0;
	private _radioNoise = [];
	private _radioChatter = [];

	private _devicePosition = [];

	while { alive _device } do
	{
		_devicePosition = getPos _device;

		if (diag_tickTime > _noiseEndTime) then
		{
			if (count _radioNoise == 0) then { _radioNoise = +SPM_CommunicationCenter_CommNoise };
			private _noise = _radioNoise deleteAt floor random count _radioNoise;
			_device say3D (_noise select 0);
			_noiseEndTime = diag_tickTime + (_noise select 1);
		};

		if (diag_tickTime > _chatterEndTime) then
		{
			if (count _radioChatter == 0) then { _radioChatter = +SPM_CommunicationCenter_CommChatter };
			private _chatter = _radioChatter deleteAt floor random count _radioChatter;
			_device say3D (_chatter select 0);
			_chatterEndTime = diag_tickTime + (_chatter select 1) + random 8;
		};

		sleep 0.5;
	};

	while { count _devicePosition > 0 } do
	{
		private _nearestSound = _devicePosition nearestobject "#soundonvehicle";
		if (isNull _nearestSound || { _nearestSound distance _device > 1.0 }) exitWith {};
		deleteVehicle _nearestSound;
	};
};

if (not isServer && hasInterface) exitWith {};

OO_TRACE_DECL(SPM_CommunicationCenter_FindClearing) =
{
	params ["_area", "_clearingRadius"];

	private _center = OO_GET(_area,StrongpointArea,Position);
	private _innerRadius = OO_GET(_area,StrongpointArea,InnerRadius);
	private _outerRadius = OO_GET(_area,StrongpointArea,OuterRadius);

	private _positions = [];
	while { _innerRadius <= _outerRadius } do
	{
		_positions = [_center, _innerRadius, _innerRadius + (_clearingRadius * 3.0), (_clearingRadius * 0.5)] call SPM_Util_SampleAreaGrid;
		[_positions, ["#GdtRoad", "#GdtWater"]] call SPM_Util_ExcludeSamplesBySurfaceType;
		[_positions, 10, 90] call SPM_Util_ExcludeSamplesBySurfaceIncline;
		[_positions, _clearingRadius, ["WALL", "BUILDING", "HOUSE", "ROCK", "ROAD", "ENTITY"]] call SPM_Util_ExcludeSamplesByProximity;

		if (count _positions > 0) exitWith { };

		_innerRadius = _innerRadius + (_clearingRadius * 3.0);
	};

	private _position = if (count _positions == 0) then { _center } else { selectRandom _positions };

	private _blockingObjects = nearestTerrainObjects [_position, ["TREE", "SMALL TREE", "BUSH", "HIDE", "FENCE"], _clearingRadius, false, true];
	{
		_x hideObjectGlobal true;
	} forEach _blockingObjects;

	[_position, _blockingObjects]
};

OO_TRACE_DECL(SPM_CommunicationCenter_Create) =
{
	params ["_category", "_garrison"];

	OO_SETREF(_category,CommunicationCenterCategory,Garrison,_garrison);
};

OO_BEGIN_SUBCLASS(CommunicationCenterCategory,Category);
	OO_OVERRIDE_METHOD(CommunicationCenterCategory,Root,Create,SPM_CommunicationCenter_Create);
	OO_DEFINE_PROPERTY(CommunicationCenterCategory,Garrison,"#REF",OO_NULL);
	OO_DEFINE_PROPERTY(CommunicationCenterCategory,CommunicationsOnline,"BOOL",false);
	OO_DEFINE_PROPERTY(CommunicationCenterCategory,CommunicationDevice,"OBJECT",objNull);
OO_END_SUBCLASS(CommunicationCenterCategory);