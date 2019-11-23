/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#include "strongpoint.h"

// A task ID is an array of values. The values can be alphanumerics and/or whole numbers.  No underscores.

SPM_Task_C_Tasks = []; // [[task-name, task], ...]

OO_TRACE_DECL(SPM_Task_IDtoName) =
{
	if (count (_this select 0) == 0) exitWith { "" };

	format ["SPM_Task_T_%1_%2", remoteExecutedOwner, (_this select 0) apply { str _x } joinString "_"];
};

SPM_Task_NameToTask =
{
	private _index = SPM_Task_C_Tasks findIf { _x select 0 == (_this select 0) };
	if (_index == -1) exitWith { taskNull };

	SPM_Task_C_Tasks select _index select 1
};

SPM_Task_IDtoTask =
{
	[[_this select 0] call SPM_Task_IDtoName] call SPM_Task_NameToTask;
};

SPM_Task_C_Create_Pending = [];

OO_TRACE_DECL(SPM_Task_C_Create) =
{
	params ["_filter", "_taskID", "_parentID", "_position", "_description", "_type", "_visible"];

	// Discard any calls not intended for the local player
	if (not isNil "_filter" && { not ([player] call _filter) }) exitWith {};

	private _parentName = [_parentID] call SPM_Task_IDtoName;
	private _parentTask = [_parentName] call SPM_Task_NameToTask;

	// JIPs playback in reverse order, so if the parent doesn't exist yet, cache the create request
	if (count _parentID > 0 && isNull _parentTask) exitWith
	{
		SPM_Task_C_Create_Pending pushBack _this;
	};

	private _name = [_taskID] call SPM_Task_IDtoName;
	private _task = player createSimpleTask [_name, _parentTask];
	SPM_Task_C_Tasks pushBack [_name, _task];

	if (count _position > 0) then { _task setSimpleTaskDestination _position };
	_task setSimpleTaskDescription _description;
	_task setSimpleTaskAlwaysVisible _visible;
	_task setSimpleTaskType _type;

	// Find pending create requests that reference us as a parent (pending select 2) and run them
	private _pending = [];
	for "_i" from (count SPM_Task_C_Create_Pending - 1) to 0 step -1 do
	{
		if (SPM_Task_C_Create_Pending select _i select 2 isEqualTo _taskID) then { _pending pushBack (SPM_Task_C_Create_Pending deleteAt _i) };
	};
	{
		_x call SPM_Task_C_Create;
	} forEach _pending;

	// Find pending setState requests for us (pending select 1) and run them
	private _pending = [];
	for "_i" from (count SPM_Task_C_SetState_Pending - 1) to 0 step -1 do
	{
		if (SPM_Task_C_SetState_Pending select _i select 1 isEqualTo _taskID) then { _pending pushBack (SPM_Task_C_SetState_Pending deleteAt _i) };
	};
	{
		_x call SPM_Task_C_SetState;
	} forEach _pending;

};

OO_TRACE_DECL(SPM_Task_C_DeleteTaskTree) =
{
	params ["_task"];

	{
		[_x] call SPM_Task_C_DeleteTaskTree;
	} forEach taskChildren _task;

	private _index = SPM_Task_C_Tasks findIf { _x select 1 == _task };
	if (_index != -1) then { SPM_Task_C_Tasks deleteAt _index };

	player removeSimpleTask _task;
};

OO_TRACE_DECL(SPM_Task_C_Delete) =
{
	params ["_filter", "_taskID"];

	// Discard any calls not intended for the local player
	if (not isNil "_filter" && { not ([player] call _filter) }) exitWith {};

	private _name = [_taskID] call SPM_Task_IDtoName;
	private _task = [_name] call SPM_Task_NameToTask;

	if (isNull _task) exitWith {};

	[_task] call SPM_Task_C_DeleteTaskTree;
};

SPM_Task_C_SetState_Pending = [];

OO_TRACE_DECL(SPM_Task_C_SetState) =
{
	params ["_filter", "_taskID", "_state"];

	// Discard any calls not intended for the local player
	if (not isNil "_filter" && { not ([player] call _filter) }) exitWith {};

	private _task = [_taskID] call SPM_Task_IDtoTask;

	if (isNull _task) exitWith { SPM_Task_C_SetState_Pending pushBack _this };

	_task setTaskState _state;
};

// SPM_Task_S_Entries stores JIP IDs for remoteExecs that we sent out to create and update tasks.  When a task is deleted, we clean up the JIPs by using this information.

SPM_Task_S_Entries = []; // [[task-name, [jipid, ...], [child-name, ...]], ...]

OO_TRACE_DECL(SPM_Task_Create) =
{
	params ["_recipients", "_taskID", "_parentID", "_position", "_description", "_type", "_visible"];

	private _jipID = "";

	if (_recipients isEqualType {}) then
	{
		_jipID = [_recipients, _taskID, _parentID, _position, _description, _type, _visible] remoteExec ["SPM_Task_C_Create", 0, true]; //JIP
	}
	else
	{
		_jipID = [nil, _taskID, _parentID, _position, _description, _type, _visible] remoteExec ["SPM_Task_C_Create", _recipients, true]; //JIP
	};

	if (_jipID != "") then
	{
		private _name = [_taskID] call SPM_Task_IDtoName;
		private _parentName = [_parentID] call SPM_Task_IDtoName;
		SPM_Task_S_Entries pushBack [_name, [_jipID], _parentName];
	};
};

OO_TRACE_DECL(SPM_Task_S_DeleteEntryTree) =
{
	params ["_entry"];

	{ remoteExec ["", _x] } forEach (_entry select 1);

	for "_i" from (count SPM_Task_S_Entries - 1) to 0 step -1 do
	{
		if (SPM_Task_S_Entries select _i select 2 == _name) then { [SPM_Task_S_Entries deleteAt _i] call SPM_Task_S_DeleteEntryTree; _i = _i min count SPM_Task_S_Entries };
	};
};

OO_TRACE_DECL(SPM_Task_Delete) =
{
	params ["_recipients", "_taskID"];

	if (_recipients isEqualType {}) then
	{
		[_recipients, _taskID] remoteExec ["SPM_Task_C_Delete", 0];
	}
	else
	{
		[nil, _taskID] remoteExec ["SPM_Task_C_Delete", _recipients];
	};

	private _name = [_taskID] call SPM_Task_IDtoName;
	private _index = SPM_Task_S_Entries findIf { _x select 0 == _name };
	if (_index >= 0) then { [SPM_Task_S_Entries deleteAt _index] call SPM_Task_S_DeleteEntryTree };
};

OO_TRACE_DECL(SPM_Task_SetState) =
{
	params ["_recipients", "_taskID", "_state"];

	private _jipID = "";

	if (_recipients isEqualType {}) then
	{
		_jipID = [_recipients, _taskID, _state] remoteExec ["SPM_Task_C_SetState", 0, true]; //JIP
	}
	else
	{
		_jipID = [nil, _taskID, _state] remoteExec ["SPM_Task_C_SetState", _recipients, true]; //JIP
	};

	if (_jipID != "") then
	{
		private _name = [_taskID] call SPM_Task_IDtoName;
		private _index = SPM_Task_S_Entries findIf { _x select 0 == _name };
		if (_index >= 0) then { SPM_Task_S_Entries select _index select 1 pushBack _jipID };
	};
};
