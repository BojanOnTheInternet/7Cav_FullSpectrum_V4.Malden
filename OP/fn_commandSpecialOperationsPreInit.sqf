/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "..\SPM\strongpoint.h"
#include "op.h"

OO_TRACE_DECL(OP_COMMAND__SpecialOperationsStop) =
{
	params ["_commandWords"];

	if (count _commandWords > 0) exitWith { ["Unexpected: '%1'", _commandWords select 0] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _commandState = OO_GET(SERVER_SpecialOperationsCommand,SpecialOperationsCommand,CommandState);

	switch (_commandState) do
	{
		case "waiting": { ["No special operations mission sequence is running"] call SPM_Util_MessageCaller; };
		case "requested":
		{
			["Stopping special operations mission sequence"] call SPM_Util_MessageCaller;
			OO_SET(SERVER_SpecialOperationsCommand,SpecialOperationsCommand,CommandState,"stopping");
		};
		case "running":
		{
			["Stopping special operations mission sequence"] call SPM_Util_MessageCaller;
			OO_SET(SERVER_SpecialOperationsCommand,SpecialOperationsCommand,CommandState,"stopping");

			private _mission = OO_GET(SERVER_SpecialOperationsCommand,SpecialOperationsCommand,RunningMission);
			if (not OO_ISNULL(_mission)) then
			{
				OO_SET(_mission,Mission,MissionState,"command-terminated");
			};
		};
		case "stopping": { ["Special operations mission sequence is being stopped"] call SPM_Util_MessageCaller; };
	};

	[OP_COMMAND_RESULT_MATCHED]
};

OO_TRACE_DECL(OP_COMMAND__SpecialOperations) =
{
	params ["_commandWords"];

	private _commands =
	[
		["stop", OP_COMMAND__SpecialOperationsStop]
	];

	private _match = [_commandWords select 0, _commands] call OP_COMMAND_Match;

	if (_match select 0 < 0) exitWith { _match };

	private _command = _match select 1;

	[_commandWords select [1, 1e3]] call (_command select 1);
};

