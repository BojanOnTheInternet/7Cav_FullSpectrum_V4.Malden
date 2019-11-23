/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "strongpoint.h"

SPM_StrongpointArea_Create =
{
	params ["_area", "_center", "_innerRadius", "_outerRadius"];

	OO_SET(_area,StrongpointArea,Position,_center);
	OO_SET(_area,StrongpointArea,InnerRadius,_innerRadius);
	OO_SET(_area,StrongpointArea,OuterRadius,_outerRadius);
};

SPM_StrongpointArea_GetNearestLocation =
{
	params ["_area"];

	private _nearestLocation = OO_GET(_area,StrongpointArea,NearestLocation);
	if (isNull _nearestLocation) then
	{
		private _center = OO_GET(_area,StrongpointArea,Position);

		private _locations = [];

		private _radius = 1000;
		while { count _locations == 0 } do
		{
			_locations = nearestLocations [_center, ["NameVillage", "NameCity", "NameCityCapital"], _radius, _center];
			_radius = _radius + 1000;
		};

		_nearestLocation = _locations select 0;

		OO_SET(_area,StrongpointArea,NearestLocation,_nearestLocation);
	};

	_nearestLocation;
};

SPM_StrongpointArea_PositionInArea =
{
	params ["_area", "_position"];

	private _distance = _position distance OO_GET(_area,StrongpointArea,Position);

	(_distance >= OO_GET(_area,StrongpointArea,InnerRadius) && _distance <= OO_GET(_area,StrongpointArea,OuterRadius))
};

OO_BEGIN_STRUCT(StrongpointArea);
	OO_OVERRIDE_METHOD(StrongpointArea,RootStruct,Create,SPM_StrongpointArea_Create);
	OO_DEFINE_METHOD(StrongpointArea,GetNearestLocation,SPM_StrongpointArea_GetNearestLocation);
	OO_DEFINE_METHOD(StrongpointArea,PositionInArea,SPM_StrongpointArea_PositionInArea);
	OO_DEFINE_PROPERTY(StrongpointArea,Position,"ARRAY",[]);
	OO_DEFINE_PROPERTY(StrongpointArea,InnerRadius,"SCALAR",0);
	OO_DEFINE_PROPERTY(StrongpointArea,OuterRadius,"SCALAR",0);
	OO_DEFINE_PROPERTY(StrongpointArea,NearestLocation,"LOCATION",locationNull);
OO_END_STRUCT(StrongpointArea);

SPM_Strongpoint_FindByName =
{
	params ["_name"];

	private _parameters = [_name];
	private _code =
		{
			params ["_name"];
			if (OO_GET(_x,Strongpoint,Name) == _name) exitWith { true };
			false;
		};
	private _strongpoint = OO_FOREACHINSTANCE(Strongpoint,_parameters,_code);

	_strongpoint
};

// The time that players have to populate the area before win/lose checks start
#define SPM_GRACE_PERIOD 120

SPM_Strongpoint_AddCategory =
{
	params ["_strongpoint", "_category"];

	OO_GET(_strongpoint,Strongpoint,Categories) pushBack _category;
	OO_SETREF(_category,Category,Strongpoint,_strongpoint);
};

SPM_Strongpoint_Run =
{
	params ["_strongpoint"];

	if (OO_GET(_strongpoint,Strongpoint,RunState) == "running") exitWith {};

	OO_SET(_strongpoint,Strongpoint,RunState,"running");
	OO_SET(_strongpoint,Strongpoint,RunStart,diag_tickTime);

	private _spawnManager = OO_GET(_strongpoint,Strongpoint,SpawnManager);

	while { OO_GET(_strongpoint,Strongpoint,RunState) == "running" } do
	{
		private _time = diag_tickTime;

		if (OO_GET(_strongpoint,Strongpoint,RunDuration) != -1 && { _time > (OO_GET(_strongpoint,Strongpoint,RunStart) + OO_GET(_strongpoint,Strongpoint,RunDuration)) }) then
		{
			OO_SET(_strongpoint,Strongpoint,RunState,"timeout");
		}
		else
		{
			if (_time > OO_GET(_strongpoint,Strongpoint,UpdateTime)) then
			{
				private _updateScript = [_strongpoint] spawn { params ["_strongpoint"]; scriptName "SPM_Strongpoint_Run_Strongpoint"; [] call OO_METHOD(_strongpoint,Strongpoint,Update) };
				waitUntil { sleep 0.1; scriptDone _updateScript };
			};

			{
				private _category = _x;

				if (OO_GET(_strongpoint,Strongpoint,RunState) == "running" && _time > OO_GET(_category,Category,UpdateTime)) then
				{
					_updateScript = [_category] spawn { params ["_category"]; scriptName "SPM_Strongpoint_Run_Category"; [] call OO_METHOD(_category,Category,Update) };
					waitUntil { sleep 0.1; scriptDone _updateScript };
				};
			} forEach OO_GET(_strongpoint,Strongpoint,Categories);

			if (OO_GET(_strongpoint,Strongpoint,RunState) == "running") then
			{
				_updateScript = [_spawnManager] spawn { params ["_spawnManager"]; scriptName "SPM_Strongpoint_Run_SpawnManager"; [] call OO_METHOD(_spawnManager,SpawnManager,Update) };
				waitUntil { sleep 0.1; scriptDone _updateScript };
			};
		};

		sleep 1;
	};

	if (OO_GET(_strongpoint,Strongpoint,RunState) == "stopping") then
	{
		OO_SET(_strongpoint,Strongpoint,RunState,"stopped");
	};
};

SPM_Strongpoint_Stop =
{
	params ["_strongpoint"];

	if (OO_GET(_strongpoint,Strongpoint,RunState) == "running") then
	{
		OO_SET(_strongpoint,Strongpoint,RunState,"stopping");
	};
};

SPM_Strongpoint_Create =
{
	params ["_strongpoint", "_center", "_controlRadius", "_activityRadius"];

	OO_SET(_strongpoint,Strongpoint,Position,_center);
	OO_SET(_strongpoint,Strongpoint,ControlRadius,_controlRadius);
	OO_SET(_strongpoint,Strongpoint,ActivityRadius,_activityRadius);

	private _spawnManager = [] call OO_CREATE(SpawnManager);
	OO_SET(_strongpoint,Strongpoint,SpawnManager,_spawnManager);
};

SPM_Strongpoint_Delete =
{
	params ["_strongpoint"];

	OO_SET(_strongpoint,Strongpoint,RunState,"deleted");

	private _categories = OO_GET(_strongpoint,Strongpoint,Categories);
	while { count _categories > 0 } do
	{
		private _category = _categories deleteAt (count _categories - 1);
		call OO_DELETE(_category);
	};

	private _spawnManager = OO_GET(_strongpoint,Strongpoint,SpawnManager);
	call OO_DELETE(_spawnManager);

	private _position = OO_GET(_strongpoint,Strongpoint,Position);
	private _controlRadius = OO_GET(_strongpoint,Strongpoint,ControlRadius);
	{ deleteVehicle _x } forEach (allMines select { _x distance _position < _controlRadius });
	{ deleteVehicle _x } forEach (_position nearObjects ["GroundWeaponHolder", _controlRadius]); // Delete any disarmed mines //BUG: Gets other stuff as well.  We can look inside the holders and root out the mines if we want to
};

OO_TRACE_DECL(SPM_Strongpoint_Update) =
{
	params ["_strongpoint"];

	private _updateTime = diag_tickTime + ([_strongpoint] call OO_GET(_strongpoint,Strongpoint,GetUpdateInterval));
	OO_SET(_strongpoint,Strongpoint,UpdateTime,_updateTime);

	private _updateIndex = OO_GET(_strongpoint,Strongpoint,UpdateIndex) + 1;
	OO_SET(_strongpoint,Strongpoint,UpdateIndex,_updateIndex);
};

OO_TRACE_DECL(SPM_Strongpoint_Command) =
{
	params ["_strongpoint", "_command", "_parameters"];

	{
		[_command, _parameters] call OO_METHOD(_x,Category,Command);
	} forEach OO_GET(_strongpoint,Strongpoint,Categories);
};

OO_TRACE_DECL(SPM_Strongpoint_GetTagValue) =
{
	params ["_strongpoint", "_tag"];

	[OO_GET(_strongpoint,Strongpoint,_Tags), _tag] call SPM_Util_GetDataValue
};

OO_TRACE_DECL(SPM_Strongpoint_SetTagValue) =
{
	params ["_strongpoint", "_tag", "_value"];

	[OO_GET(_strongpoint,Strongpoint,_Tags), _tag, _value] call SPM_Util_SetDataValue
};

SPM_Strongpoint_SendNotification =
{
	params ["_strongpoint", "_message", "_type"];

	[_message, ["chat"]] call SPM_Mission_Message;
};

OO_BEGIN_CLASS(Strongpoint);
	OO_OVERRIDE_METHOD(Strongpoint,Root,Create,SPM_Strongpoint_Create);
	OO_OVERRIDE_METHOD(Strongpoint,Root,Delete,SPM_Strongpoint_Delete);
	OO_DEFINE_METHOD(Strongpoint,Run,SPM_Strongpoint_Run);
	OO_DEFINE_METHOD(Strongpoint,Stop,SPM_Strongpoint_Stop);
	OO_DEFINE_METHOD(Strongpoint,Update,SPM_Strongpoint_Update);
	OO_DEFINE_METHOD(Strongpoint,AddCategory,SPM_Strongpoint_AddCategory);
	OO_DEFINE_METHOD(Strongpoint,GetTagValue,SPM_Strongpoint_GetTagValue);
	OO_DEFINE_METHOD(Strongpoint,SetTagValue,SPM_Strongpoint_SetTagValue);
	OO_DEFINE_METHOD(Strongpoint,Command,SPM_Strongpoint_Command);
	OO_DEFINE_PROPERTY(Strongpoint,RunStart,"SCALAR",0);
	OO_DEFINE_PROPERTY(Strongpoint,RunDuration,"SCALAR",-1);
	OO_DEFINE_PROPERTY(Strongpoint,RunState,"STRING","starting"); // starting, running, timeout, stopped, deleted
	OO_DEFINE_PROPERTY(Strongpoint,UpdateTime,"SCALAR",0);
	OO_DEFINE_PROPERTY(Strongpoint,UpdateIndex,"BOOL",0);
	OO_DEFINE_PROPERTY(Strongpoint,GetUpdateInterval,"CODE",{10});
	OO_DEFINE_PROPERTY(Strongpoint,Position,"ARRAY",[]);
	OO_DEFINE_PROPERTY(Strongpoint,ActivityRadius,"SCALAR",0); // Indicates the entire area of activity for the strongpoint.  Units spawn in no closer than this distance when entering a running strongpoint.
	OO_DEFINE_PROPERTY(Strongpoint,ControlRadius,"SCALAR",0); // Indicates the area that the strongpoint is about.
	OO_DEFINE_PROPERTY(Strongpoint,Name,"STRING","");
	OO_DEFINE_PROPERTY(Strongpoint,Categories,"ARRAY",[]);
	OO_DEFINE_PROPERTY(Strongpoint,SpawnManager,"#OBJ",OO_NULL);
	OO_DEFINE_PROPERTY(Strongpoint,InitializeObject,"CODE",{});
	OO_DEFINE_PROPERTY(Strongpoint,SendNotification,"CODE",{}); // Expected parameters are [strongpoint, [messages], [media-types]]
	OO_DEFINE_PROPERTY(Strongpoint,_Tags,"ARRAY",[]);
OO_END_CLASS(Strongpoint);

OO_TRACE_DECL(SPM_Category_InitializeObject) =
{
	params ["_category", "_object"];

	private _strongpoint = OO_GETREF(_category,Category,Strongpoint);
	private _initializeObject = OO_GET(_strongpoint,Strongpoint,InitializeObject);

	[_category, _object] call _initializeObject;
};

OO_TRACE_DECL(SPM_Category_Update) =
{
	params ["_category"];

	private _updateTime = diag_tickTime + ([_category] call OO_GET(_category,Category,GetUpdateInterval));
	OO_SET(_category,Category,UpdateTime,_updateTime);

	private _updateIndex = OO_GET(_category,Category,UpdateIndex) + 1;
	OO_SET(_category,Category,UpdateIndex,_updateIndex);
};

OO_TRACE_DECL(SPM_Category_SendNotification) =
{
	params ["_category", "_origin", "_message", "_type"];

	private _strongpoint = OO_GETREF(_category,Category,Strongpoint);
	[_strongpoint, _origin, _message, _type] call OO_GET(_strongpoint,Strongpoint,SendNotification);
};

OO_TRACE_DECL(SPM_Category_Command) =
{
	params ["_category", "_command", "_parameters"];
};

OO_TRACE_DECL(SPM_Category_GetTagValue) =
{
	params ["_category", "_tag"];

	[OO_GET(_category,Category,_Tags), _tag] call SPM_Util_GetDataValue
};

OO_TRACE_DECL(SPM_Category_SetTagValue) =
{
	params ["_category", "_tag", "_value"];

	[OO_GET(_category,Category,_Tags), _tag, _value] call SPM_Util_SetDataValue
};

OO_BEGIN_CLASS(Category);
	OO_DEFINE_METHOD(Category,Update,SPM_Category_Update);
	OO_DEFINE_METHOD(Category,GetTagValue,SPM_Category_GetTagValue);
	OO_DEFINE_METHOD(Category,SetTagValue,SPM_Category_SetTagValue);
	OO_DEFINE_METHOD(Category,SendNotification,SPM_Category_SendNotification);
	OO_DEFINE_METHOD(Category,Command,SPM_Category_Command);
	OO_DEFINE_PROPERTY(Category,Strongpoint,"#REF",OO_NULL);
	OO_DEFINE_PROPERTY(Category,InitializeObject,"CODE",SPM_Category_InitializeObject); // By default, use the strongpoint's initializer
	OO_DEFINE_PROPERTY(Category,UpdateTime,"SCALAR",0);
	OO_DEFINE_PROPERTY(Category,UpdateIndex,"BOOL",0);
	OO_DEFINE_PROPERTY(Category,GetUpdateInterval,"CODE",{10});
	OO_DEFINE_PROPERTY(Category,_Tags,"ARRAY",[]);
OO_END_CLASS(Category);
