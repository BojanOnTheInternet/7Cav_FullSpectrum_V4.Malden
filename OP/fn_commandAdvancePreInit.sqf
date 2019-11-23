/*
Copyright (c) 2017-2019, John Buehler

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

	switch (["Advance"] call JB_MP_GetParamValueText) do
	{
		case "Started":
		{
			["Stopping running advance"] call SPM_Util_MessageCaller; ["Advance", "Stopped"] call JB_MP_S_SetParameter;
		};
		case "Suspended":
		{
			["Stopping suspended advance"] call SPM_Util_MessageCaller; ["Advance", "Stopped"] call JB_MP_S_SetParameter;
		};
		case "Stopped": { ["Advance is already stopped"] call SPM_Util_MessageCaller };
	};

	[OP_COMMAND_RESULT_MATCHED]
};

OO_TRACE_DECL(OP_COMMAND__AdvanceStart) =
{
	params ["_commandWords"];

	if (count _commandWords > 0) exitWith { ["Unexpected: '%1'", _commandWords select 0] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	switch (["Advance"] call JB_MP_GetParamValueText) do
	{
		case "Started": { ["Advance is already running"] call SPM_Util_MessageCaller };
		case "Suspended": { ["Resuming advance"] call SPM_Util_MessageCaller; ["Advance", "Started"] call JB_MP_S_SetParameter };
		case "Stopped": { ["Starting advance"] call SPM_Util_MessageCaller; ["Advance", "Started"] call JB_MP_S_SetParameter };
	};

	[OP_COMMAND_RESULT_MATCHED]
};

OO_TRACE_DECL(OP_COMMAND__AdvanceSuspend) =
{
	params ["_commandWords"];

	if (count _commandWords > 0) exitWith { ["Unexpected: '%1'", _commandWords select 0] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	switch (["Advance"] call JB_MP_GetParamValueText) do
	{
		case "Started":
		{
			["Suspending advance"] call SPM_Util_MessageCaller; ["Advance", "Suspended"] call JB_MP_S_SetParameter;
		};
		case "Suspended": { ["Advance is already suspended"] call SPM_Util_MessageCaller };
		case "Stopped": { ["Advance is stopped"] call SPM_Util_MessageCaller };
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

