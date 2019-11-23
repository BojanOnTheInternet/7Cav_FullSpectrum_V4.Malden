/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#include "..\SPM\strongpoint.h"
#include "op.h"

#define IDC_OK 1
#define IDC_CANCEL 2

#define COMMAND_DIALOG 3200
#define COMMAND_CONTROL 1200
#define OUTPUT_CONTROL 1300
#define EXECUTE_CONTROL 1700
#define SERVER_HOST_CONTROL 1400

#define SERVER_COLOR [1.0, 1.0, 1.0, 1.0];

#define HOST_SELECTED_ALPHA 1.0
#define HOST_NOTSELECTED_ALPHA 0.5

OP_Comand_AdjustControl =
{
	params ["_controlID", "_adjustment"];

	private _position = ctrlPosition (findDisplay COMMAND_DIALOG displayCtrl _controlID);
	{ _position set [_forEachIndex, (_position select _forEachIndex) + _x] } forEach _adjustment;
	(findDisplay COMMAND_DIALOG displayCtrl _controlID) ctrlSetPosition _position;
	(findDisplay COMMAND_DIALOG displayCtrl _controlID) ctrlCommit 0;
};

OP_Command_UpdateSelectedHost =
{
	private _headlessClients = (allPlayers select { _x isKindOf "HeadlessClient_F"});

	private _color = SERVER_COLOR;
	if (isNull OP_SelectedHost) then { _color set [3, HOST_SELECTED_ALPHA] } else { _color set [3, HOST_NOTSELECTED_ALPHA] };
	(findDisplay COMMAND_DIALOG displayCtrl SERVER_HOST_CONTROL) ctrlSetTextColor _color;

	{
		private _idc = SERVER_HOST_CONTROL + _forEachIndex + 1;

		_color = [_x] call OP_HostColor;
		_color = getArray (configFile >> "CfgMarkerColors" >> _color >> "color");
		if (OP_SelectedHost == _x) then { _color set [3, HOST_SELECTED_ALPHA] } else { _color set [3, HOST_NOTSELECTED_ALPHA] };
		(findDisplay COMMAND_DIALOG displayCtrl _idc) ctrlSetTextColor _color;
	} forEach _headlessClients;
};

OP_Command_SelectHost =
{
	params ["_control"];

	private _host = (ctrlIDC _control) - SERVER_HOST_CONTROL - 1;

	OP_SelectedHost = if (_host == -1) then { objNull } else { (allPlayers select { _x isKindOf "HeadlessClient_F"}) select _host };

	[] call OP_Command_UpdateSelectedHost;
};

OO_TRACE_DECL(OP_Command_ShowDialog) =
{
	createDialog "OP_Command";
	waitUntil { dialog };

	ctrlSetText [COMMAND_CONTROL, profileNamespace getVariable ["OP_CommandContents", ""]];

	private _headlessClients = (allPlayers select { _x isKindOf "HeadlessClient_F"});
	if (count _headlessClients > 0) then
	{
		[COMMAND_CONTROL, [0, 0, 0, -0.05]] call OP_Comand_AdjustControl;
		
		(findDisplay COMMAND_DIALOG) ctrlCreate ["iHostButton", SERVER_HOST_CONTROL];
		private _position = ctrlPosition (findDisplay COMMAND_DIALOG displayCtrl SERVER_HOST_CONTROL);

		{
			private _idc = SERVER_HOST_CONTROL + _forEachIndex + 1;
			(findDisplay COMMAND_DIALOG) ctrlCreate ["iHostButton", _idc];
			[_idc, [((_position select 2) + 0.005) * (_forEachIndex + 1), 0, 0, 0]] call OP_Comand_AdjustControl;
			(findDisplay COMMAND_DIALOG displayCtrl _idc) ctrlSetText vehicleVarName _x;
		} forEach _headlessClients;

		[] call OP_Command_UpdateSelectedHost;
	};

	[OP_Command_AppendOutputMessage] call SPM_Util_PushMessageReceiver;
};

#define PREFIX "mc operation "

OO_TRACE_DECL(OP_Command_AppendOutputMessage) =
{
	params ["_message"];

	if (isNull findDisplay COMMAND_DIALOG) exitWith { false };

	ctrlSetText [OUTPUT_CONTROL, (ctrlText OUTPUT_CONTROL) + (toString [10]) + _message];

	true
};

OO_TRACE_DECL(OP_Command_ExecuteAction) =
{
	[] spawn
	{
		ctrlEnable [COMMAND_CONTROL, false];

		private _operation = player getVariable ["OP_Selection", OP_SELECTION_NULL];
		private _host = _operation select 4;
		if (isNil "_host") then { _host = OP_SelectedHost };
		if (_host isEqualType objNull && { isNull _host }) then { _host = 2 };

		private _lines = (ctrlText COMMAND_CONTROL) splitString toString [10];

		{
			private _command = _x;

			[_command] call OP_Command_AppendOutputMessage;

			// Remove comment
			private _commentIndex = _command find "//";
			if (_commentIndex >= 0) then { _command = _command select [0, _commentIndex] };

			if (count (_command splitString " ") > 0) then // Ignore empty lines
			{
				OP_Command_ExecutionPending = true;
				[PREFIX + _command] remoteExec ["OP_S_Command_ExecuteCommand", _host];
				[{ not OP_Command_ExecutionPending }, 5] call JB_fnc_timeoutWaitUntil;
			};
		} forEach _lines;

		ctrlEnable [COMMAND_CONTROL, true];
	};
};

OP_Command_Unload =
{
	[] call SPM_Util_PopMessageReceiver;
	profileNamespace setVariable ["OP_CommandContents", ctrlText COMMAND_CONTROL];
	saveProfileNamespace;
};

OP_Command_DoneAction =
{
	closeDialog IDC_OK;
};

OO_TRACE_DECL(OP_C_Command_ExecutionCompleted) =
{
	OP_Command_ExecutionPending = false;

	"" // OO_TRACE_DECL insists on a return value
};

if (not isServer && hasInterface) exitWith {};

OO_TRACE_DECL(OP_S_Command_ExecuteCommand) =
{
	params ["_command"];

	[_command] call SERVER_ExecuteCommand;

	[] remoteExec ["OP_C_Command_ExecutionCompleted", remoteExecutedOwner];
};