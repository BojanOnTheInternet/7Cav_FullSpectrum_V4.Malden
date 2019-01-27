/*
Copyright (c) 2017, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "..\SPM\strongpoint.h"
#include "op.h"

OO_TRACE_DECL(OP_COMMAND__AdvanceStop) =
{
	params ["_commandWords"];

	if (count _commandWords > 0) exitWith { ["Unexpected: '%1'", _commandWords select 0] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	switch (Advance_RunState) do
	{
		case "run":
		{
			["Stopping running advance"] call SPM_Util_MessageCaller; Advance_RunState = "stop";
			["NotificationEndAdvance", ["This operational advance has been stopped by command."]] remoteExec ["BIS_fnc_showNotification", 0];
		};
		case "suspend":
		{
			["Stopping suspended advance"] call SPM_Util_MessageCaller; Advance_RunState = "stop";
			["NotificationEndAdvance", ["This operational advance has been stopped by command."]] remoteExec ["BIS_fnc_showNotification", 0];
		};
		case "stop": { ["Advance is already stopped"] call SPM_Util_MessageCaller };
	};

	[OP_COMMAND_RESULT_MATCHED]
};

OO_TRACE_DECL(OP_COMMAND__AdvanceStart) =
{
	params ["_commandWords"];

	if (count _commandWords > 0) exitWith { ["Unexpected: '%1'", _commandWords select 0] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	switch (Advance_RunState) do
	{
		case "run": { ["Advance is already running"] call SPM_Util_MessageCaller };
		case "suspend": { ["Resuming advance"] call SPM_Util_MessageCaller; Advance_RunState = "run" };
		case "stop": { ["Starting advance"] call SPM_Util_MessageCaller; Advance_RunState = "run" };
	};

	[OP_COMMAND_RESULT_MATCHED]
};

OO_TRACE_DECL(OP_COMMAND__AdvanceSuspend) =
{
	params ["_commandWords"];

	if (count _commandWords > 0) exitWith { ["Unexpected: '%1'", _commandWords select 0] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	switch (Advance_RunState) do
	{
		case "run":
		{
			["Suspending advance"] call SPM_Util_MessageCaller; Advance_RunState = "suspend";
			["NotificationEndAdvance", ["This operational advance has been suspended by command."]] remoteExec ["BIS_fnc_showNotification", 0];
		};
		case "suspend": { ["Advance is already suspended"] call SPM_Util_MessageCaller };
		case "stop": { ["Advance is stopped"] call SPM_Util_MessageCaller };
	};

	[OP_COMMAND_RESULT_MATCHED]
};

OO_TRACE_DECL(OP_COMMAND__Advance) =
{
	params ["_commandWords"];

	private _commands =
	[
		["stop", OP_COMMAND__AdvanceStop],
		["start", OP_COMMAND__AdvanceStart],
		["suspend", OP_COMMAND__AdvanceSuspend]
	];

	private _match = [_commandWords select 0, _commands] call OP_COMMAND_Match;

	if (_match select 0 < 0) exitWith { _match };

	private _command = _match select 1;

	[_commandWords select [1, 1e3]] call (_command select 1);
};

