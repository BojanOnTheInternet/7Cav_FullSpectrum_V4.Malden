/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

#define SPAWN_CONFLICT_RANGE 20
#define NO_SCRIPT 0

SPM_SpawnManager_CS = call JB_fnc_criticalSectionCreate;
SPM_SpawnManager_AllocatedPositions = [];

SPM_SpawnManager_AllocatePosition =
{
	params ["_position", "_radius"];

	private _index = -1;

	SPM_SpawnManager_CS call JB_fnc_criticalSectionEnter;

		{ if (count _x > 0 && { (_x select 0) distance _position < (_x select 1) + _radius }) exitWith { _index = _forEachIndex } } forEach SPM_SpawnManager_AllocatedPositions;
		if (_index != -1) then { _index = -1 } else { _index = count SPM_SpawnManager_AllocatedPositions; SPM_SpawnManager_AllocatedPositions pushBack [_position, _radius] };

	SPM_SpawnManager_CS call JB_fnc_criticalSectionLeave;

	_index
};

SPM_SpawnManager_FreePosition =
{
	params ["_index"];

	SPM_SpawnManager_CS call JB_fnc_criticalSectionEnter;

		SPM_SpawnManager_AllocatedPositions set [_index, []];
		while { count SPM_SpawnManager_AllocatedPositions > 0 && { count (SPM_SpawnManager_AllocatedPositions select (count SPM_SpawnManager_AllocatedPositions - 1)) == 0 } } do { SPM_SpawnManager_AllocatedPositions deleteAt (count SPM_SpawnManager_AllocatedPositions - 1) };

	SPM_SpawnManager_CS call JB_fnc_criticalSectionLeave;
};

SPM_SpawnManager_Update =
{
	params ["_manager"];

	private _requests = OO_GET(_manager,SpawnManager,Requests);

	private _index = 0;
	while { _index < count _requests } do
	{
		private _request = _requests select _index;
		private _script = _request select 0 select 0;

		if (_script isEqualType NO_SCRIPT) then
		{
			private _parameters = _request select 1;
			private _index = [_parameters select 0, SPAWN_CONFLICT_RANGE] call SPM_SpawnManager_AllocatePosition;
			if (_index != -1) then
			{
				_script = ([_parameters select 0, _parameters select 1] + (_parameters select 3)) spawn (_parameters select 2);
				_request set [0, [_script, _index]];
			};
		}
		else
		{
			if (scriptDone _script) then
			{
				[_request select 0 select 1] call SPM_SpawnManager_FreePosition;
				_requests deleteAt _index;
				_index = _index - 1;
			};
		};

		_index = _index + 1;
	};
};

SPM_SpawnManager_ScheduleSpawn =
{
	params ["_manager", "_position", "_direction", "_code", "_parameters"];

	OO_GET(_manager,SpawnManager,Requests) pushBack [[NO_SCRIPT, -1], [_position, _direction, _code, _parameters]];
};

SPM_SpawnManager_Delete =
{
	params ["_manager"];

	private _requests = OO_GET(_manager,SpawnManager,Requests);

	{
		private _index = _x select 0 select 1;
		if (_index != -1) then { [_index] call SPM_SpawnManager_FreePosition };
		private _script = _x select 0 select 0;
		if (not (_script isEqualType NO_SCRIPT)) then { terminate _script };
	} forEach _requests;

	OO_SET(_manager,SpawnManager,Requests,[]);
};

OO_BEGIN_CLASS(SpawnManager);
	OO_OVERRIDE_METHOD(SpawnManager,Root,Delete,SPM_SpawnManager_Delete);
	OO_DEFINE_METHOD(SpawnManager,Update,SPM_SpawnManager_Update);
	OO_DEFINE_METHOD(SpawnManager,ScheduleSpawn,SPM_SpawnManager_ScheduleSpawn);
	OO_DEFINE_PROPERTY(SpawnManager,Requests,"ARRAY",[]); // [request, active-script]
OO_END_CLASS(SpawnManager);