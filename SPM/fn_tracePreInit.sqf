/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

TRACE_ObjectStrings = [];
TRACE_ObjectPositions = [];

TRACE_C_SetObjectValue =
{
	params ["_keyObject", "_keyName", "_keyValue", "_valueType"];

	if (isNil "_keyObject") exitWith {}; // 1.0.15 saw nils (which means bugs elsewhere), so just defending against them here

	private _list = switch (_valueType) do
	{
		case "string": { TRACE_ObjectStrings };
		case "position": { TRACE_ObjectPositions };
		default { [] };
	};
	
	private _object = objNull;
	private _index = -1;
	{
		_object = _x select 0;
		if (typeName _object == typeName _keyObject && { _object == _keyObject }) exitWith { _index = _forEachIndex };
	} forEach _list;

	if (_index == -1) then
	{
		if (not isNil "_keyValue") then
		{
			_list pushBack [_keyObject, [[_keyName, _keyValue]]];
		};
	}
	else
	{
		private _namedValues = _list select _index select 1;
		private _keyNameIndex = [_namedValues, _keyName] call BIS_fnc_findInPairs;
		if (_keyNameIndex == -1) then
		{
			if (not isNil "_keyValue") then
			{
				_namedValues pushBack [_keyName, _keyValue];
			};
		}
		else
		{
			if (not isNil "_keyValue") then
			{
				(_namedValues select _keyNameIndex) set [1, _keyValue];
			}
			else
			{
				_namedValues deleteAt _keyNameIndex;
			};
		};
	};
};

TRACE_DrawObjectValues =
{
	if (CLIENT_CuratorType != "MC" || { (getPos curatorCamera) select 0 == 0 }) exitWith {}; // Only for mission controller curators when in Zeus

	private _position = [];
	private _fullLine = "";

	TRACE_ObjectStrings = TRACE_ObjectStrings select
	{
		switch (typeName (_x select 0)) do
		{
			case "GROUP": { { alive _x } count units (_x select 0) > 0 };
			case "OBJECT": { alive (_x select 0) };
			default { false }
		};
	};

	private _object = nil;
	{
		_object = _x select 0;
		if (typeName _object == "GROUP") then { _object = leader _object };

		_position = getPosVisual _object;
		_position set [2, getPosATL _object select 2];
		_fullLine = ((_x select 1) apply { _x select 1 }) joinString ", ";
		drawIcon3D ["", [1,1,1,1], _position, 0, 0, 0, _fullLine, 1, 0.04, "PuristaMedium"];
	} forEach TRACE_ObjectStrings;

	TRACE_ObjectPositions = TRACE_ObjectPositions select { alive (_x select 0) };

	{
		_position = getPosATL (_x select 0) vectorAdd [0,0,2];
		if (surfaceIsWater _position) then { _position = AGLtoASL _position };

		{
			drawLine3D [_position, _x select 1, [1,0,0,1]];
		} forEach (_x select 1);
	} forEach TRACE_ObjectPositions;
};

if (not isServer && hasInterface) exitWith {};

TRACE_SetObjectString =
{
	params ["_keyObject", "_keyName", "_keyValue"];

	[[_keyObject, _keyName, if (isNil "_keyValue") then { nil } else { _keyValue }, "string"], "TRACE_C_SetObjectValue", ["MC"]] call SERVER_RemoteExecCurators;
};

TRACE_SetObjectPosition =
{
	params ["_keyObject", "_keyName", "_keyValue"];

	[[_keyObject, _keyName, if (isNil "_keyValue") then { nil } else { _keyValue }, "position"], "TRACE_C_SetObjectValue", ["MC"]] call SERVER_RemoteExecCurators;
};
