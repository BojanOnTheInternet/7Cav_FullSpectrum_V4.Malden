/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#include "strongpoint.h"

OO_TRACE_DECL(SPM_Mission_Message) =
{
	params ["_message", "_media", ["_recipient", {true}, [objNull, {}]]];

	if (_recipient isEqualType {}) then
	{
		[_message, _media, _recipient] remoteExec ["SPM_Mission_C_Message", 0];
	}
	else
	{
		if (local _recipient) then
		{
			[_message, _media] call SPM_Mission_C_Message;
		}
		else
		{
			[_message, _media] remoteExec ["SPM_Mission_C_Message", _recipient];
		};
	};
};

SPM_Mission_SpecOpsMembers =
{
	allPlayers select { [_x] call BOTH_IsSpecOpsMember }
};

if (not hasInterface) exitWith {};

SPM_Mission_MessageFormat = "<t align = 'left' shadow = '1' size = '0.4' font='EtelkaMonospacePro'>%1</t><br/>";

SPM_Mission_MessageStart =
[
	["### SPECIAL OPERATIONS ###", SPM_Mission_MessageFormat],
	["###   MESSAGE BEGINS   ###", SPM_Mission_MessageFormat],
	["", "<br/>"],
	["", "<br/>"],
	[">", SPM_Mission_MessageFormat]
];

SPM_Mission_MessageEnd =
[
	[">", SPM_Mission_MessageFormat],
	["###    MESSAGE ENDS    ###", SPM_Mission_MessageFormat],
	["", "<br/>"],
	["", "<br/>"],
	["", "<br/>"]
];

SPM_Mission_Message_CS = call JB_fnc_criticalSectionCreate;
SPM_Mission_MessageScript = scriptNull;
SPM_Mission_MessageQueue = [];

OO_TRACE_DECL(SPM_Mission_EnterMessageIntoLog) =
{
	params ["_message", "_log"];

	// Trim trailing blank lines
	_message = +_message;
	for "_i" from (count _message - 1) to 0 step -1 do
	{
		if (count (_message select _i) > 0) exitWith {};
		_message deleteAt _i;
	};

	if (not (player diarySubjectExists (_log select 0))) then { player createDiarySubject [_log select 0, _log select 0] };

	private _logEntry = format ["<font face='EtelkaMonospacePro' size=10>%1</font>", _message joinString "<br/>"];
	player createDiaryRecord [_log select 0, [_log select 1, _logEntry]];
};

// Clone of BIS_fnc_typeText
OO_TRACE_DECL(SPM_Mission_MessageShowScreen) =
{
#define DELAY_CHARACTER	0.02;
#define DELAY_CURSOR	0.04;

	private ["_data","_posX","_posY","_rootFormat","_toDisplay"];
	private ["_blocks","_block","_blockText","_blockTextF","_blockTextF_","_blockFormat","_formats","_processedTextF","_cursorInvis","_blinkCounts","_blinkCount"];

	_data = _this param [0, [], [[]]];
	_posX = _this param [1, 0, [0]];
	_posY = _this param [2, 0, [0]];
	_rootFormat = _this param [3, "<t >%1</t>", [""]];

	_invisCursor = "<t color ='#00000000' shadow = '0'>_</t>";

	//process the input data
	_blocks = [];
	_formats = [];
	_blinkCounts = [];

	{
		_block = _x param [0, "", [""]];
		_format = _x param [1, "<t align = 'center' shadow = '1' size = '0.7'>%1</t><br/>", [""]];
		_blinkCount = _x param [2, 5, [0]];

		_blocks pushBack (_block splitString "");
		_formats pushBack _format;
		_blinkCounts pushBack _blinkCount;
	}
	forEach _data;

	//do the printing
	_processedTextF  = "";

	{
		_blockArray = _x;
		_blockFormat = _formats select _forEachIndex;
		_blockText = "";
		_blockTextF = "";
		_blockTextF_ = "";

		{
			_blockText = _blockText + _x;

			_blockTextF  = format [_blockFormat, _blockText + _invisCursor];
			_blockTextF_ = format [_blockFormat, _blockText + "_"];

			//print the output
			_toDisplay = format [_rootFormat, _processedTextF + _blockTextF_];
			[_toDisplay, _posX, _posY, 5, 0, 0, 90] spawn BIS_fnc_dynamicText;
			playSound "ReadoutClick";
			sleep DELAY_CHARACTER;

			_toDisplay = format [_rootFormat, _processedTextF + _blockTextF];
			[_toDisplay, _posX, _posY, 5, 0, 0, 90] spawn BIS_fnc_dynamicText;
			sleep DELAY_CURSOR;
		}
		forEach _blockArray;

		_blinkCount = _blinkCounts select _forEachIndex;

		if (_blinkCount > 0) then
		{
			for "_i" from 1 to _blinkCount do
			{
				_toDisplay = format [_rootFormat, _processedTextF + _blockTextF_];
				[_toDisplay, _posX, _posY, 5, 0, 0, 90] spawn BIS_fnc_dynamicText;
				sleep DELAY_CHARACTER;

				_toDisplay = format [_rootFormat, _processedTextF + _blockTextF];
				[_toDisplay, _posX, _posY, 5, 0, 0, 90] spawn BIS_fnc_dynamicText;
				sleep DELAY_CURSOR;
			};
		};

		//store finished block
		_processedTextF  = _processedTextF + _blockTextF;
	} forEach _blocks;

	//clean the screen
	["", _posX, _posY, 5, 0, 0, 90] spawn BIS_fnc_dynamicText;
};

OO_TRACE_DECL(SPM_Mission_MessageWrap) =
{
	params ["_message", "_lineLength"];

	private _wrappedMessage = [];
	{
		if (count _x <= _lineLength) then
		{
			_wrappedMessage pushBack _x;
		}
		else
		{
			private _line = "";

			{
				switch (true) do
				{
					case (count _line == 0): { _line = _x };
					case ((count _line + count _x) <= _lineLength): { _line = _line + " " + _x };
					default
					{
						_wrappedMessage pushBack _line;
						_line = "    " + _x;
					};
				};
			} forEach (_x splitString " ");

			_wrappedMessage pushBack _line;
		};
	} forEach _message;

	_wrappedMessage
};

OO_TRACE_DECL(SPM_Mission_MessageShow) =
{
	private _script = scriptNull;

	waitUntil { sleep 0.2; not isNull findDisplay 46 };

	sleep 5;

	while { true } do
	{
		waitUntil { sleep 0.2; count SPM_Mission_MessageQueue > 0 && scriptDone _script };
		_script = scriptNull;

		SPM_Mission_Message_CS call JB_fnc_criticalSectionEnter;
		(SPM_Mission_MessageQueue deleteAt 0) params ["_message", "_media"];
		SPM_Mission_Message_CS call JB_fnc_criticalSectionLeave;

		if ("log" in _media) then
		{
			[_message, ["Log", "Notification"]] call SPM_Mission_EnterMessageIntoLog;
		};

		if ("log-specops" in _media) then
		{
			[_message, ["Special Operations", "Log"]] call SPM_Mission_EnterMessageIntoLog;
		};

		if ("printout" in _media) then
		{
			private _messageWrapped = [_message, 45] call SPM_Mission_MessageWrap;
			private _transmission = _messageWrapped apply { ["> " + _x, SPM_Mission_MessageFormat] };
			_script = [_transmission, 0.8, 0.8] spawn SPM_Mission_MessageShowScreen;
		};

		if ("printout-specops" in _media) then
		{
			private _messageWrapped = [_message, 45] call SPM_Mission_MessageWrap;
			private _transmission = SPM_Mission_MessageStart + (_messageWrapped apply { ["> " + _x, SPM_Mission_MessageFormat] }) + SPM_Mission_MessageEnd;
			_script = [_transmission, 0.8, 0.8] spawn SPM_Mission_MessageShowScreen;
		};

		if ("chat" in _media) then
		{
			{
				systemchat _x;
			} forEach _message;
		};

		if ("title" in _media) then
		{
			if (typeName _message == "ARRAY") then {
				titleText [_message joinString "\n", "plain down", 0.5];
			}
			else {
				titleText [_message, "plain down", 0.5];
			};
			
		};

		if ("notification" in _media) then
		{
			[_message select 0, _message select [1, 1e3]] call BIS_fnc_showNotification;
		};
	};
};

OO_TRACE_DECL(SPM_Mission_C_Message) =
{
	params ["_message", "_media", "_filter"];

	// Discard any messages not intended for the local player
	if (not isNil "_filter" && { not ([player] call _filter) }) exitWith {};

	SPM_Mission_Message_CS call JB_fnc_criticalSectionEnter;
	if (isNull SPM_Mission_MessageScript) then { SPM_Mission_MessageScript = [] spawn SPM_Mission_MessageShow };
	SPM_Mission_MessageQueue pushBack [_message, _media];
	SPM_Mission_Message_CS call JB_fnc_criticalSectionLeave;
};
