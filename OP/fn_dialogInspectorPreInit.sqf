/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#include "..\SPM\strongpoint.h"

#define IDC_OK 1
#define IDC_CANCEL 2

#define INSPECTOR_DIALOG 3100
#define STRONGPOINTS_CONTROL 1200
#define DETAILS_CONTROL 1500
#define PAUSERESUME_CONTROL 1700

#define SPECIAL_OPERATIONS_COMMAND "Special Operations Command"

OO_TRACE_DECL(OP_Inspector_ShowDialog) =
{
	createDialog "OP_Inspector";
	waitUntil { dialog };

	lbClear STRONGPOINTS_CONTROL;
	lbClear DETAILS_CONTROL;

	OP_Inspector_Paused = false;
	ctrlSetText [PAUSERESUME_CONTROL, "PAUSE"];

	[] spawn
	{
		scriptName "OP_Inspector_ShowDialog";

		while { dialog } do
		{
			if (not OP_Inspector_Paused) then
			{
				private _selectedIndex = lbCurSel STRONGPOINTS_CONTROL;
				private _selectedStrongpoint = ((findDisplay INSPECTOR_DIALOG) displayCtrl STRONGPOINTS_CONTROL) lnbText [_selectedIndex, 0];
				[_selectedStrongpoint] remoteExec ["OP_S_Inspector_DetailsRequest", 2];
			};
			sleep 2;
		};
	};
};

OO_TRACE_DECL(OP_Inspector_PauseResumeAction) =
{
	params ["_display"];

	OP_Inspector_Paused = not OP_Inspector_Paused;

	ctrlSetText [PAUSERESUME_CONTROL, if (OP_Inspector_Paused) then { "RESUME" } else { "PAUSE" }];
};

OO_TRACE_DECL(OP_Inspector_DoneAction) =
{
	params ["_display"];

	closeDialog IDC_OK;
};

OO_TRACE_DECL(OP_C_Inspector_DetailsResponse) =
{
	params ["_strongpointNames", "_strongpointDetails"];

	lbClear STRONGPOINTS_CONTROL;
	{
		lnbAddRow [STRONGPOINTS_CONTROL, [_x]];
	} forEach _strongpointNames;

	lbClear DETAILS_CONTROL;
	{
		{
			lnbAddRow [DETAILS_CONTROL, _x];
		} forEach _x;
		lnbAddRow [DETAILS_CONTROL, [""]];
	} forEach _strongpointDetails;
};

if (not isServer && hasInterface) exitWith {};

OO_TRACE_DECL(OP_S_Inspector_DetailsRequest) =
{
	params ["_strongpointName"];

	private _strongpointNames = [];
	private _strongpoint = [];

	private _parameters = [_strongpointNames, _strongpointName, _strongpoint];
	private _code =
		{
			params ["_strongpointNames", "_strongpointName", "_strongpoint"];
			private _name = OO_GET(_x,Strongpoint,Name);
			_strongpointNames pushBack _name;
			if (_name == _strongpointName) then { _strongpoint set [0, _x] };
			false
		};
	OO_FOREACHINSTANCE(Strongpoint,_parameters,_code);

	private _strongpointDetails = [];
	if (count _strongpoint > 0) then
	{
		_strongpoint = _strongpoint select 0;

		_strongpointDetails pushBack ([_strongpoint] call OO_GetNamedProperties);

		{
			_strongpointDetails pushBack ([_x] call OO_GetNamedProperties);
		} forEach OO_GET(_strongpoint,Strongpoint,Categories);
	};

	if (SpecialOperations_RunState == "run") then
	{
		// Add Special Operations Command as a choice
		_strongpointNames pushBack SPECIAL_OPERATIONS_COMMAND;
		if (_strongpointName == SPECIAL_OPERATIONS_COMMAND) then
		{
			_strongpointDetails pushBack ([SERVER_SpecialOperationsCommand] call OO_GetNamedProperties)
		};
	};

	[_strongpointNames, _strongpointDetails] remoteExec ["OP_C_Inspector_DetailsResponse", remoteExecutedOwner];
};

