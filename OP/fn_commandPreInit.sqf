/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "..\SPM\strongpoint.h"
#include "op.h"

OO_TRACE_DECL(OP_COMMAND_Match) =
{
	params ["_commandWord", "_commands"];

	if (isNil "_commandWord") exitWith
	{
		[OP_COMMAND_RESULT_NOCOMMAND, _commands apply { _x select 0 }]
	};

	private _result = [OP_COMMAND_RESULT_UNRECOGNIZED, _commandWord];

	private _executeWord = toLower _commandWord;
	private _executeWordLength = count _executeWord;
	{
		if (_executeWord == (_x select 0)) exitWith
		{
			_result = [OP_COMMAND_RESULT_MATCHED, _x];
		};

		private _partialMatch = ((_x select 0) find _executeWord == 0);

		if (_partialMatch && (_result select 0) == OP_COMMAND_RESULT_MATCHED) exitWith
		{
			_result = [OP_COMMAND_RESULT_AMBIGUOUS, _commandWord];
		};

		if (_partialMatch) then
		{
			_result = [OP_COMMAND_RESULT_MATCHED, _x];
		};
	} forEach _commands;

	_result
};

OO_TRACE_DECL(OP_COMMAND_ParseString) =
{
	params ["_commandStringCharacters", "_start"];

	private _startCharacter = _commandStringCharacters select _start;
	_commandStringCharacters deleteAt _start;

	private _scan = _start;
	private _end = -1;
	while { _scan < count _commandStringCharacters && _end == -1 } do
	{
		if (_commandStringCharacters select _scan != _startCharacter) then
		{
			_scan = _scan + 1;
		}
		else
		{
			_commandStringCharacters deleteAt _scan;
			if (_scan < count _commandStringCharacters - 1 && { _commandStringCharacters select _scan == _startCharacter}) then
			{
				_scan = _scan + 1;
			}
			else
			{
				_end = _scan;
			};
		};
	};

	[_end, (_commandStringCharacters select [_start, _end - _start]) joinString ""]
};

OO_TRACE_DECL(OP_COMMAND_GetWords) =
{
	params ["_commandString"];

	private _commandStringCharacters = _commandString splitString "";
	private _pieces = [[]];

	private _i = 0;
	while { _i < count _commandStringCharacters } do
	{
		if (not ((_commandStringCharacters select _i) in ["'", """"])) then
		{
			(_pieces select (count _pieces - 1)) pushBack (_commandStringCharacters select _i);
		}
		else
		{
			private _result = [_commandStringCharacters, _i] call OP_COMMAND_ParseString;
			_i = _result select 0;
			_pieces pushBack (_result select 1);
			_pieces pushBack [];
		};

		_i = _i + 1;
	};

	private _words = [];
	{
		if (_x isEqualType "") then
		{
			_words pushBack _x;
		}
		else
		{
			_words append ((_x joinString "") splitString " ");
		};
	} forEach _pieces;

	_words
};

OO_TRACE_DECL(OP_COMMAND_ParseEnumeration) =
{
	params ["_parameter", "_value", "_enumeratedValues"];

	private _matches = [];
	switch (typeName _value) do
	{
		case (typeName ""):
		{
			{
				if (_x find _value == 0) then { _matches pushBack _forEachIndex };
			} forEach _enumeratedValues;
		};
		case (typeName 0):
		{
			private _match = _enumeratedValues find _value;
			if (_match != -1) then { _matches pushBack _match };
		};
	};

	switch (count _matches) do
	{
		case 0: { [format ["The '%1' parameter value '%2' is invalid.  Use one of %3", _parameter, _value, _enumeratedValues]] call SPM_Util_MessageCaller; [-1, _parameter] };
		case 1: { [0, _parameter, _enumeratedValues select (_matches select 0)] };
		default { [format ["The '%1' parameter value '%2' is ambiguous.  Use one of %3", _parameter, _value, _enumeratedValues]] call SPM_Util_MessageCaller; [-1, _parameter] };
	};
};

OP_COMMAND_Directions =
[
	["N", 0],
	["S", 180],
	["E", 90],
	["W", 270],
	["NE", 45],
	["NW", 315],
	["SE", 135],
	["SW", 225]
];

OP_COMMAND_Locations = (nearestLocations [[worldSize / 2, worldSize / 2, 0], ["NameVillage", "NameCity", "NameCityCapital"], worldSize]) apply { [text _x, position _x] };

OO_TRACE_DECL(OP_COMMAND_ParseParameter) =
{
	params ["_commandWords", "_parameterName", "_requiredParameter", "_requiredValue", "_valueDataType", "_defaultValue", "_enumeratedValues"];

	private _matches = [];
	{
		if (_parameterName find _x == 0) then { _matches pushBack _forEachIndex };
	} forEach _commandWords;

	if (count _matches > 1) exitWith
	{
		[format ["'%1' is an ambiguous parameter name", _parameterName]] call SPM_Util_MessageCaller; [-1, _parameterName];
	};

	if (count _matches == 0) exitWith
	{
		if (not _requiredParameter) then { [1, _parameterName, if (isNil "_defaultValue") then { nil } else { _defaultValue }] } else { [format ["The '%1' parameter is required", _parameterName]] call SPM_Util_MessageCaller; [-1, _parameterName] };
	};

	private _index = _matches select 0;

	private _value = _commandWords select (_index + 1);
	if (isNil "_value" || { _value find "-" == 0 }) exitWith
	{
		if (not _requiredValue) then { [0, _parameterName, if (isNil "_defaultValue") then { nil } else { _defaultValue }] } else { [format ["The '%1' parameter requires a value", _parameterName]] call SPM_Util_MessageCaller; [-1, _parameterName] };
	};

	switch (_valueDataType) do
	{
		case "":
		{
			[format ["The '%1' parameter does not take a value", _parameterName]] call SPM_Util_MessageCaller;
			[-1, _parameterName]
		};

		case "STRING":
		{
			if (isNil "_enumeratedValues") then
			{
				[0, _parameterName, _value]
			}
			else
			{
				[_parameterName, _value, _enumeratedValues] call OP_COMMAND_ParseEnumeration;
			};
		};
		case "SCALAR":
		{
			private _valueArray = toArray _value;
			if (_valueArray select 0 < 48 || _valueArray select 0 > 57) then
			{
				[format ["The '%1' parameter value must be a number", _parameterName]] call SPM_Util_MessageCaller;
				[-1, _parameterName]
			}
			else
			{
				_value = parseNumber _value;
				if (isNil "_enumeratedValues") then
				{
					[0, _parameterName, _value]
				}
				else
				{
					[_parameterName, _value, _enumeratedValues] call OP_COMMAND_ParseEnumeration;
				};
			};
		};
		case "#RANGE":
		{
			private _result = [-1, _parameterName];

			private _pieces = _value splitString "..";
			if (count _pieces != 2) then
			{
				[format ["The '%1' parameter value must be of the format number..number", _parameterName]] call SPM_Util_MessageCaller;
			}
			else
			{
				_pieces = _pieces apply { private _valueArray = toArray _x; if (_valueArray select 0 >= 48 && _valueArray select 0 <= 57) then { parseNumber _x } else { nil } };
				if ({ isNil "_x" } count _pieces > 0) then
				{
					[format ["The '%1' parameter value must be of the format number..number", _parameterName]] call SPM_Util_MessageCaller;
				}
				else
				{
					if (_pieces select 0 > _pieces select 1) then
					{
						[format ["The '%1' parameter value's second value must be greater than or equal to the first value", _parameterName]] call SPM_Util_MessageCaller;
					}
					else
					{
						_result = [0, _parameterName, _pieces];
					};
				};
			};
			_result
		};
		case "#DIRECTION":
		{
			private _result = [-1, _parameterName];

			private _pieces = _value splitString ",";
			if (count _pieces != 2) then
			{
				[format ["The '%1' parameter value must be of the format direction,sweep", _parameterName]] call SPM_Util_MessageCaller;
			}
			else
			{
				private _direction = nil;

				private _valueArray = toArray (_pieces select 0);
				if (_valueArray select 0 >= 48 && _valueArray select 0 <= 57) then
				{
					_direction = parseNumber (_pieces select 0);
					if (_direction < 0 || _direction > 360) then { _direction = nil };
				}
				else
				{
					_direction = [OP_COMMAND_Directions, _pieces select 0] call BIS_fnc_getFromPairs;
					if (isNil "_direction") then
					{
						_direction = [OP_COMMAND_Locations, _pieces select 0] call BIS_fnc_getFromPairs;
					};
				};

				if (isNil "_direction") then { [format ["The '%1' parameter value's direction must be a numeric compass heading, the name of a compass direction or the full name of a village or city", _parameterName]] call SPM_Util_MessageCaller };

				private _sweep = nil;

				private _valueArray = toArray (_pieces select 1);
				if (_valueArray select 0 >= 48 && _valueArray select 0 <= 57) then
				{
					_sweep = parseNumber (_pieces select 1);
					if (_sweep < 1 || _sweep > 360) then { _sweep = nil };
				};

				if (isNil "_sweep") then { [format ["The '%1' parameter value's sweep must be a number between 1 and 360", _parameterName]] call SPM_Util_MessageCaller };

				if (not isNil "_direction" && not isNil "_sweep") then { _result = [0, _parameterName, [_direction, _sweep]] };
			};

			_result
		};
		case "#AREA":
		{
			private _result = [-1, _parameterName];

			private _pieces = _value splitString ",";
			if (count _pieces != 3) then
			{
				[format ["The '%1' parameter value must be of the format x,y,radius", _parameterName]] call SPM_Util_MessageCaller;
			}
			else
			{
				private _values = _pieces apply
				{
					private _valueArray = toArray _x;
					if (_valueArray select 0 >= 48 && _valueArray select 0 <= 57) then { parseNumber _x } else { nil };
				};

				if ({ isNil "_x" } count _pieces > 0) then
				{
					[format ["The '%1' parameter must contain only numbers", _parameterName]] call SPM_Util_MessageCaller
				}
				else
				{
					_result = [0, _parameterName, _values];
				};
			};

			_result
		};
	};
};

OO_TRACE_DECL(OP_COMMAND_ParseParameters) =
{
	params ["_commandWords", "_usage"];

	private _parameters = [];

	// Find parameters specified in the command but not part of the command's usage
	{
		private _word = _x;
		if ({ _x select 0 find _word == 0 } count (_usage select 1) == 0) then
		{
			[format ["'%1' is an unknown parameter name", _word]] call SPM_Util_MessageCaller;
			_parameters = [[-1]];
		};
	} forEach (_commandWords select { _x find "-" == 0 });

	// Find the usage-defined parameters
	_parameters append ((_usage select 1) apply { ([_commandWords] + _x) call OP_COMMAND_ParseParameter });

	_parameters
};

OO_TRACE_DECL(OP_COMMAND_GetParsedParameter) =
{
	params ["_parameters", "_name"];

	private _match = [];
	{
		if (_x select 1 == _name) exitWith { _match = _x };
	} forEach _parameters;

	_match
};

OO_TRACE_DECL(OP_COMMAND_UsageDescription) =
{
	params ["_usage"];

	private _description = (_usage select 0);
	private _parameters = (_usage select 1) apply
	{
		private _parameter = _x select 0;
		if (_x select 3 != "") then
		{
			private _value = _x select 3;
			if (not isNil { _x select 4 }) then
			{
				switch (_x select 3) do
				{
					case "STRING": { _value = (_x select 4) joinString "|" };
					case "SCALAR": { _value = (_x select 4) apply { str _x } joinString ".." };
				};
			};
			if (_x select 2) then { _parameter = _parameter + " [" + _value + "]" } else { _parameter = _parameter + " " + _value };
		};
		if (_x select 1) then { _parameter = "[" + _parameter + "]" };
		_parameter
	};

	_description + " " + (_parameters joinString " ");
};

OO_TRACE_DECL(OP_COMMAND_Execute) =
{
	params ["_commandString"];

	private _commandWords = [_commandString] call OP_COMMAND_GetWords;

	private _commands =
	[
		["advance", OP_COMMAND__Advance],
		["operation", OP_COMMAND__Operation],
		["specops", OP_COMMAND__SpecialOperations]
	];

	private _match = [_commandWords select 0, _commands] call OP_COMMAND_Match;

	if (_match select 0 < 0) exitWith { _match };

	private _command = _match select 1;

	[_commandWords select [1, 1e3]] call (_command select 1);
};