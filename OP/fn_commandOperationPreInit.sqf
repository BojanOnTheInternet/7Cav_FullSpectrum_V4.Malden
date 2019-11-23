/*
Copyright (c) 2017-2019, John Buehler

Permission is hereby granted, free of charge, to any person obtaining a copy of this software (the "Software"), to deal in the Software, including the rights to use, copy, modify, merge, publish and/or distribute copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (not isServer && hasInterface) exitWith {};

#include "..\SPM\strongpoint.h"
#include "op.h"

OO_TRACE_DECL(OP_GetPlayerSelection) =
{	
	params ["_player"];

	_player getVariable ["OP_Selection", OP_SELECTION_NULL]
};

OO_TRACE_DECL(OP_GetCallerSelection) =
{
	private _caller = [remoteExecutedOwner] call SPM_Util_GetOwnerPlayer;

	if (isNull _caller) exitWith { OP_SELECTION_NULL };

	[_caller] call OP_GetPlayerSelection
};

OP_MissionControllersMonitoringKnownOperations = [];
OP_KnownOperations = [];

[] spawn
{
	scriptName "OP_UpdateKnownOperations";

	while { sleep 2; true } do
	{
		if (count OP_MissionControllersMonitoringKnownOperations > 0) then
		{
			[] call OP_UpdateKnownOperations;
		};
	};
};

OO_TRACE_DECL(OP_UpdateKnownOperations) =
{
	private _knownOperations = [];
	OO_FOREACHINSTANCE(Strongpoint,[],{ _knownOperations pushBack _x; false });

	_knownOperations = _knownOperations apply { [OO_REFERENCE(_x), OO_GET(_x,Strongpoint,Position), OO_GET(_x,Strongpoint,ActivityRadius), OO_GET(_x,Strongpoint,Name)] };
	_knownOperations sort true;

	if (not (_knownOperations isEqualTo OP_KnownOperations)) then
	{
		OP_KnownOperations = _knownOperations;
		{
			[OP_KnownOperations] remoteExec ["OP_C_SetKnownOperations", _x];
		} forEach OP_MissionControllersMonitoringKnownOperations;
	};
};

OO_TRACE_DECL(OP_COMMAND__OperationStart) =
{
	private _selection = call OP_GetCallerSelection;

	if (OO_ISNULL(_selection select 0)) then
	{
		["No operation is selected."] call SPM_Util_MessageCaller;
	}
	else
	{
		private _mission = OO_INSTANCE(_selection select 0);

		if (OO_GET(_mission,Strongpoint,RunState) != "starting") then
		{
			["The selected operation has already been started."] call SPM_Util_MessageCaller;
		}
		else
		{
			["Starting selected operation."] call SPM_Util_MessageCaller;
			[_mission] spawn
			{
				params ["_mission"];
				
				scriptName "OP_COMMAND__OperationStart";
				
				call OO_METHOD(_mission,Strongpoint,Run);

				call OO_DELETE(_mission);
			};
		};
	};

	[OP_COMMAND_RESULT_MATCHED]
};

OO_TRACE_DECL(OP_COMMAND__OperationStop) =
{
	private _selection = call OP_GetCallerSelection;

	if (OO_ISNULL(_selection select 0)) then
	{
		["No operation is selected."] call SPM_Util_MessageCaller;
	}
	else
	{
		private _mission = OO_INSTANCE(_selection select 0);

		switch OO_GET(_mission,Strongpoint,RunState) do
		{
			case "running":
			{
				[] call OO_METHOD(_mission,Strongpoint,Stop);
				[_mission] call OP_S_NotifyRemovedMission;
				["The operation is stopping."] call SPM_Util_MessageCaller;
			};
			case "starting":
			{
				[] call OO_DELETE(_mission);
				[_mission] call OP_S_NotifyRemovedMission;
				["The operation is stopping."] call SPM_Util_MessageCaller;
			};
			default
			{
				["The operation has already been stopped."] call SPM_Util_MessageCaller;
			};
		};
	};

	[OP_COMMAND_RESULT_MATCHED]
};

OO_TRACE_DECL(OP_COMMAND__OperationSurrender) =
{
	params ["_commandWords"];

	if (count _commandWords > 1) exitWith
	{
		[format ["Expected only a number at: '%1'", _commandWords joinString " "]] call SPM_Util_MessageCaller;

		[OP_COMMAND_RESULT_MATCHED]
	};

	private _surrenderDuration = 10;
	if (count _commandWords == 1) then { _surrenderDuration = parseNumber (_commandWords select 0) };

	if (_surrenderDuration == 0) exitWith
	{
		[format ["Expected a number at '%1'", _commandWords select 0]] call SPM_Util_MessageCaller;

		[OP_COMMAND_RESULT_MATCHED]
	};

	private _selection = call OP_GetCallerSelection;

	if (OO_ISNULL(_selection select 0)) then
	{
		["No operation is selected."] call SPM_Util_MessageCaller;
	}
	else
	{
		private _mission = OO_INSTANCE(_selection select 0);

		[format ["Surrendering all forces in operation over the next %1 seconds...", _surrenderDuration]] call SPM_Util_MessageCaller;
		["surrender", _surrenderDuration] call OO_METHOD(_mission,Strongpoint,Command);
	};

	[OP_COMMAND_RESULT_MATCHED]
};

OO_TRACE_DECL(OP_COMMAND__OperationRename) =
{
	params ["_commandWords"];

	if (count _commandWords == 0) exitWith
	{
		["Specify a name for the operation"] call SPM_Util_MessageCaller;

		[OP_COMMAND_RESULT_MATCHED]
	};

	if (count _commandWords > 1) exitWith
	{
		[format ["Unexpected: '%1'", _commandWords joinString " "]] call SPM_Util_MessageCaller;

		[OP_COMMAND_RESULT_MATCHED]
	};

	private _name = _commandWords select 0;

	private _selection = call OP_GetCallerSelection;
	if (OO_ISNULL(_selection select 0)) then
	{
		["No operation is selected."] call SPM_Util_MessageCaller;
	}
	else
	{
		private _nameInUse = false;
		OO_FOREACHINSTANCE(Mission,[],{ if (OO_GET(_x,Strongpoint,Name) == _name) then { _nameInUse = true; true } else { false } });

		if (_nameInUse) then
		{
			[format ["An operation named '%1' already exists", _name]] call SPM_Util_MessageCaller;
		}
		else
		{
			private _mission = OO_INSTANCE(_selection select 0);

			OO_SET(_mission,Strongpoint,Name,_name);

			[format ["Operation renamed to '%1'", _name]] call SPM_Util_MessageCaller;

			_selection = +_selection;
			_selection set [3, _name];
			[_selection] remoteExec ["OP_C_SetSelection", remoteExecutedOwner];
		};
	};

	[OP_COMMAND_RESULT_MATCHED]
};

OP_OperationNumber = 0;

OO_TRACE_DECL(OP_GetMission) =
{
	private _selection = call OP_GetCallerSelection;
	_selection params ["_reference", "_center", "_radius"];

	if (not OO_ISNULL(_reference)) exitWith { OO_INSTANCE(_reference) };

	if (_radius == 0) exitWith
	{
		["Either select an existing operation or select an area for a new operation."] call SPM_Util_MessageCaller;
		OO_NULL
	};

	private _message = format ["Creating operation on %1.", if (isServer) then { "server" } else { vehicleVarName player }];
	[_message] call SPM_Util_MessageCaller;
	private _mission = [_center, _radius, _radius, 2] call OO_CREATE(Mission);

	OP_OperationNumber = OP_OperationNumber + 1;
	private _name = format ["%1 Operation %2", if (isServer) then { "Server" } else { vehicleVarName player }, OP_OperationNumber];
	OO_SET(_mission,Strongpoint,Name,_name);
	OO_SET(_mission,Strongpoint,InitializeObject,SERVER_InitializeCategoryObject);

	_reference = OO_REFERENCE(_mission);
	_selection = [_reference, _center, _radius, _name, if (isServer) then { objNull } else { player }];
	[_selection] remoteExec ["OP_C_SetSelection", remoteExecutedOwner];

	_mission
};

SPM_Command_OperationSides = ["csat", "civilian", "syndikat"];

OO_TRACE_DECL(SPM_Command_OperationSetGarrisonSide) =
{
	params ["_garrison", "_side"];

	switch (_side) do
	{
		case "csat":
		{
			OO_SET(_garrison,ForceCategory,SideEast,east);
			OO_SET(_garrison,ForceCategory,SkillLevel,0.5);
			OO_SET(_garrison,InfantryGarrisonCategory,HouseOutdoors,true);

			OO_SET(_garrison,ForceCategory,RatingsEast,SPM_InfantryGarrison_RatingsEast);
			OO_SET(_garrison,ForceCategory,CallupsEast,SPM_InfantryGarrison_CallupsEast);
			OO_SET(_garrison,InfantryGarrisonCategory,InitialCallupsEast,SPM_InfantryGarrison_InitialCallupsEast);
		};

		case "civilian":
		{
			OO_SET(_garrison,ForceCategory,SideEast,civilian);
			OO_SET(_garrison,InfantryGarrisonCategory,HouseOutdoors,true);
	
			OO_SET(_garrison,ForceCategory,RatingsEast,SPM_InfantryGarrison_RatingsCivilian);
			OO_SET(_garrison,ForceCategory,CallupsEast,SPM_InfantryGarrison_CallupsCivilian);
			OO_SET(_garrison,InfantryGarrisonCategory,InitialCallupsEast,SPM_InfantryGarrison_CallupsCivilian);
		};

		case "syndikat":
		{
			OO_SET(_garrison,ForceCategory,SideEast,independent);
			OO_SET(_garrison,ForceCategory,SkillLevel,0.35);
			OO_SET(_garrison,InfantryGarrisonCategory,HouseOutdoors,true);

			OO_SET(_garrison,ForceCategory,RatingsEast,SPM_InfantryGarrison_RatingsSyndikat);
			OO_SET(_garrison,ForceCategory,CallupsEast,SPM_InfantryGarrison_CallupsSyndikat);
			OO_SET(_garrison,InfantryGarrisonCategory,InitialCallupsEast,SPM_InfantryGarrison_InitialCallupsSyndikat);
		};
	};
};

OP_COMMAND__OperationCreateGarrison_Usage =
[
	"create garrison name",
	[
		["-area", false, true, "#RANGE", [0,100]]
	]
];

OO_TRACE_DECL(OP_COMMAND__OperationCreateGarrison) =
{
	params ["_commandWords"];

	private _name = _commandWords select 0;

	if (_name find "-" == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationCreateGarrison_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _parameters = [_commandWords, OP_COMMAND__OperationCreateGarrison_Usage] call OP_COMMAND_ParseParameters;
	if ({ _x select 0 == -1 } count _parameters > 0) exitWith { [OP_COMMAND_RESULT_MATCHED] };
	if ({ _x select 0 >= 0 } count _parameters == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationCreateGarrison_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _mission = call OP_GetMission;

	if (OO_ISNULL(_mission)) exitWith { [OP_COMMAND_RESULT_MATCHED] };

	private _categories = OO_GET(_mission,Strongpoint,Categories) select { (["Name"] call OO_METHOD(_x,Category,GetTagValue)) find _name != -1 } select { OO_INSTANCE_ISOFCLASS(_x,InfantryGarrisonCategory) };
	if (count _categories > 0) exitWith { [format ["The operation already contains a garrison called '%1'", _name]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _areaParameter = [_parameters, "-area"] call OP_COMMAND_GetParsedParameter;

	private _areaValues = (_areaParameter select 2) apply { _x / 100 }; // Convert to percentages

	private _center = OO_GET(_mission,Strongpoint,Position);
	private _radius = OO_GET(_mission,Strongpoint,ActivityRadius);
	private _innerRadius = (_areaValues select 0) * _radius;
	private _outerRadius = (_areaValues select 1) * _radius;

	private _area = [_center, _innerRadius, _outerRadius] call OO_CREATE(StrongpointArea);
	_garrison = [_area] call OO_CREATE(InfantryGarrisonCategory);
	OO_SET(_garrison,ForceCategory,RatingsWest,SPM_InfantryGarrison_RatingsWest);
	OO_SET(_garrison,ForceCategory,RatingsEast,SPM_InfantryGarrison_RatingsEast);
	OO_SET(_garrison,ForceCategory,CallupsEast,SPM_InfantryGarrison_CallupsEast);
	["Name", _name] call OO_METHOD(_garrison,Category,SetTagValue);

	OO_SET(_garrison,ForceCategory,Reserves,0);
	OO_SET(_garrison,ForceCategory,RangeWest,500);
	OO_SET(_garrison,InfantryGarrisonCategory,InitialReserves,0);

	[_garrison, "csat"] call SPM_Command_OperationSetGarrisonSide;

	[_garrison] call OO_METHOD(_mission,Strongpoint,AddCategory);

	[format ["Garrison '%1' added to operation", _name]] call SPM_Util_MessageCaller;

	[OP_COMMAND_RESULT_MATCHED]
};

OP_COMMAND__OperationCreateCheckpoints_Usage =
[
	"create checkpoints name",
	[
		["-garrison", true, true, "STRING"],
		["-area", false, true, "#RANGE", [0,100]]
	]
];

OO_TRACE_DECL(OP_COMMAND__OperationCreateCheckpoints) =
{
	params ["_commandWords"];

	private _name = _commandWords select 0;

	if (_name find "-" == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationCreateCheckpoints_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _parameters = [_commandWords, OP_COMMAND__OperationCreateCheckpoints_Usage] call OP_COMMAND_ParseParameters;
	if ({ _x select 0 == -1 } count _parameters > 0) exitWith { [OP_COMMAND_RESULT_MATCHED] };
	if ({ _x select 0 >= 0 } count _parameters == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationCreateCheckpoints_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _mission = call OP_GetMission;

	if (OO_ISNULL(_mission)) exitWith { [OP_COMMAND_RESULT_MATCHED] };

	private _categories = OO_GET(_mission,Strongpoint,Categories) select { (["Name"] call OO_METHOD(_x,Category,GetTagValue)) find _name != -1 } select { OO_INSTANCE_ISOFCLASS(_x,CheckpointsCategory) };
	if (count _categories > 0) exitWith { [format ["The operation already contains a checkpoints called '%1'", _name]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _areaParameter = [_parameters, "-area"] call OP_COMMAND_GetParsedParameter;
	private _garrisonParameter = [_parameters, "-garrison"] call OP_COMMAND_GetParsedParameter;

	private _categories = OO_GET(_mission,Strongpoint,Categories) select { (["Name"] call OO_METHOD(_x,Category,GetTagValue)) find (_garrisonParameter select 2) != -1 } select { OO_INSTANCE_ISOFCLASS(_x,InfantryGarrisonCategory) };
	if (count _categories == 0) exitWith { [format ["The operation does not contain a garrison called '%1'", (_garrisonParameter select 2)]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _garrison = _categories select 0;

	private _areaValues = (_areaParameter select 2) apply { _x / 100 }; // Convert to percentages

	private _center = OO_GET(_mission,Strongpoint,Position);
	private _radius = OO_GET(_mission,Strongpoint,ActivityRadius);
	private _innerRadius = (_areaValues select 0) * _radius;
	private _outerRadius = (_areaValues select 1) * _radius;

	private _area = [_center, _innerRadius, _outerRadius] call OO_CREATE(StrongpointArea);
	_checkpoints = [_area, _garrison, 1e30] call OO_CREATE(CheckpointsCategory);
	["Name", _name] call OO_METHOD(_checkpoints,Category,SetTagValue);

	[_checkpoints] call OO_METHOD(_mission,Strongpoint,AddCategory);

	[format ["Checkpoints '%1' added to operation", _name]] call SPM_Util_MessageCaller;

	[OP_COMMAND_RESULT_MATCHED]
};

OP_COMMAND__OperationCreateArmor_Usage =
[
	"create armor name",
	[
		["-area", false, true, "#RANGE", [0,100]]
	]
];

OO_TRACE_DECL(OP_COMMAND__OperationCreateArmor) =
{
	params ["_commandWords"];

	private _name = _commandWords select 0;

	if (isNil "_name" || { _name find "-" == 0 }) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationCreateArmor_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _parameters = [_commandWords, OP_COMMAND__OperationCreateArmor_Usage] call OP_COMMAND_ParseParameters;
	if ({ _x select 0 == -1 } count _parameters > 0) exitWith { [OP_COMMAND_RESULT_MATCHED] };
	if ({ _x select 0 >= 0 } count _parameters == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationCreateArmor_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _mission = call OP_GetMission;

	if (OO_ISNULL(_mission)) exitWith { [OP_COMMAND_RESULT_MATCHED] };

	private _categories = OO_GET(_mission,Strongpoint,Categories) select { (["Name"] call OO_METHOD(_x,Category,GetTagValue)) find _name != -1 } select { OO_INSTANCE_ISOFCLASS(_x,ArmorCategory) };
	if (count _categories > 0) exitWith { [format ["The operation already contains armor called '%1'", _name]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _areaParameter = [_parameters, "-area"] call OP_COMMAND_GetParsedParameter;

	private _areaValues = (_areaParameter select 2) apply { _x / 100 }; // Convert to percentages

	private _center = OO_GET(_mission,Strongpoint,Position);
	private _radius = OO_GET(_mission,Strongpoint,ActivityRadius);
	private _innerRadius = (_areaValues select 0) * _radius;
	private _outerRadius = (_areaValues select 1) * _radius;

	private _area = [_center, _innerRadius, _outerRadius] call OO_CREATE(StrongpointArea);
	_armor = [_area] call OO_CREATE(ArmorCategory);
	["Name", _name] call OO_METHOD(_armor,Category,SetTagValue);
	OO_SET(_armor,ForceCategory,RatingsWest,[]);

	OO_SET(_armor,ForceCategory,Reserves,0);
	OO_SET(_armor,ArmorCategory,PatrolType,"area");
	OO_SET(_armor,ForceCategory,RatingsEast,[]);
	OO_SET(_armor,ForceCategory,CallupsEast,[]);
	OO_SET(_armor,ForceCategory,RangeWest,1500);

	[_armor] call OO_METHOD(_mission,Strongpoint,AddCategory);

	[format ["Armor '%1' added to operation", _name]] call SPM_Util_MessageCaller;

	[OP_COMMAND_RESULT_MATCHED]
};

OP_COMMAND__OperationCreateCars_Usage =
[
	"create cars name",
	[
		["-area", false, true, "#RANGE", [0,100]]
	]
];

OO_TRACE_DECL(OP_COMMAND__OperationCreateCars) =
{
	params ["_commandWords"];

	private _name = _commandWords select 0;

	if (isNil "_name" || { _name find "-" == 0 }) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationCreateCars_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _parameters = [_commandWords, OP_COMMAND__OperationCreateCars_Usage] call OP_COMMAND_ParseParameters;
	if ({ _x select 0 == -1 } count _parameters > 0) exitWith { [OP_COMMAND_RESULT_MATCHED] };
	if ({ _x select 0 >= 0 } count _parameters == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationCreateCars_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _mission = call OP_GetMission;

	if (OO_ISNULL(_mission)) exitWith { [OP_COMMAND_RESULT_MATCHED] };

	private _categories = OO_GET(_mission,Strongpoint,Categories) select { (["Name"] call OO_METHOD(_x,Category,GetTagValue)) find _name != -1 } select { OO_INSTANCE_ISOFCLASS(_x,CarsCategory) };
	if (count _categories > 0) exitWith { [format ["The operation already contains cars called '%1'", _name]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _areaParameter = [_parameters, "-area"] call OP_COMMAND_GetParsedParameter;

	private _areaValues = (_areaParameter select 2) apply { _x / 100 }; // Convert to percentages

	private _center = OO_GET(_mission,Strongpoint,Position);
	private _radius = OO_GET(_mission,Strongpoint,ActivityRadius);
	private _innerRadius = (_areaValues select 0) * _radius;
	private _outerRadius = (_areaValues select 1) * _radius;

	private _area = [_center, _innerRadius, _outerRadius] call OO_CREATE(StrongpointArea);
	_cars = [_area] call OO_CREATE(CivilianVehiclesCategory);
	["Name", _name] call OO_METHOD(_cars,Category,SetTagValue);

	[_cars] call OO_METHOD(_mission,Strongpoint,AddCategory);

	[format ["Cars '%1' added to operation", _name]] call SPM_Util_MessageCaller;

	[OP_COMMAND_RESULT_MATCHED]
};

OP_COMMAND__OperationCreateTransport_Usage =
[
	"create transport name",
	[
	]
];

OO_TRACE_DECL(OP_COMMAND__OperationCreateTransport) =
{
	params ["_commandWords"];

	private _name = _commandWords select 0;

	if (isNil "_name" || { _name find "-" == 0 }) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationCreateTransport_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

//	private _parameters = [_commandWords, OP_COMMAND__OperationCreateTransport_Usage] call OP_COMMAND_ParseParameters;
//	if ({ _x select 0 == -1 } count _parameters > 0) exitWith { [OP_COMMAND_RESULT_MATCHED] };
//	if ({ _x select 0 >= 0 } count _parameters == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationCreateTransport_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _mission = call OP_GetMission;

	if (OO_ISNULL(_mission)) exitWith { [OP_COMMAND_RESULT_MATCHED] };

	private _categories = OO_GET(_mission,Strongpoint,Categories) select { (["Name"] call OO_METHOD(_x,Category,GetTagValue)) find _name != -1 } select { OO_INSTANCE_ISOFCLASS(_x,TransportCategory) };
	if (count _categories > 0) exitWith { [format ["The operation already contains transport called '%1'", _name]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	_transport = [] call OO_CREATE(TransportCategory);
	["Name", _name] call OO_METHOD(_transport,Category,SetTagValue);

	OO_SET(_transport,TransportCategory,SeaTransports,[]);
	OO_SET(_transport,TransportCategory,GroundTransports,[]);
	OO_SET(_transport,TransportCategory,AirTransports,[]);

	[_transport] call OO_METHOD(_mission,Strongpoint,AddCategory);

	[format ["Transport '%1' added to operation", _name]] call SPM_Util_MessageCaller;

	[OP_COMMAND_RESULT_MATCHED]
};

OP_COMMAND__OperationCreateMortar_Usage =
[
	"create mortar name",
	[
		["-garrison", true, true, "STRING"],
		["-number", false, true, "SCALAR", 1]
	]
];

OO_TRACE_DECL(OP_COMMAND__OperationCreateMortar) =
{
	params ["_commandWords"];

	private _name = _commandWords select 0;

	if (isNil "_name" || { _name find "-" == 0 }) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationCreateMortar_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _parameters = [_commandWords, OP_COMMAND__OperationCreateMortar_Usage] call OP_COMMAND_ParseParameters;
	if ({ _x select 0 == -1 } count _parameters > 0) exitWith { [OP_COMMAND_RESULT_MATCHED] };
	if ({ _x select 0 >= 0 } count _parameters == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationCreateMortar_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _mission = call OP_GetMission;

	if (OO_ISNULL(_mission)) exitWith { [OP_COMMAND_RESULT_MATCHED] };

	private _categories = OO_GET(_mission,Strongpoint,Categories) select { (["Name"] call OO_METHOD(_x,Category,GetTagValue)) find _name != -1 } select { OO_INSTANCE_ISOFCLASS(_x,MortarCategory) };
	if (count _categories > 0) exitWith { [format ["The operation already contains a mortar called '%1'", _name]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _garrisonParameter = [_parameters, "-garrison"] call OP_COMMAND_GetParsedParameter;
	private _numberParameter = [_parameters, "-number"] call OP_COMMAND_GetParsedParameter;

	private _categories = OO_GET(_mission,Strongpoint,Categories) select { (["Name"] call OO_METHOD(_x,Category,GetTagValue)) find (_garrisonParameter select 2) != -1 } select { OO_INSTANCE_ISOFCLASS(_x,InfantryGarrisonCategory) };
	if (count _categories == 0) exitWith { [format ["The operation does not contain a garrison called '%1'", (_garrisonParameter select 2)]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _garrison = _categories select 0;
	private _number = _numberParameter select 2;

	_category = [_number, _garrison] call OO_CREATE(MortarCategory);
	["Name", _name] call OO_METHOD(_category,Category,SetTagValue);
	[_category] call OO_METHOD(_mission,Strongpoint,AddCategory);

	OO_GET(_garrison,InfantryGarrisonCategory,Mortars) pushBack _category;

	[format ["Mortar '%1' added to operation", _name]] call SPM_Util_MessageCaller;

	[OP_COMMAND_RESULT_MATCHED]
};

OP_COMMAND__OperationCreateDump_Usage =
[
	"create dump name",
	[
		["-garrison", true, true, "STRING"]
	]
];

OO_TRACE_DECL(OP_COMMAND__OperationCreateDump) =
{
	params ["_commandWords"];

	private _name = _commandWords select 0;

	if (isNil "_name" || { _name find "-" == 0 }) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationCreateDump_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _parameters = [_commandWords, OP_COMMAND__OperationCreateDump_Usage] call OP_COMMAND_ParseParameters;
	if ({ _x select 0 == -1 } count _parameters > 0) exitWith { [OP_COMMAND_RESULT_MATCHED] };
	if ({ _x select 0 >= 0 } count _parameters == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationCreateDump_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _mission = call OP_GetMission;

	if (OO_ISNULL(_mission)) exitWith { [OP_COMMAND_RESULT_MATCHED] };

	private _categories = OO_GET(_mission,Strongpoint,Categories) select { (["Name"] call OO_METHOD(_x,Category,GetTagValue)) find _name != -1 } select { OO_INSTANCE_ISOFCLASS(_x,ObjectiveMarkAmmoDump) };
	if (count _categories > 0) exitWith { [format ["The operation already contains a dump called '%1'", _name]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _garrisonParameter = [_parameters, "-garrison"] call OP_COMMAND_GetParsedParameter;

	private _categories = OO_GET(_mission,Strongpoint,Categories) select { (["Name"] call OO_METHOD(_x,Category,GetTagValue)) find (_garrisonParameter select 2) != -1 } select { OO_INSTANCE_ISOFCLASS(_x,InfantryGarrisonCategory) };
	if (count _categories == 0) exitWith { [format ["The operation does not contain a garrison called '%1'", (_garrisonParameter select 2)]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _garrison = _categories select 0;

	private _position = OO_GET(_mission,Strongpoint,Position);
	private _area = [_position, 0, 50] call OO_CREATE(StrongpointArea);
	private _ammoDump = [_area] call OO_CREATE(AmmoDumpCategory);
	[_ammoDump] call OO_METHOD(_mission,Strongpoint,AddCategory);

	private _objective = [_ammoDump] call OO_CREATE(ObjectiveMarkAmmoDump);
	["Name", _name] call OO_METHOD(_objective,Category,SetTagValue);
	[_objective] call OO_METHOD(_mission,Mission,AddObjective);

	private _pulse = [_objective, 8.0] call OO_CREATE(DamagePulseCategory);
	OO_SET(_pulse,DamagePulseCategory,DamageScale,0.06); // Make the barrel very durable
	[_pulse] call OO_METHOD(_mission,Strongpoint,AddCategory);

	private _guardableObject = [] call OO_CREATE(GuardableObjectiveObject);
	OO_SET(_guardableObject,GuardableObjectiveObject,Objective,_objective);

	private _category = [_guardableObject, _garrison, 4] call OO_CREATE(GuardObjectCategory);
	[_category] call OO_METHOD(_mission,Strongpoint,AddCategory);

	[format ["Ammunition dump '%1' added to operation", _name]] call SPM_Util_MessageCaller;

	[OP_COMMAND_RESULT_MATCHED]
};

SPM_Command_OperationContainerTypes = ["crates"];

OP_COMMAND__OperationCreateCaches_Usage =
[
	"create caches name",
	[
		["-garrison", true, true, "STRING"],
		["-caches", true, true, "SCALAR"],
		["-containers", false, true, "#RANGE", [2,5]],
		["-types", false, true, "STRING", SPM_Command_OperationContainerTypes select 0, SPM_Command_OperationContainerTypes],
		["-find", false, true, "SCALAR", -1]
	]
];

OO_TRACE_DECL(OP_COMMAND__OperationCreateCaches) =
{
	params ["_commandWords"];

	private _name = _commandWords select 0;

	if (isNil "_name" || { _name find "-" == 0 }) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationCreateCaches_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _parameters = [_commandWords, OP_COMMAND__OperationCreateCaches_Usage] call OP_COMMAND_ParseParameters;
	if ({ _x select 0 == -1 } count _parameters > 0) exitWith { [OP_COMMAND_RESULT_MATCHED] };
	if ({ _x select 0 >= 0 } count _parameters == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationCreateCaches_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _mission = call OP_GetMission;

	if (OO_ISNULL(_mission)) exitWith { [OP_COMMAND_RESULT_MATCHED] };

	private _categories = OO_GET(_mission,Strongpoint,Categories) select { (["Name"] call OO_METHOD(_x,Category,GetTagValue)) find _name != -1 } select { OO_INSTANCE_ISOFCLASS(_x,ObjectiveMarkAmmoCaches) };
	if (count _categories > 0) exitWith { [format ["The operation already contains a caches objective called '%1'", _name]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _garrisonParameter = [_parameters, "-garrison"] call OP_COMMAND_GetParsedParameter;

	private _categories = OO_GET(_mission,Strongpoint,Categories) select { (["Name"] call OO_METHOD(_x,Category,GetTagValue)) find (_garrisonParameter select 2) != -1 } select { OO_INSTANCE_ISOFCLASS(_x,InfantryGarrisonCategory) };
	if (count _categories == 0) exitWith { [format ["The operation does not contain a garrison called '%1'", (_garrisonParameter select 2)]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _garrison = _categories select 0;

	private _cachesParameter = [_parameters, "-caches"] call OP_COMMAND_GetParsedParameter;
	private _containersParameter = [_parameters, "-containers"] call OP_COMMAND_GetParsedParameter;
	private _typesParameter = [_parameters, "-types"] call OP_COMMAND_GetParsedParameter;
	private _findParameter = [_parameters, "-find"] call OP_COMMAND_GetParsedParameter;

	private _caches = _cachesParameter select 2;
	if (_caches <= 0) exitWith  { [format ["The number of caches must be greater than zero (specified %1)", (_cachesParameter select 2)]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _containers = _containersParameter select 2;

	private _types = _typesParameter select 2;
	switch (_types) do
	{
		case "crates": { _types = [[["Box_Syndicate_Ammo_F", 500], ["Box_IED_Exp_F", 5000], ["Box_Syndicate_WpsLaunch_F", 2000, true], ["Box_Syndicate_Wps_F", 1000]]] };
	};

	private _find = _findParameter select 2;
	_find = if (_find == -1) then { 0.75 } else { ((_find / _caches) max 0.0) min 1.0 };

	private _category = [_garrison, _caches, _containers, _types] call OO_CREATE(AmmoCachesCategory);
	[_category] call OO_METHOD(_mission,Strongpoint,AddCategory);

	private _objective = [_category, _find] call OO_CREATE(ObjectiveMarkAmmoCaches);
	["Name", _name] call OO_METHOD(_objective,Category,SetTagValue);
	[_objective] call OO_METHOD(_mission,Mission,AddObjective);

	[format ["Ammunition caches '%1' added to operation", _name]] call SPM_Util_MessageCaller;

	[OP_COMMAND_RESULT_MATCHED]
};

OP_COMMAND__OperationCreateTower_Usage =
[
	"create tower name",
	[
		["-garrison", true, true, "STRING"]
	]
];

OO_TRACE_DECL(OP_COMMAND__OperationCreateTower) =
{
	params ["_commandWords"];

	private _name = _commandWords select 0;

	if (isNil "_name" || { _name find "-" == 0 }) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationCreateTower_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _parameters = [_commandWords, OP_COMMAND__OperationCreateTower_Usage] call OP_COMMAND_ParseParameters;
	if ({ _x select 0 == -1 } count _parameters > 0) exitWith { [OP_COMMAND_RESULT_MATCHED] };
	if ({ _x select 0 >= 0 } count _parameters == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationCreateTower_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _mission = call OP_GetMission;

	if (OO_ISNULL(_mission)) exitWith { [OP_COMMAND_RESULT_MATCHED] };

	private _categories = OO_GET(_mission,Strongpoint,Categories) select { (["Name"] call OO_METHOD(_x,Category,GetTagValue)) find _name != -1 } select { OO_INSTANCE_ISOFCLASS(_x,ObjectiveMarkRadioTower) };
	if (count _categories > 0) exitWith { [format ["The operation already contains a tower called '%1'", _name]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _garrisonParameter = [_parameters, "-garrison"] call OP_COMMAND_GetParsedParameter;

	private _categories = OO_GET(_mission,Strongpoint,Categories) select { (["Name"] call OO_METHOD(_x,Category,GetTagValue)) find (_garrisonParameter select 2) != -1 } select { OO_INSTANCE_ISOFCLASS(_x,InfantryGarrisonCategory) };
	if (count _categories == 0) exitWith { [format ["The operation does not contain a garrison called '%1'", (_garrisonParameter select 2)]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _garrison = _categories select 0;

	private _position = OO_GET(_mission,Strongpoint,Position);
	private _area = [_position, 0, 50] call OO_CREATE(StrongpointArea);
	private _radioTower = ["Land_Communication_F", _area] call OO_CREATE(RadioTowerCategory);
	[_radioTower] call OO_METHOD(_mission,Strongpoint,AddCategory);

	private _objective = [_radioTower] call OO_CREATE(ObjectiveMarkRadioTower);
	["Name", _name] call OO_METHOD(_objective,Category,SetTagValue);
	[_objective] call OO_METHOD(_mission,Mission,AddObjective);

	private _pulse = [_objective, 0.8] call OO_CREATE(DamagePulseCategory);
	[_pulse] call OO_METHOD(_mission,Strongpoint,AddCategory);

	private _guardableObject = [] call OO_CREATE(GuardableObjectiveObject);
	OO_SET(_guardableObject,GuardableObjectiveObject,Objective,_objective);

	private _category = [_guardableObject, _garrison, 2] call OO_CREATE(GuardObjectCategory);
	[_category] call OO_METHOD(_mission,Strongpoint,AddCategory);

	[format ["Communications tower '%1' added to operation", _name]] call SPM_Util_MessageCaller;

	[OP_COMMAND_RESULT_MATCHED]
};

OP_COMMAND__OperationCreateSatellite_Usage =
[
	"create satellite name",
	[
		["-garrison", true, true, "STRING"],
		["-guards", false, true, "SCALAR", 2]
	]
];

OO_TRACE_DECL(OP_COMMAND__OperationCreateSatellite) =
{
	params ["_commandWords"];

	private _name = _commandWords select 0;

	if (isNil "_name" || { _name find "-" == 0 }) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationCreateSatellite_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _parameters = [_commandWords, OP_COMMAND__OperationCreateSatellite_Usage] call OP_COMMAND_ParseParameters;
	if ({ _x select 0 == -1 } count _parameters > 0) exitWith { [OP_COMMAND_RESULT_MATCHED] };
	if ({ _x select 0 >= 0 } count _parameters == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationCreateSatellite_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _mission = call OP_GetMission;

	if (OO_ISNULL(_mission)) exitWith { [OP_COMMAND_RESULT_MATCHED] };

	private _categories = OO_GET(_mission,Strongpoint,Categories) select { (["Name"] call OO_METHOD(_x,Category,GetTagValue)) find _name != -1 } select { OO_INSTANCE_ISOFCLASS(_x,ObjectiveDestroyCommunicationCenter) };
	if (count _categories > 0) exitWith { [format ["The operation already contains a satellite communication center called '%1'", _name]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _garrisonParameter = [_parameters, "-garrison"] call OP_COMMAND_GetParsedParameter;
	private _guardsParameter = [_parameters, "-guards"] call OP_COMMAND_GetParsedParameter;

	private _categories = OO_GET(_mission,Strongpoint,Categories) select { (["Name"] call OO_METHOD(_x,Category,GetTagValue)) find (_garrisonParameter select 2) != -1 } select { OO_INSTANCE_ISOFCLASS(_x,InfantryGarrisonCategory) };
	if (count _categories == 0) exitWith { [format ["The operation does not contain a garrison called '%1'", (_garrisonParameter select 2)]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _garrison = _categories select 0;

	private _numberGuards = _guardsParameter select 2;

	private _communicationCenter = [_garrison] call OO_CREATE(SatelliteCommunicationCenterCategory);
	[_communicationCenter] call OO_METHOD(_mission,Strongpoint,AddCategory);

	private _objective = [_communicationCenter] call OO_CREATE(ObjectiveDestroyCommunicationCenter);
	["Name", _name] call OO_METHOD(_objective,Category,SetTagValue);
	[_objective] call OO_METHOD(_mission,Mission,AddObjective);

	if (_numberGuards > 0) then
	{
		private _guardableObject = [] call OO_CREATE(GuardableObjectiveObject);
		OO_SET(_guardableObject,GuardableObjectiveObject,Objective,_objective);

		private _category = [_guardableObject, _garrison, _numberGuards] call OO_CREATE(GuardObjectCategory);
		[_category] call OO_METHOD(_mission,Strongpoint,AddCategory);
	};

	[format ["Satellite communication center '%1' added to operation", _name]] call SPM_Util_MessageCaller;

	[OP_COMMAND_RESULT_MATCHED]
};

OP_COMMAND__OperationCreateRadio_Usage =
[
	"create radio name",
	[
		["-garrison", true, true, "STRING"],
		["-guards", false, true, "SCALAR", 2]
	]
];

OO_TRACE_DECL(OP_COMMAND__OperationCreateRadio) =
{
	params ["_commandWords"];

	private _name = _commandWords select 0;

	if (isNil "_name" || { _name find "-" == 0 }) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationCreateRadio_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _parameters = [_commandWords, OP_COMMAND__OperationCreateRadio_Usage] call OP_COMMAND_ParseParameters;
	if ({ _x select 0 == -1 } count _parameters > 0) exitWith { [OP_COMMAND_RESULT_MATCHED] };
	if ({ _x select 0 >= 0 } count _parameters == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationCreateRadio_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _mission = call OP_GetMission;

	if (OO_ISNULL(_mission)) exitWith { [OP_COMMAND_RESULT_MATCHED] };

	private _categories = OO_GET(_mission,Strongpoint,Categories) select { (["Name"] call OO_METHOD(_x,Category,GetTagValue)) find _name != -1 } select { OO_INSTANCE_ISOFCLASS(_x,ObjectiveDestroyCommunicationCenter) };
	if (count _categories > 0) exitWith { [format ["The operation already contains a radio communication center called '%1'", _name]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _garrisonParameter = [_parameters, "-garrison"] call OP_COMMAND_GetParsedParameter;
	private _guardsParameter = [_parameters, "-guards"] call OP_COMMAND_GetParsedParameter;

	private _categories = OO_GET(_mission,Strongpoint,Categories) select { (["Name"] call OO_METHOD(_x,Category,GetTagValue)) find (_garrisonParameter select 2) != -1 } select { OO_INSTANCE_ISOFCLASS(_x,InfantryGarrisonCategory) };
	if (count _categories == 0) exitWith { [format ["The operation does not contain a garrison called '%1'", (_garrisonParameter select 2)]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _garrison = _categories select 0;

	private _numberGuards = _guardsParameter select 2;

	private _communicationCenter = [_garrison] call OO_CREATE(RadioCommunicationCenterCategory);
	[_communicationCenter] call OO_METHOD(_mission,Strongpoint,AddCategory);

	private _objective = [_communicationCenter] call OO_CREATE(ObjectiveDestroyCommunicationCenter);
	["Name", _name] call OO_METHOD(_objective,Category,SetTagValue);
	[_objective] call OO_METHOD(_mission,Mission,AddObjective);

	if (_numberGuards > 0) then
	{
		private _guardableObject = [] call OO_CREATE(GuardableObjectiveObject);
		OO_SET(_guardableObject,GuardableObjectiveObject,Objective,_objective);

		private _category = [_guardableObject, _garrison, _numberGuards] call OO_CREATE(GuardObjectCategory);
		[_category] call OO_METHOD(_mission,Strongpoint,AddCategory);
	};

	[format ["Radio communication center '%1' added to operation", _name]] call SPM_Util_MessageCaller;

	[OP_COMMAND_RESULT_MATCHED]
};

OP_COMMAND__OperationCreateTarget_Usage =
[
	"create target name",
	[
		["-garrison", true, true, "STRING"],
		["-type", true, true, "STRING"],
		["-required", false, false, "STRING", "true", ["true", "false"]]
	]
];

OO_TRACE_DECL(OP_COMMAND__OperationCreateTarget) =
{
	params ["_commandWords"];

	private _name = _commandWords select 0;

	if (isNil "_name" || { _name find "-" == 0 }) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationCreateTarget_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _parameters = [_commandWords, OP_COMMAND__OperationCreateTarget_Usage] call OP_COMMAND_ParseParameters;
	if ({ _x select 0 == -1 } count _parameters > 0) exitWith { [OP_COMMAND_RESULT_MATCHED] };
	if ({ _x select 0 >= 0 } count _parameters == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationCreateTarget_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _mission = call OP_GetMission;

	if (OO_ISNULL(_mission)) exitWith { [OP_COMMAND_RESULT_MATCHED] };

	private _categories = OO_GET(_mission,Strongpoint,Categories) select { (["Name"] call OO_METHOD(_x,Category,GetTagValue)) find _name != -1 } select { OO_INSTANCE_ISOFCLASS(_x,ObjectiveCaptureMan) };
	if (count _categories > 0) exitWith { [format ["The operation already contains a target called '%1'", _name]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _garrisonParameter = [_parameters, "-garrison"] call OP_COMMAND_GetParsedParameter;

	private _categories = OO_GET(_mission,Strongpoint,Categories) select { (["Name"] call OO_METHOD(_x,Category,GetTagValue)) find (_garrisonParameter select 2) != -1 } select { OO_INSTANCE_ISOFCLASS(_x,InfantryGarrisonCategory) };
	if (count _categories == 0) exitWith { [format ["The operation does not contain a garrison called '%1'", (_garrisonParameter select 2)]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _garrison = _categories select 0;

	private _typeParameter = [_parameters, "-type"] call OP_COMMAND_GetParsedParameter;

	private _type = _typeParameter select 2;

	if (not (_type isKindOf "Man")) exitWith { [format ["The target type '%1' does not specify a type of soldier or civilian.", _type]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _requiredParameter = [_parameters, "-required"] call OP_COMMAND_GetParsedParameter;
	private _required = ((_requiredParameter select 2) == "true");

	private _position = OO_GET(_mission,Strongpoint,Position);
	private _area = [_position, 0, 50] call OO_CREATE(StrongpointArea);

	private _unitProvider = [_garrison, nil, nil, _type, nil, nil, _name] call OO_CREATE(ProvideGarrisonUnit);
	[_unitProvider] call OO_METHOD(_mission,Strongpoint,AddCategory);

	private _objective = [_unitProvider] call OO_CREATE(ObjectiveCaptureMan);
	["Name", _name] call OO_METHOD(_objective,Category,SetTagValue);
	if (_required) then { OO_SET(_objective,MissionObjective,CompletionStates,SPM_MissionObjective_CompletionStates_Required) } else { OO_SET(_objective,MissionObjective,CompletionStates,SPM_MissionObjective_CompletionStates_Optional) };
	[_objective] call OO_METHOD(_mission,Mission,AddObjective);

	[format ["Target '%1' added to operation", _name]] call SPM_Util_MessageCaller;

	[OP_COMMAND_RESULT_MATCHED]
};

OP_COMMAND__OperationCreateCaptive_Usage =
[
	"create captive name",
	[
		["-garrison", true, true, "STRING"],
		["-type", true, true, "STRING"],
		["-required", false, false, "STRING", "true", ["true", "false"]]
	]
];

OO_TRACE_DECL(OP_COMMAND__OperationCreateCaptive) =
{
	params ["_commandWords"];

	private _name = _commandWords select 0;

	if (isNil "_name" || { _name find "-" == 0 }) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationCreateCaptive_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _parameters = [_commandWords, OP_COMMAND__OperationCreateCaptive_Usage] call OP_COMMAND_ParseParameters;
	if ({ _x select 0 == -1 } count _parameters > 0) exitWith { [OP_COMMAND_RESULT_MATCHED] };
	if ({ _x select 0 >= 0 } count _parameters == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationCreateCaptive_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _mission = call OP_GetMission;

	if (OO_ISNULL(_mission)) exitWith { [OP_COMMAND_RESULT_MATCHED] };

	private _categories = OO_GET(_mission,Strongpoint,Categories) select { (["Name"] call OO_METHOD(_x,Category,GetTagValue)) find _name != -1 } select { OO_INSTANCE_ISOFCLASS(_x,ObjectiveCaptureMan) };
	if (count _categories > 0) exitWith { [format ["The operation already contains a captive called '%1'", _name]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _garrisonParameter = [_parameters, "-garrison"] call OP_COMMAND_GetParsedParameter;

	private _categories = OO_GET(_mission,Strongpoint,Categories) select { (["Name"] call OO_METHOD(_x,Category,GetTagValue)) find (_garrisonParameter select 2) != -1 } select { OO_INSTANCE_ISOFCLASS(_x,InfantryGarrisonCategory) };
	if (count _categories == 0) exitWith { [format ["The operation does not contain a garrison called '%1'", (_garrisonParameter select 2)]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _garrison = _categories select 0;

	private _typeParameter = [_parameters, "-type"] call OP_COMMAND_GetParsedParameter;

	private _type = _typeParameter select 2;

	if (not (_type isKindOf "Man")) exitWith { [format ["The captive type '%1' does not specify a type of soldier or civilian.", _type]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _requiredParameter = [_parameters, "-required"] call OP_COMMAND_GetParsedParameter;
	private _required = ((_requiredParameter select 2) == "true");

	private _position = OO_GET(_mission,Strongpoint,Position);
	private _area = [_position, 0, 50] call OO_CREATE(StrongpointArea);

	private _unitProvider = [_garrison, nil, nil, _type, nil, nil, _name] call OO_CREATE(ProvideGarrisonUnit);
	[_unitProvider] call OO_METHOD(_mission,Strongpoint,AddCategory);

	private _objective = [_unitProvider] call OO_CREATE(ObjectiveRescueMan);
	["Name", _name] call OO_METHOD(_objective,Category,SetTagValue);
	if (_required) then { OO_SET(_objective,MissionObjective,CompletionStates,SPM_MissionObjective_CompletionStates_Required) } else { OO_SET(_objective,MissionObjective,CompletionStates,SPM_MissionObjective_CompletionStates_Optional) };
	[_objective] call OO_METHOD(_mission,Mission,AddObjective);

	private _guardableObject = [] call OO_CREATE(GuardableObjectiveObject);
	OO_SET(_guardableObject,GuardableObjectiveObject,Objective,_objective);

	private _category = [_guardableObject, _garrison, 4] call OO_CREATE(GuardObjectCategory);
	[_category] call OO_METHOD(_mission,Strongpoint,AddCategory);

	[format ["Captive '%1' added to operation", _name]] call SPM_Util_MessageCaller;

	[OP_COMMAND_RESULT_MATCHED]
};

OP_COMMAND__OperationCreatePatrolPerimeter_Usage =
[
	"create patrol perimeter name",
	[
		["-garrison", true, true, "STRING"],
		["-area", false, true, "#RANGE", [0,100]]
	]
];

OO_TRACE_DECL(OP_COMMAND__OperationCreatePatrolPerimeter) =
{
	params ["_commandWords"];

	private _name = _commandWords select 0;

	if (isNil "_name" || { _name find "-" == 0 }) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationCreatePatrolPerimeter_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _parameters = [_commandWords, OP_COMMAND__OperationCreatePatrolPerimeter_Usage] call OP_COMMAND_ParseParameters;
	if ({ _x select 0 == -1 } count _parameters > 0) exitWith { [OP_COMMAND_RESULT_MATCHED] };
	if ({ _x select 0 >= 0 } count _parameters == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationCreatePatrolPerimeter_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _mission = call OP_GetMission;

	if (OO_ISNULL(_mission)) exitWith { [OP_COMMAND_RESULT_MATCHED] };

	private _categories = OO_GET(_mission,Strongpoint,Categories) select { (["Name"] call OO_METHOD(_x,Category,GetTagValue)) find _name != -1 } select { OO_INSTANCE_ISOFCLASS(_x,PerimeterPatrolCategory) };
	if (count _categories > 0) exitWith { [format ["The operation already contains a patrol called '%1'", _name]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _garrisonParameter = [_parameters, "-garrison"] call OP_COMMAND_GetParsedParameter;

	private _categories = OO_GET(_mission,Strongpoint,Categories) select { (["Name"] call OO_METHOD(_x,Category,GetTagValue)) find (_garrisonParameter select 2) != -1 } select { OO_INSTANCE_ISOFCLASS(_x,InfantryGarrisonCategory) };
	if (count _categories == 0) exitWith { [format ["The operation does not contain a garrison called '%1'", (_garrisonParameter select 2)]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _garrison = _categories select 0;

	private _areaParameter = [_parameters, "-area"] call OP_COMMAND_GetParsedParameter;
	private _areaValues = (_areaParameter select 2) apply { _x / 100 }; // Convert to percentages

	private _center = OO_GET(_mission,Strongpoint,Position);
	private _radius = OO_GET(_mission,Strongpoint,ActivityRadius);
	private _innerRadius = (_areaValues select 0) * _radius;
	private _outerRadius = (_areaValues select 1) * _radius;

	private _area = [_center, _innerRadius, _outerRadius] call OO_CREATE(StrongpointArea);
	private _patrol = [_area, _garrison] call OO_CREATE(PerimeterPatrolCategory);
	["Name", _name] call OO_METHOD(_patrol,Category,SetTagValue);
	OO_SET(_patrol,InfantryPatrolCategory,OnStartPatrol,SERVER_Infantry_OnStartPatrol);

	[_patrol] call OO_METHOD(_mission,Strongpoint,AddCategory);

	[format ["Patrol '%1' added to operation", _name]] call SPM_Util_MessageCaller;

	[OP_COMMAND_RESULT_MATCHED]
};

OO_TRACE_DECL(OP_COMMAND__OperationCreatePatrol) =
{
	params ["_commandWords"];

	private _commands =
	[
		["perimeter", OP_COMMAND__OperationCreatePatrolPerimeter]
	];

	private _match = [_commandWords select 0, _commands] call OP_COMMAND_Match;

	if (_match select 0 < 0) exitWith { _match };

	private _command = _match select 1;

	[_commandWords select [1, 1e3]] call (_command select 1);
};

OO_TRACE_DECL(OP_COMMAND__OperationCreate) =
{
	params ["_commandWords"];

	private _commands =
	[
		["garrison", OP_COMMAND__OperationCreateGarrison],
		["transport", OP_COMMAND__OperationCreateTransport],
		["armor", OP_COMMAND__OperationCreateArmor],
		["mortar", OP_COMMAND__OperationCreateMortar],
		["tower", OP_COMMAND__OperationCreateTower],
		["dump", OP_COMMAND__OperationCreateDump],
		["caches", OP_COMMAND__OperationCreateCaches],
		["target", OP_COMMAND__OperationCreateTarget],
		["captive", OP_COMMAND__OperationCreateCaptive],
		["patrol", OP_COMMAND__OperationCreatePatrol],
		["cars", OP_COMMAND__OperationCreateCars],
		["satellite", OP_COMMAND__OperationCreateSatellite],
		["radio", OP_COMMAND__OperationCreateRadio],
		["checkpoints", OP_COMMAND__OperationCreateCheckpoints]
	];

	private _match = [_commandWords select 0, _commands] call OP_COMMAND_Match;

	if (_match select 0 < 0) exitWith { _match };

	private _command = _match select 1;

	[_commandWords select [1, 1e3]] call (_command select 1);
};

OP_COMMAND__OperationDeleteGarrison_Usage =
[
	"delete garrison name",
	[
	]
];

OO_TRACE_DECL(OP_COMMAND__OperationDeleteGarrison) =
{
	params ["_commandWords"];

	private _name = _commandWords select 0;

	if (_name find "-" == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationDeleteGarrison_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

//	private _parameters = [_commandWords, OP_COMMAND__OperationDeleteGarrison_Usage] call OP_COMMAND_ParseParameters;
//	if ({ _x select 0 == -1 } count _parameters > 0) exitWith { [OP_COMMAND_RESULT_MATCHED] };
//	if ({ _x select 0 >= 0 } count _parameters == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationDeleteGarrison_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _selection = [] call OP_GetCallerSelection;
	private _reference = _selection select 0;

	if (OO_ISNULL(_reference)) exitWith { [OP_COMMAND_RESULT_MATCHED] };

	private _mission = OO_INSTANCE(_reference);

	private _categories = OO_GET(_mission,Strongpoint,Categories) select { (["Name"] call OO_METHOD(_x,Category,GetTagValue)) find _name != -1 } select { OO_INSTANCE_ISOFCLASS(_x,InfantryGarrisonCategory) };
	if (count _categories == 0) exitWith { [format ["The operation does not contain a garrison called '%1'", _name]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _garrison = _categories select 0;

	call OO_DELETE(_garrison);

	[OP_COMMAND_RESULT_MATCHED]
};

OP_COMMAND__OperationDeleteTransport_Usage =
[
	"delete transport name",
	[
	]
];

OO_TRACE_DECL(OP_COMMAND__OperationDeleteTransport) =
{
	params ["_commandWords"];

	private _name = _commandWords select 0;

	if (isNil "_name" || { _name find "-" == 0 }) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationDeleteTransport_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

//	private _parameters = [_commandWords, OP_COMMAND__OperationDeleteTransport_Usage] call OP_COMMAND_ParseParameters;
//	if ({ _x select 0 == -1 } count _parameters > 0) exitWith { [OP_COMMAND_RESULT_MATCHED] };
//	if ({ _x select 0 >= 0 } count _parameters == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationDeleteTransport_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _selection = [] call OP_GetCallerSelection;
	private _mission = _selection select 0;

	if (OO_ISNULL(_mission)) exitWith { [OP_COMMAND_RESULT_MATCHED] };

	_mission = OO_INSTANCE(_mission);

	private _categories = OO_GET(_mission,Strongpoint,Categories) select { (["Name"] call OO_METHOD(_x,Category,GetTagValue)) find _name != -1 } select { OO_INSTANCE_ISOFCLASS(_x,TransportCategory) };
	if (count _categories == 0) exitWith { [format ["The operation does not contain transport called '%1'", _name]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _transport = _categories select 0;

	call OO_DELETE(_transport);

	[OP_COMMAND_RESULT_MATCHED]
};

OP_COMMAND__OperationDeleteArmor_Usage =
[
	"delete armor name",
	[
	]
];

OO_TRACE_DECL(OP_COMMAND__OperationDeleteArmor) =
{
	params ["_commandWords"];

	private _name = _commandWords select 0;

	if (isNil "_name" || { _name find "-" == 0 }) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationDeleteArmor_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

//	private _parameters = [_commandWords, OP_COMMAND__OperationDeleteArmor_Usage] call OP_COMMAND_ParseParameters;
//	if ({ _x select 0 == -1 } count _parameters > 0) exitWith { [OP_COMMAND_RESULT_MATCHED] };
//	if ({ _x select 0 >= 0 } count _parameters == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationDeleteArmor_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _selection = [] call OP_GetCallerSelection;
	private _mission = _selection select 0;

	if (OO_ISNULL(_mission)) exitWith { [OP_COMMAND_RESULT_MATCHED] };

	_mission = OO_INSTANCE(_mission);

	private _categories = OO_GET(_mission,Strongpoint,Categories) select { (["Name"] call OO_METHOD(_x,Category,GetTagValue)) find _name != -1 } select { OO_INSTANCE_ISOFCLASS(_x,ArmorCategory) };
	if (count _categories == 0) exitWith { [format ["The operation does not contain armor called '%1'", _name]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _armor = _categories select 0;

	call OO_DELETE(_armor);

	[OP_COMMAND_RESULT_MATCHED]
};

OP_COMMAND__OperationDeleteMortar_Usage =
[
	"delete mortar name",
	[
	]
];

OO_TRACE_DECL(OP_COMMAND__OperationDeleteMortar) =
{
	params ["_commandWords"];

	private _name = _commandWords select 0;

	if (isNil "_name" || { _name find "-" == 0 }) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationDeleteMortar_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

//	private _parameters = [_commandWords, OP_COMMAND__OperationDeleteMortar_Usage] call OP_COMMAND_ParseParameters;
//	if ({ _x select 0 == -1 } count _parameters > 0) exitWith { [OP_COMMAND_RESULT_MATCHED] };
//	if ({ _x select 0 >= 0 } count _parameters == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationDeleteMortar_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _selection = [] call OP_GetCallerSelection;
	private _mission = _selection select 0;

	if (OO_ISNULL(_mission)) exitWith { [OP_COMMAND_RESULT_MATCHED] };

	_mission = OO_INSTANCE(_mission);

	private _categories = OO_GET(_mission,Strongpoint,Categories) select { (["Name"] call OO_METHOD(_x,Category,GetTagValue)) find _name != -1 } select { OO_INSTANCE_ISOFCLASS(_x,MortarCategory) };
	if (count _categories == 0) exitWith { [format ["The operation does not contain a mortar called '%1'", _name]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _mortar = _categories select 0;

	private _garrison = OO_GETREF(_mortar,MortarCategory,Garrison);
	private _mortarIndex = -1;
	{
		if (_x isEqualTo _mortar) exitWith { _mortarIndex = _forEachIndex };
	} forEach OO_GET(_garrison,InfantryGarrisonCategory,Mortars);
	if (_mortarIndex != -1) then { OO_GET(_garrison,InfantryGarrisonCategory,Mortars) deleteAt _mortarIndex };

	call OO_DELETE(_mortar);

	[format ["Mortar '%1' removed from operation", _name]] call SPM_Util_MessageCaller;

	[OP_COMMAND_RESULT_MATCHED]
};

OP_COMMAND__OperationDeleteDump_Usage =
[
	"delete dump name",
	[
	]
];

OO_TRACE_DECL(OP_COMMAND__OperationDeleteDump) =
{
	params ["_commandWords"];

	private _name = _commandWords select 0;

	if (isNil "_name" || { _name find "-" == 0 }) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationDeleteDump_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

//	private _parameters = [_commandWords, OP_COMMAND__OperationDeleteDump_Usage] call OP_COMMAND_ParseParameters;
//	if ({ _x select 0 == -1 } count _parameters > 0) exitWith { [OP_COMMAND_RESULT_MATCHED] };
//	if ({ _x select 0 >= 0 } count _parameters == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationDeleteDump_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _selection = [] call OP_GetCallerSelection;
	private _mission = _selection select 0;

	if (OO_ISNULL(_mission)) exitWith { [OP_COMMAND_RESULT_MATCHED] };

	_mission = OO_INSTANCE(_mission);

	private _categories = OO_GET(_mission,Strongpoint,Categories) select { (["Name"] call OO_METHOD(_x,Category,GetTagValue)) find _name != -1 } select { OO_INSTANCE_ISOFCLASS(_x,ObjectiveMarkAmmoDump) };
	if (count _categories == 0) exitWith { [format ["The operation does not contain a dump called '%1'", _name]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _dump = _categories select 0;

	call OO_DELETE(_dump);

	[format ["Dump '%1' removed from operation", _name]] call SPM_Util_MessageCaller;

	[OP_COMMAND_RESULT_MATCHED]
};

OP_COMMAND__OperationDeleteTower_Usage =
[
	"delete tower name",
	[
	]
];

OO_TRACE_DECL(OP_COMMAND__OperationDeleteTower) =
{
	params ["_commandWords"];

	private _name = _commandWords select 0;

	if (isNil "_name" || { _name find "-" == 0 }) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationDeleteTower_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

//	private _parameters = [_commandWords, OP_COMMAND__OperationDeleteTower_Usage] call OP_COMMAND_ParseParameters;
//	if ({ _x select 0 == -1 } count _parameters > 0) exitWith { [OP_COMMAND_RESULT_MATCHED] };
//	if ({ _x select 0 >= 0 } count _parameters == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationDeleteTower_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _selection = [] call OP_GetCallerSelection;
	private _mission = _selection select 0;

	if (OO_ISNULL(_mission)) exitWith { [OP_COMMAND_RESULT_MATCHED] };

	_mission = OO_INSTANCE(_mission);

	private _categories = OO_GET(_mission,Strongpoint,Categories) select { (["Name"] call OO_METHOD(_x,Category,GetTagValue)) find _name != -1 } select { OO_INSTANCE_ISOFCLASS(_x,ObjectiveMarkRadioTower) };
	if (count _categories == 0) exitWith { [format ["The operation does not contain a tower called '%1'", _name]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _tower = _categories select 0;

	call OO_DELETE(_tower);

	[format ["Tower '%1' removed from operation", _name]] call SPM_Util_MessageCaller;

	[OP_COMMAND_RESULT_MATCHED]
};

OP_COMMAND__OperationDeleteTarget_Usage =
[
	"delete target name",
	[
	]
];

OO_TRACE_DECL(OP_COMMAND__OperationDeleteTarget) =
{
	params ["_commandWords"];

	private _name = _commandWords select 0;

	if (isNil "_name" || { _name find "-" == 0 }) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationDeleteTower_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

//	private _parameters = [_commandWords, OP_COMMAND__OperationDeleteTarget_Usage] call OP_COMMAND_ParseParameters;
//	if ({ _x select 0 == -1 } count _parameters > 0) exitWith { [OP_COMMAND_RESULT_MATCHED] };
//	if ({ _x select 0 >= 0 } count _parameters == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationDeleteTarget_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _selection = [] call OP_GetCallerSelection;
	private _mission = _selection select 0;

	if (OO_ISNULL(_mission)) exitWith { [OP_COMMAND_RESULT_MATCHED] };

	_mission = OO_INSTANCE(_mission);

	private _categories = OO_GET(_mission,Strongpoint,Categories) select { (["Name"] call OO_METHOD(_x,Category,GetTagValue)) find _name != -1 } select { OO_INSTANCE_ISOFCLASS(_x,ObjectiveDestroyCaptureMan) };
	if (count _categories == 0) exitWith { [format ["The operation does not contain a target called '%1'", _name]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _target = _categories select 0;

	call OO_DELETE(_target);

	[format ["Target '%1' removed from operation", _name]] call SPM_Util_MessageCaller;

	[OP_COMMAND_RESULT_MATCHED]
};

OO_TRACE_DECL(OP_COMMAND__OperationDelete) =
{
	params ["_commandWords"];

	private _commands =
	[
		["garrison", OP_COMMAND__OperationDeleteGarrison],
		["transport", OP_COMMAND__OperationDeleteTransport],
		["armor", OP_COMMAND__OperationDeleteArmor],
		["mortar", OP_COMMAND__OperationDeleteMortar],
		["tower", OP_COMMAND__OperationDeleteTower],
		["dump", OP_COMMAND__OperationDeleteDump],
		["target", OP_COMMAND__OperationDeleteTarget]
	];

	private _match = [_commandWords select 0, _commands] call OP_COMMAND_Match;

	if (_match select 0 < 0) exitWith { _match };

	private _command = _match select 1;

	[_commandWords select [1, 1e3]] call (_command select 1);
};

OP_COMMAND__OperationAddArmor_Usage =
[
	"add armor name",
	[
		["-west", false, true, "STRING", nil, ["infantry", "apcs", "tanks", "cas", "airdefense"]],
		["-east", false, true, "STRING", nil, ["cars", "offroads", "apcs", "tanks", "helicopters", "airdefense"]]
	]
];

OO_TRACE_DECL(OP_COMMAND__OperationAddArmor) =
{
	params ["_commandWords"];

	private _name = _commandWords select 0;

	if (_name find "-" == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationAddArmor_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _parameters = [_commandWords, OP_COMMAND__OperationAddArmor_Usage] call OP_COMMAND_ParseParameters;
	if ({ _x select 0 == -1 } count _parameters > 0) exitWith { [OP_COMMAND_RESULT_MATCHED] };
	if ({ _x select 0 >= 0 } count _parameters == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationAddArmor_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _selection = [] call OP_GetCallerSelection;
	private _mission = _selection select 0;

	if (OO_ISNULL(_mission)) exitWith { [OP_COMMAND_RESULT_MATCHED] };

	_mission = OO_INSTANCE(_mission);

	private _categories = OO_GET(_mission,Strongpoint,Categories) select { (["Name"] call OO_METHOD(_x,Category,GetTagValue)) find _name != -1 } select { OO_INSTANCE_ISOFCLASS(_x,ArmorCategory) };

	if (count _categories == 0) exitWith { [format ["The operation does not contain armor called '%1'", _name]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };
	if (count _categories > 1) exitWith { [format ["'%1' is an ambiguous armor name", _name]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _armor = _categories select 0;

	private _westParameter = [_parameters, "-west"] call OP_COMMAND_GetParsedParameter;
	private _eastParameter = [_parameters, "-east"] call OP_COMMAND_GetParsedParameter;

	private _count = { _x } count [_westParameter select 0 == 0, _eastParameter select 0 == 0];
	if (_count == 0) exitWith { ["add armor: either -west or -east must be specified"] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };
	if (_count == 2) exitWith { ["add armor: only one of -west or -east may be specified"] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	if (_westParameter select 0 == 0) then
	{
		private _ratings = [];
		switch (_westParameter select 2) do
		{
			case "infantry": { _ratings = SPM_MissionAdvance_Patrol_RatingsWest };
			case "apcs": { _ratings = SPM_Armor_RatingsWestAPCs };
			case "tanks": { _ratings = SPM_Armor_RatingsWestTanks };
			case "cas": { _ratings = SPM_Armor_RatingsWestAir };
			case "airdefense": { _ratings = SPM_Armor_RatingsWestAirDefense };
		};
		private _ratingsWest = OO_GET(_armor,ForceCategory,RatingsWest);

		_ratingsWest append _ratings;

		private _totalRatingWest = 0; { _totalRatingWest = _totalRatingWest + (_x select 1 select 0) * (_x select 1 select 1) } forEach _ratingsWest;

		private _totalForce = 0; { _totalForce = _totalForce + OO_GET(_x,ForceRating,Rating) } forEach OO_GET(_armor,ForceCategory,InitialMinimumWestForce);
		private _force = [_totalForce, _totalRatingWest / count _ratingsWest] call SPM_ForceRating_CreateForce;
		OO_SET(_armor,ForceCategory,InitialMinimumWestForce,_force);

		private _totalForce = 0; { _totalForce = _totalForce + OO_GET(_x,ForceRating,Rating) } forEach OO_GET(_armor,ForceCategory,MinimumWestForce);
		private _force = [_totalForce, _totalRatingWest / count _ratingsWest] call SPM_ForceRating_CreateForce;
		OO_SET(_armor,ForceCategory,MinimumWestForce,_force);
	};

	if (_eastParameter select 0 == 0) then
	{
		private _callups = [];
		private _ratings = [];
		switch (_eastParameter select 2) do
		{
			case "cars": { _callups = SPM_MissionAdvance_Patrol_CallupsEast; _ratings = SPM_MissionAdvance_Patrol_RatingsEast; };
			case "offroads": { _callups = SPM_MissionAdvance_Patrol_CallupsSyndikat; _ratings = SPM_MissionAdvance_Patrol_RatingsSyndikat; };
			case "apcs": { _callups = SPM_Armor_CallupsEastAPCs; _ratings = SPM_Armor_RatingsEastAPCs; };
			case "tanks": { _callups = SPM_Armor_CallupsEastTanks; _ratings = SPM_Armor_RatingsEastTanks; };
			case "helicopters": { _callups = SPM_Armor_CallupsEastAir; _ratings = SPM_Armor_RatingsEastAir; };
			case "airdefense": { _callups = SPM_Armor_CallupsEastAirDefense; _ratings = SPM_Armor_RatingsEastAirDefense; };
		};
		OO_GET(_armor,ForceCategory,CallupsEast) append _callups;
		OO_GET(_armor,ForceCategory,RatingsEast) append _ratings;
	};

	[OP_COMMAND_RESULT_MATCHED]
};

OP_COMMAND__OperationAddPatrolPerimeter_Usage =
[
	"add patrol perimeter name",
	[
		["-size", false, true, "SCALAR", 4],
		["-direction", false, true, "STRING", "clockwise", ["clockwise", "counterclockwise"]],
		["-seebuildings", false, true, "SCALAR", 50],
		["-visitbuildings", false, true, "SCALAR", 1.0],
		["-enterbuildings", false, true, "SCALAR", 0.5],
		["-loiter", false, true, "SCALAR", 0]
	]
];

OO_TRACE_DECL(OP_COMMAND__OperationAddPatrolPerimeter) =
{
	params ["_commandWords"];

	private _name = _commandWords select 0;

	if (_name find "-" == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationAddPatrolPerimeter_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _parameters = [_commandWords, OP_COMMAND__OperationAddPatrolPerimeter_Usage] call OP_COMMAND_ParseParameters;
	if ({ _x select 0 == -1 } count _parameters > 0) exitWith { [OP_COMMAND_RESULT_MATCHED] };
	if ({ _x select 0 >= 0 } count _parameters == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationAddPatrolPerimeter_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _selection = [] call OP_GetCallerSelection;
	private _mission = _selection select 0;

	if (OO_ISNULL(_mission)) exitWith { [OP_COMMAND_RESULT_MATCHED] };

	_mission = OO_INSTANCE(_mission);

	private _categories = OO_GET(_mission,Strongpoint,Categories) select { (["Name"] call OO_METHOD(_x,Category,GetTagValue)) find _name != -1 } select { OO_INSTANCE_ISOFCLASS(_x,PerimeterPatrolCategory) };

	if (count _categories == 0) exitWith { [format ["The operation does not contain a patrol called '%1'", _name]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };
	if (count _categories > 1) exitWith { [format ["'%1' is an ambiguous a patrol name", _name]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _armor = _categories select 0;

	private _patrol = _categories select 0;

	private _sizeParameter = [_parameters, "-size"] call OP_COMMAND_GetParsedParameter;
	private _directionParameter = [_parameters, "-direction"] call OP_COMMAND_GetParsedParameter;
	private _seebuildingsParameter = [_parameters, "-seebuildings"] call OP_COMMAND_GetParsedParameter;
	private _visitbuildingsParameter = [_parameters, "-visitbuildings"] call OP_COMMAND_GetParsedParameter;
	private _enterbuildingsParameter = [_parameters, "-enterbuildings"] call OP_COMMAND_GetParsedParameter;
	private _loiterParameter = [_parameters, "-loiter"] call OP_COMMAND_GetParsedParameter;

	private _size = _sizeParameter select 2;
	private _direction = (_directionParameter select 2) == "clockwise";
	private _seebuildings = _seebuildingsParameter select 2;
	private _visitbuildings = _visitbuildingsParameter select 2;
	private _enterbuildings = _enterbuildingsParameter select 2;
	private _loiter = _loiterParameter select 2;

	[_size, _direction, _seebuildings, _visitbuildings, _enterbuildings, _loiter] call OO_METHOD(_patrol,InfantryPatrolCategory,AddPatrol);

	[OP_COMMAND_RESULT_MATCHED]
};

OO_TRACE_DECL(OP_COMMAND__OperationAddPatrol) =
{
	params ["_commandWords"];

	private _commands =
	[
		["perimeter", OP_COMMAND__OperationAddPatrolPerimeter]
	];

	private _match = [_commandWords select 0, _commands] call OP_COMMAND_Match;

	if (_match select 0 < 0) exitWith { _match };

	private _command = _match select 1;

	[_commandWords select [1, 1e3]] call (_command select 1);
};

OP_COMMAND__OperationAddTransport_Usage =
[
	"add transport name",
	[
		["-sea", false, true, "STRING", nil, ["speedboat"]],
		["-ground", false, true, "STRING", nil, ["marid", "zamak", "truck"]],
		["-air", false, true, "STRING", nil, ["mohawk"]]
	]
];

OO_TRACE_DECL(OP_COMMAND__OperationAddTransport) =
{
	params ["_commandWords"];

	private _name = _commandWords select 0;

	if (_name find "-" == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationAddTransport_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _parameters = [_commandWords, OP_COMMAND__OperationAddTransport_Usage] call OP_COMMAND_ParseParameters;
	if ({ _x select 0 == -1 } count _parameters > 0) exitWith { [OP_COMMAND_RESULT_MATCHED] };
	if ({ _x select 0 >= 0 } count _parameters == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationAddTransport_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _selection = [] call OP_GetCallerSelection;
	private _mission = _selection select 0;

	if (OO_ISNULL(_mission)) exitWith { [OP_COMMAND_RESULT_MATCHED] };

	_mission = OO_INSTANCE(_mission);

	private _categories = OO_GET(_mission,Strongpoint,Categories) select { (["Name"] call OO_METHOD(_x,Category,GetTagValue)) find _name != -1 } select { OO_INSTANCE_ISOFCLASS(_x,TransportCategory) };

	if (count _categories == 0) exitWith { [format ["The operation does not contain a transport called '%1'", _name]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };
	if (count _categories > 1) exitWith { [format ["'%1' is an ambiguous transport name", _name]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _transport = _categories select 0;

	private _seaParameter = [_parameters, "-sea"] call OP_COMMAND_GetParsedParameter;
	private _groundParameter = [_parameters, "-ground"] call OP_COMMAND_GetParsedParameter;
	private _airParameter = [_parameters, "-air"] call OP_COMMAND_GetParsedParameter;

	if (_seaParameter select 0 == 0) then
	{
		private _callups = [];
		switch (_seaParameter select 2) do
		{
			case "speedboat": { _callups = SPM_Transport_CallupsEastSpeedboat };
		};
		OO_GET(_transport,TransportCategory,SeaTransports) append _callups;
	};

	if (_groundParameter select 0 == 0) then
	{
		private _callups = [];
		switch (_groundParameter select 2) do
		{
			case "marid": { _callups = SPM_Transport_CallupsEastMarid };
			case "zamak": { _callups = SPM_Transport_CallupsEastZamak };
			case "truck": { _callups = SPM_Transport_CallupsEastTruck };
		};
		OO_GET(_transport,TransportCategory,GroundTransports) append _callups;
	};

	if (_airParameter select 0 == 0) then
	{
		private _callups = [];
		switch (_airParameter select 2) do
		{
			case "mohawk": { _callups = SPM_Transport_CallupsEastMohawk };
		};
		OO_GET(_transport,TransportCategory,AirTransports) append _callups;
	};

	[OP_COMMAND_RESULT_MATCHED]
};

OO_TRACE_DECL(OP_COMMAND__OperationAdd) =
{
	params ["_commandWords"];

	private _commands =
	[
		["armor", OP_COMMAND__OperationAddArmor],
		["patrol", OP_COMMAND__OperationAddPatrol],
		["transport", OP_COMMAND__OperationAddTransport]
	];

	private _match = [_commandWords select 0, _commands] call OP_COMMAND_Match;

	if (_match select 0 < 0) exitWith { _match };

	private _command = _match select 1;

	[_commandWords select [1, 1e3]] call (_command select 1);
};

SPM_Command_OperationGarrisonHousing = ["inner", "middle", "outer", "random"];

OP_COMMAND__OperationSetGarrison_Usage =
[
	"set garrison name",
	[
		["-initial", false, true, "SCALAR"],
		["-housing", false, true, "STRING", nil, SPM_Command_OperationGarrisonHousing],
		["-outdoors", false, true, "STRING", nil, ["true", "false"]],
		["-occupants", false, true, "#RANGE"],
		["-reserves", false, true, "SCALAR"],
		["-maintain", false, true, "SCALAR"],
		["-proximity", false, true, "SCALAR"],
		["-bysea", false, true, "SCALAR"],
		["-byground", false, true, "SCALAR"],
		["-skill", false, true, "SCALAR"],
		["-difficulty", false, true, "SCALAR"],
		["-side", false, true, "STRING", nil, SPM_Command_OperationSides],
		["-update", false, true, "#RANGE"],
		["-approach", false, true, "#DIRECTION"],
		["-transport", false, true, "STRING"],
		["-relocate", false, true, "SCALAR"]
	]
];

OO_TRACE_DECL(OP_COMMAND__OperationSetGarrison) =
{
	params ["_commandWords"];

	private _name = _commandWords select 0;

	if (_name find "-" == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationSetGarrison_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _parameters = [_commandWords, OP_COMMAND__OperationSetGarrison_Usage] call OP_COMMAND_ParseParameters;
	if ({ _x select 0 == -1 } count _parameters > 0) exitWith { [OP_COMMAND_RESULT_MATCHED] };
	if ({ _x select 0 >= 0 } count _parameters == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationSetGarrison_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _mission = call OP_GetMission;

	if (OO_ISNULL(_mission)) exitWith { [OP_COMMAND_RESULT_MATCHED] };

	private _categories = OO_GET(_mission,Strongpoint,Categories) select { (["Name"] call OO_METHOD(_x,Category,GetTagValue)) find _name != -1 } select { OO_INSTANCE_ISOFCLASS(_x,InfantryGarrisonCategory) };
	if (count _categories == 0) exitWith { [format ["The operation does not contain a garrison called '%1'", _name]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };
	if (count _categories > 1) exitWith { [format ["'%1' is an ambiguous garrison name", _name]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _garrison = _categories select 0;

	private _initialParameter = [_parameters, "-initial"] call OP_COMMAND_GetParsedParameter;
	private _housingParameter = [_parameters, "-housing"] call OP_COMMAND_GetParsedParameter;
	private _outdoorsParameter = [_parameters, "-outdoors"] call OP_COMMAND_GetParsedParameter;
	private _occupantsParameter = [_parameters, "-occupants"] call OP_COMMAND_GetParsedParameter;
	private _reservesParameter = [_parameters, "-reserves"] call OP_COMMAND_GetParsedParameter;
	private _maintainParameter = [_parameters, "-maintain"] call OP_COMMAND_GetParsedParameter;
	private _proximityParameter = [_parameters, "-proximity"] call OP_COMMAND_GetParsedParameter;
	private _byseaParameter = [_parameters, "-bysea"] call OP_COMMAND_GetParsedParameter;
	private _bygroundParameter = [_parameters, "-byground"] call OP_COMMAND_GetParsedParameter;
	private _skillParameter = [_parameters, "-skill"] call OP_COMMAND_GetParsedParameter;
	private _difficultyParameter = [_parameters, "-difficulty"] call OP_COMMAND_GetParsedParameter;
	private _sideParameter = [_parameters, "-side"] call OP_COMMAND_GetParsedParameter;
	private _updateParameter = [_parameters, "-update"] call OP_COMMAND_GetParsedParameter;
	private _approachParameter = [_parameters, "-approach"] call OP_COMMAND_GetParsedParameter;
	private _transportParameter = [_parameters, "-transport"] call OP_COMMAND_GetParsedParameter;
	private _relocateParameter = [_parameters, "-relocate"] call OP_COMMAND_GetParsedParameter;

	private _garrisonRatingEast = 0;
	{ _garrisonRatingEast = _garrisonRatingEast + (_x select 1 select 0) } forEach OO_GET(_garrison,ForceCategory,RatingsEast);
	_garrisonRatingEast = _garrisonRatingEast / count OO_GET(_garrison,ForceCategory,RatingsEast);

	private _garrisonRatingWest = 0;
	{ _garrisonRatingWest = _garrisonRatingWest + (_x select 1 select 0) } forEach OO_GET(_garrison,ForceCategory,RatingsWest);
	_garrisonRatingWest = _garrisonRatingWest / count OO_GET(_garrison,ForceCategory,RatingsWest);

	if (_initialParameter select 0 == 0) then
	{
		if (OO_GET(_mission,Strongpoint,RunState) != "starting") then
		{
			["The initial complement of a garrison may not be set after the operation has been started"] call SPM_Util_MessageCaller;
		}
		else
		{
			private _reserves = _initialParameter select 2;
			OO_SET(_garrison,InfantryGarrisonCategory,InitialReserves,_reserves);
		};
	};

	if (_housingParameter select 0 == 0) then
	{
		switch (_housingParameter select 2) do
		{
			case "inner": { OO_SET(_garrison,InfantryGarrisonCategory,HousingDistribution, 0.2) };
			case "middle": { OO_SET(_garrison,InfantryGarrisonCategory,HousingDistribution, 0.5) };
			case "outer": { OO_SET(_garrison,InfantryGarrisonCategory,HousingDistribution, 0.8) };
			case "random": { OO_SET(_garrison,InfantryGarrisonCategory,HousingDistribution, -1) };
		};
	};

	if (_outdoorsParameter select 0 == 0) then
	{
		private _outdoors = (_outdoorsParameter select 2) == "true";
		OO_SET(_garrison,InfantryGarrisonCategory,HouseOutdoors,_outdoors);
	};

	if (_occupantsParameter select 0 == 0) then
	{
		private _occupants = _occupantsParameter select 2;
		OO_SET(_garrison,InfantryGarrisonCategory,OccupationLimits,_occupants);
	};

	if (_reservesParameter select 0 == 0) then
	{
		private _reserves = _reservesParameter select 2;
		OO_SET(_garrison,ForceCategory,Reserves,_reserves);
	};

	if (_maintainParameter select 0 == 0) then
	{
		private _force = [_maintainParameter select 2, _garrisonRatingWest] call SPM_ForceRating_CreateForce;
		OO_SET(_garrison,ForceCategory,MinimumWestForce,_force);
		diag_log OO_GET(_garrison,ForceCategory,MinimumWestForce);
	};

	if (_proximityParameter select 0 == 0) then
	{
		private _proximity = _proximityParameter select 2;
		OO_SET(_garrison,ForceCategory,RangeWest,_proximity);
	};

	if (_byseaParameter select 0 == 0) then
	{
		private _bysea = _byseaParameter select 2;
		OO_SET(_garrison,InfantryGarrisonCategory,TransportBySea,_bysea);
	};

	if (_bygroundParameter select 0 == 0) then
	{
		private _byground = _bygroundParameter select 2;
		OO_SET(_garrison,InfantryGarrisonCategory,TransportByGround,_byground);
	};

	if (_skillParameter select 0 == 0) then
	{
		private _skill = _skillParameter select 2;
		OO_SET(_garrison,ForceCategory,SkillLevel,_skill);
	};

	if (_difficultyParameter select 0 == 0) then
	{
		private _difficulty = _difficultyParameter select 2;
		OO_SET(_garrison,ForceCategory,DifficultyLevel,_difficulty);
	};

	if (_sideParameter select 0 == 0) then
	{
		private _side = _sideParameter select 2;
		[_garrison, _side] call SPM_Command_OperationSetGarrisonSide;
	};

	if (_updateParameter select 0 == 0) then
	{
		private _update = _updateParameter select 2;
		private _remainingTime = OO_GET(_garrison,InfantryGarrisonCategory,_BalanceTime) - diag_tickTime;
		if (_remainingTime > _update select 1) then // If the InfantryGarrisonCategory's next update is beyond our maximum time, generate a new _BalanceTime
		{
			private _balanceTime = diag_tickTime + (_update select 0) + (random ((_update select 1) - (_update select 0)));
			OO_SET(_garrison,InfantryGarrisonCategory,_BalanceTime,_balanceTime);
		};
		OO_SET(_garrison,InfantryGarrisonCategory,BalanceInterval,_update);
	};

	if (_approachParameter select 0 == 0) then
	{
		private _approach = _approachParameter select 2;

		private _direction = _approach select 0;
		private _sweep = _approach select 1;

		if (_direction isEqualType []) then
		{
			private _area = OO_GET(_garrison,ForceCategory,Area);
			_direction = OO_GET(_area,StrongpointArea,Position) getDir _direction;
		};

		private _approachDirection = [_direction, _sweep];
		OO_SET(_garrison,ForceCategory,CallupDirection,_approachDirection);
	};

	if (_transportParameter select 0 == 0) then
	{
		private _transportName = _transportParameter select 2;

		private _transports = OO_GET(_mission,Strongpoint,Categories) select { (["Name"] call OO_METHOD(_x,Category,GetTagValue)) find _transportName != -1 } select { OO_INSTANCE_ISOFCLASS(_x,TransportCategory) };
		if (count _transports == 0) exitWith { [format ["The operation does not contain a transport called '%1'", _transportName]] call SPM_Util_MessageCaller };
		if (count _transports > 1) exitWith { [format ["'%1' is an ambiguous transport name", _transportName]] call SPM_Util_MessageCaller };

		private _transport = _transports select 0;
		OO_SET(_garrison,InfantryGarrisonCategory,Transport,_transport);
	};

	if (_relocateParameter select 0 == 0) then
	{
		private _relocate = _relocateParameter select 2;
		OO_SET(_garrison,InfantryGarrisonCategory,RelocateProbability,_relocate);
	};

	[OP_COMMAND_RESULT_MATCHED]
};

OP_COMMAND__OperationSetCheckpoints_Usage =
[
	"set checkpoints name",
	[
		["-coverage", false, true, "#DIRECTION"]
	]
];

OO_TRACE_DECL(OP_COMMAND__OperationSetCheckpoints) =
{
	params ["_commandWords"];

	private _name = _commandWords select 0;

	if (_name find "-" == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationSetCheckpoints_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _parameters = [_commandWords, OP_COMMAND__OperationSetCheckpoints_Usage] call OP_COMMAND_ParseParameters;
	if ({ _x select 0 == -1 } count _parameters > 0) exitWith { [OP_COMMAND_RESULT_MATCHED] };
	if ({ _x select 0 >= 0 } count _parameters == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationSetCheckpoints_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _mission = call OP_GetMission;

	if (OO_ISNULL(_mission)) exitWith { [OP_COMMAND_RESULT_MATCHED] };

	private _categories = OO_GET(_mission,Strongpoint,Categories) select { (["Name"] call OO_METHOD(_x,Category,GetTagValue)) find _name != -1 } select { OO_INSTANCE_ISOFCLASS(_x,CheckpointsCategory) };
	if (count _categories == 0) exitWith { [format ["The operation does not contain a checkpoints called '%1'", _name]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };
	if (count _categories > 1) exitWith { [format ["'%1' is an ambiguous checkpoints name", _name]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _checkpoints = _categories select 0;

	private _coverageParameter = [_parameters, "-coverage"] call OP_COMMAND_GetParsedParameter;

	if (_coverageParameter select 0 == 0) then
	{
		private _coverage = _coverageParameter select 2;

		private _direction = _coverage select 0;
		private _sweep = _coverage select 1;

		if (_direction isEqualType []) then
		{
			private _area = OO_GET(_checkpoints,ForceCategory,Area);
			_direction = OO_GET(_area,StrongpointArea,Position) getDir _direction;
		};

		private _coverageDirection = [_direction, _sweep];
		OO_SET(_checkpoints,CheckpointsCategory,Coverage,_coverageDirection);
	};

	[OP_COMMAND_RESULT_MATCHED]
};

OP_COMMAND__OperationSetCars_Usage =
[
	"set cars name",
	[
		["-ownership", false, true, "SCALAR"]
	]
];

OO_TRACE_DECL(OP_COMMAND__OperationSetCars) =
{
	params ["_commandWords"];

	private _name = _commandWords select 0;

	if (_name find "-" == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationSetCars_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _parameters = [_commandWords, OP_COMMAND__OperationSetCars_Usage] call OP_COMMAND_ParseParameters;
	if ({ _x select 0 == -1 } count _parameters > 0) exitWith { [OP_COMMAND_RESULT_MATCHED] };
	if ({ _x select 0 >= 0 } count _parameters == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationSetCars_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _mission = call OP_GetMission;

	if (OO_ISNULL(_mission)) exitWith { [OP_COMMAND_RESULT_MATCHED] };

	private _categories = OO_GET(_mission,Strongpoint,Categories) select { (["Name"] call OO_METHOD(_x,Category,GetTagValue)) find _name != -1 } select { OO_INSTANCE_ISOFCLASS(_x,CivilianVehiclesCategory) };

	if (count _categories == 0) exitWith { [format ["The operation does not contain cars called '%1'", _name]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };
	if (count _categories > 1) exitWith { [format ["'%1' is an ambiguous cars name", _name]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _cars = _categories select 0;

	private _ownershipParameter = [_parameters, "-ownership"] call OP_COMMAND_GetParsedParameter;

	if (_ownershipParameter select 0 == 0) then
	{
		private _ownership = _ownershipParameter select 2;
		OO_SET(_cars,CivilianVehiclesCategory,OwnershipRate,_ownership);
	};

	[OP_COMMAND_RESULT_MATCHED]
};

OO_TRACE_DECL(SPM_Command_OperationSetArmorSide) =
{
	params ["_armor", "_side"];

	switch (_side) do
	{
		case "csat":
		{
			OO_SET(_armor,ForceCategory,SideEast,east);
		};

		case "civilian":
		{
			OO_SET(_armor,ForceCategory,SideEast,civilian);
		};

		case "syndikat":
		{
			OO_SET(_armor,ForceCategory,SideEast,independent);
		};
	};
};

OP_COMMAND__OperationSetArmor_Usage =
[
	"set armor name",
	[
		["-initial", false, true, "SCALAR"],
		["-maintain", false, true, "SCALAR"],
		["-reserves", false, true, "SCALAR"],
		["-proximity", false, true, "SCALAR"],
		["-patrol", false, true, "STRING", nil, ["area", "target"]],
		["-skill", false, true, "SCALAR"],
		["-difficulty", false, true, "SCALAR"],
		["-side", false, true, "STRING", nil, SPM_Command_OperationSides],
		["-update", false, true, "#RANGE"],
		["-retire", false, true, "STRING", nil, ["true", "false"]],
		["-approach", false, true, "#DIRECTION"],
		["-preplaced", false, true, "STRING", nil, ["true", "false"]]
	]
];

OO_TRACE_DECL(OP_COMMAND__OperationSetArmor) =
{
	params ["_commandWords"];

	private _name = _commandWords select 0;

	if (_name find "-" == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationSetArmor_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _parameters = [_commandWords, OP_COMMAND__OperationSetArmor_Usage] call OP_COMMAND_ParseParameters;
	if ({ _x select 0 == -1 } count _parameters > 0) exitWith { [OP_COMMAND_RESULT_MATCHED] };
	if ({ _x select 0 >= 0 } count _parameters == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationSetArmor_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _mission = call OP_GetMission;

	if (OO_ISNULL(_mission)) exitWith { [OP_COMMAND_RESULT_MATCHED] };

	private _categories = OO_GET(_mission,Strongpoint,Categories) select { (["Name"] call OO_METHOD(_x,Category,GetTagValue)) find _name != -1 } select { OO_INSTANCE_ISOFCLASS(_x,ArmorCategory) };

	if (count _categories == 0) exitWith { [format ["The operation does not contain armor called '%1'", _name]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };
	if (count _categories > 1) exitWith { [format ["'%1' is an ambiguous armor name", _name]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _armor = _categories select 0;

	private _initialParameter = [_parameters, "-initial"] call OP_COMMAND_GetParsedParameter;
	private _maintainParameter = [_parameters, "-maintain"] call OP_COMMAND_GetParsedParameter;
	private _reservesParameter = [_parameters, "-reserves"] call OP_COMMAND_GetParsedParameter;
	private _proximityParameter = [_parameters, "-proximity"] call OP_COMMAND_GetParsedParameter;
	private _patrolParameter = [_parameters, "-patrol"] call OP_COMMAND_GetParsedParameter;
	private _skillParameter = [_parameters, "-skill"] call OP_COMMAND_GetParsedParameter;
	private _difficultyParameter = [_parameters, "-difficulty"] call OP_COMMAND_GetParsedParameter;
	private _sideParameter = [_parameters, "-side"] call OP_COMMAND_GetParsedParameter;
	private _updateParameter = [_parameters, "-update"] call OP_COMMAND_GetParsedParameter;
	private _retireParameter = [_parameters, "-retire"] call OP_COMMAND_GetParsedParameter;
	private _approachParameter = [_parameters, "-approach"] call OP_COMMAND_GetParsedParameter;
	private _preplacedParameter = [_parameters, "-preplaced"] call OP_COMMAND_GetParsedParameter;

	private _ratingsWest = OO_GET(_armor,ForceCategory,RatingsWest);
	private _totalRatingWest = 0; { _totalRatingWest = _totalRatingWest + (_x select 1 select 0) * (_x select 1 select 1) } forEach _ratingsWest;

	if (_totalRatingWest == 0 && ((_initialParameter select 0 == 0) || (_maintainParameter select 0 == 0))) exitWith { ["set vehicles: Neither -initial nor -maintain may be specified before vehicle types have been added."] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	if (_initialParameter select 0 == 0) then
	{
		private _force = [_initialParameter select 2, _totalRatingWest / count _ratingsWest] call SPM_ForceRating_CreateForce;
		OO_SET(_armor,ForceCategory,InitialMinimumWestForce,_force);
	};

	if (_maintainParameter select 0 == 0) then
	{
		private _force = [_maintainParameter select 2, _totalRatingWest / count _ratingsWest] call SPM_ForceRating_CreateForce;
		OO_SET(_armor,ForceCategory,MinimumWestForce,_force);
	};

	if (_reservesParameter select 0 == 0) then
	{
		private _reserves = _reservesParameter select 2;
		OO_SET(_armor,ForceCategory,Reserves,_reserves);
	};

	if (_proximityParameter select 0 == 0) then
	{
		private _proximity = _proximityParameter select 2;
		OO_SET(_armor,ForceCategory,RangeWest,_proximity);
	};

	if (_patrolParameter select 0 == 0) then
	{
		private _patrol = _patrolParameter select 2;
		OO_SET(_armor,ArmorCategory,PatrolType,_patrol);
	};

	if (_skillParameter select 0 == 0) then
	{
		private _skill = _skillParameter select 2;
		OO_SET(_armor,ForceCategory,SkillLevel,_skill);
	};

	if (_difficultyParameter select 0 == 0) then
	{
		private _difficulty = _difficultyParameter select 2;
		OO_SET(_armor,ForceCategory,DifficultyLevel,_difficulty);
	};

	if (_sideParameter select 0 == 0) then
	{
		private _side = _sideParameter select 2;
		[_armor, _side] call SPM_Command_OperationSetArmorSide;
	};

	if (_updateParameter select 0 == 0) then
	{
		private _update = _updateParameter select 2;
		private _remainingTime = OO_GET(_armor,ArmorCategory,_CallupTime) - diag_tickTime;
		if (_remainingTime > _update select 1) then // If the ArmorCategory's next update is beyond our maximum time, generate a new _CallupTime
		{
			private _callupTime = diag_tickTime + (_update select 0) + (random ((_update select 1) - (_update select 0)));
			OO_SET(_armor,ArmorCategory,_CallupTime,_callupTime);
		};
		OO_SET(_armor,ArmorCategory,CallupInterval,_update);
	};

	if (_retireParameter select 0 == 0) then
	{
		private _retire = (_retireParameter select 2) == "true";
		OO_SET(_armor,ForceCategory,UnitsCanRetire,_retire);
	};

	if (_approachParameter select 0 == 0) then
	{
		private _approach = _approachParameter select 2;

		private _direction = _approach select 0;
		private _sweep = _approach select 1;

		if (_direction isEqualType []) then
		{
			private _area = OO_GET(_armor,ForceCategory,Area);
			_direction = OO_GET(_area,StrongpointArea,Position) getDir _direction;
		};

		private _approachDirection = [_direction, _sweep];
		OO_SET(_armor,ForceCategory,CallupDirection,_approachDirection);
	};

	if (_preplacedParameter select 0 == 0) then
	{
		private _preplaced = (_preplacedParameter select 2) == "true";
		OO_SET(_armor,ArmorCategory,UsePreplacedEquipment,_preplaced);
	};

	[OP_COMMAND_RESULT_MATCHED]
};

OP_COMMAND__OperationSetMortar_Usage =
[
	"set mortar name",
	[
		["-update", false, true, "#RANGE"]
	]
];

OO_TRACE_DECL(OP_COMMAND__OperationSetMortar) =
{
	params ["_commandWords"];

	private _name = _commandWords select 0;

	if (_name find "-" == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationSetMortar_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _parameters = [_commandWords, OP_COMMAND__OperationSetMortar_Usage] call OP_COMMAND_ParseParameters;
	if ({ _x select 0 == -1 } count _parameters > 0) exitWith { [OP_COMMAND_RESULT_MATCHED] };
	if ({ _x select 0 >= 0 } count _parameters == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationSetMortar_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _mission = call OP_GetMission;

	if (OO_ISNULL(_mission)) exitWith { [OP_COMMAND_RESULT_MATCHED] };

	private _categories = OO_GET(_mission,Strongpoint,Categories) select { (["Name"] call OO_METHOD(_x,Category,GetTagValue)) find _name != -1 } select { OO_INSTANCE_ISOFCLASS(_x,MortarCategory) };

	if (count _categories == 0) exitWith { [format ["The operation does not contain a mortar called '%1'", _name]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };
	if (count _categories > 1) exitWith { [format ["'%1' is an ambiguous mortar name", _name]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _mortar = _categories select 0;

	private _updateParameter = [_parameters, "-update"] call OP_COMMAND_GetParsedParameter;

	if (_updateParameter select 0 == 0) then
	{
		private _update = _updateParameter select 2;
		private _remainingTime = OO_GET(_mortar,Category,UpdateTime) - diag_tickTime;
		if (_remainingTime > _update select 1) then // If the MortarCategory's next update is beyond our maximum time, generate a new UpdateTime
		{
			private _updateTime = diag_tickTime + (_update select 0) + (random ((_update select 1) - (_update select 0)));
			OO_SET(_mortar,Category,UpdateTime,_updateTime);
		};
		private _getUpdateInterval = compile format ["%1 + random %2", _update select 0, (_update select 1) - (_update select 0)];
		OO_SET(_mortar,MortarCategory,GetUpdateInterval,_getUpdateInterval);
	};

	[OP_COMMAND_RESULT_MATCHED]
};

OO_TRACE_DECL(OP_COMMAND__OperationSet) =
{
	params ["_commandWords"];

	private _commands =
	[
		["garrison", OP_COMMAND__OperationSetGarrison],
		["checkpoints", OP_COMMAND__OperationSetCheckpoints],
		["cars", OP_COMMAND__OperationSetCars],
		["armor", OP_COMMAND__OperationSetArmor],
		["mortar", OP_COMMAND__OperationSetMortar]
	];

	private _match = [_commandWords select 0, _commands] call OP_COMMAND_Match;

	if (_match select 0 < 0) exitWith { _match };

	private _command = _match select 1;

	[_commandWords select [1, 1e3]] call (_command select 1);
};

OP_COMMAND__OperationSpawnArmor_Usage =
[
	"spawn armor name",
	[
		["-type", true, true, "STRING"]
	]
];

OO_TRACE_DECL(OP_COMMAND__OperationSpawnArmor) =
{
	params ["_commandWords"];

	private _name = _commandWords select 0;

	if (_name find "-" == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationSpawnArmor_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _parameters = [_commandWords, OP_COMMAND__OperationSpawnArmor_Usage] call OP_COMMAND_ParseParameters;
	if ({ _x select 0 == -1 } count _parameters > 0) exitWith { [OP_COMMAND_RESULT_MATCHED] };
	if ({ _x select 0 >= 0 } count _parameters == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationSpawnArmor_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _mission = call OP_GetMission;

	if (OO_ISNULL(_mission)) exitWith { [OP_COMMAND_RESULT_MATCHED] };

	private _categories = OO_GET(_mission,Strongpoint,Categories) select { (["Name"] call OO_METHOD(_x,Category,GetTagValue)) find _name != -1 } select { OO_INSTANCE_ISOFCLASS(_x,ArmorCategory) };

	if (count _categories == 0) exitWith { [format ["The operation does not contain a armor called '%1'", _name]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };
	if (count _categories > 1) exitWith { [format ["'%1' is an ambiguous armor name", _name]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _armor = _categories select 0;

	private _typeParameter = [_parameters, "-type"] call OP_COMMAND_GetParsedParameter;

	if (_typeParameter select 0 == 0) then
	{
		private _type = _typeParameter select 2;

		private _matches = [];
		{
			private _callupType = _x select 0;
			if (_callupType find _type >= 0 || { ([_callupType] call JB_fnc_displayName) find _type >= 0 }) then { _matches pushBack _x };
		} forEach OO_GET(_armor,ForceCategory,CallupsEast);

		switch (true) do
		{
			case (count _matches == 0): { [format ["The name '%1' does not match any vehicle types in armor unit '%2'", _type, _name]] call SPM_Util_MessageCaller };
			case (count _matches > 1): { [format ["The name '%1' matches multiple vehicle types in armor unit '%2'", _type, _name]] call SPM_Util_MessageCaller };
			default
			{
				private _area = OO_GET(_armor,ForceCategory,Area);
				private _center = OO_GET(_area,StrongpointArea,Position);
				private _radius = OO_GET(_area,StrongpointArea,OuterRadius);
				[[_center, _radius] call SPM_Util_RandomPosition, 0, (_matches select 0) select 0] call OO_METHOD(_armor,ArmorCategory,CreateUnit);
			};
		};
	};

	[OP_COMMAND_RESULT_MATCHED]
};

OO_TRACE_DECL(OP_COMMAND__OperationSpawn) =
{
	params ["_commandWords"];

	private _commands =
	[
		["armor", OP_COMMAND__OperationSpawnArmor]
	];

	private _match = [_commandWords select 0, _commands] call OP_COMMAND_Match;

	if (_match select 0 < 0) exitWith { _match };

	private _command = _match select 1;

	[_commandWords select [1, 1e3]] call (_command select 1);
};

OP_COMMAND__OperationShowAll_Usage =
[
	"show all",
	[
	]
];

OO_TRACE_DECL(OP_COMMAND__OperationShowAll) =
{
	params ["_commandWords"];

	private _caller = [remoteExecutedOwner] call SPM_Util_GetOwnerPlayer;

	if (not (_caller in OP_MissionControllersMonitoringKnownOperations)) then
	{
		OP_MissionControllersMonitoringKnownOperations pushBack _caller;
		[OP_KnownOperations] remoteExec ["OP_C_SetKnownOperations", _caller];
	};

	[OP_COMMAND_RESULT_MATCHED]
};

OO_TRACE_DECL(OP_COMMAND__OperationShow) =
{
	params ["_commandWords"];

	private _commands =
	[
		["all", OP_COMMAND__OperationShowAll]
	];

	private _match = [_commandWords select 0, _commands] call OP_COMMAND_Match;

	if (_match select 0 < 0) exitWith { _match };

	private _command = _match select 1;

	[_commandWords select [1, 1e3]] call (_command select 1);
};

OP_COMMAND__OperationHideAll_Usage =
[
	"hide all",
	[
	]
];

OO_TRACE_DECL(OP_COMMAND__OperationHideAll) =
{
	params ["_commandWords"];

	private _caller = [remoteExecutedOwner] call SPM_Util_GetOwnerPlayer;

	if (not (_caller in OP_MissionControllersMonitoringKnownOperations)) exitWith {};

	OP_MissionControllersMonitoringKnownOperations = OP_MissionControllersMonitoringKnownOperations - [_caller];
	[[]] remoteExec ["OP_C_SetKnownOperations", _caller];

	[OP_COMMAND_RESULT_MATCHED]
};

OO_TRACE_DECL(OP_COMMAND__OperationHide) =
{
	params ["_commandWords"];

	private _commands =
	[
		["all", OP_COMMAND__OperationHideAll]
	];

	private _match = [_commandWords select 0, _commands] call OP_COMMAND_Match;

	if (_match select 0 < 0) exitWith { _match };

	private _command = _match select 1;

	[_commandWords select [1, 1e3]] call (_command select 1);
};

OP_COMMAND__OperationSelect_Usage =
[
	"select",
	[
		["-name", false, true, "STRING"],
		["-area", false, true, "#AREA"]
	]
];

OO_TRACE_DECL(OP_COMMAND__OperationSelect) =
{
	params ["_commandWords"];

	private _parameters = [_commandWords, OP_COMMAND__OperationSelect_Usage] call OP_COMMAND_ParseParameters;
	if ({ _x select 0 == -1 } count _parameters > 0) exitWith { [OP_COMMAND_RESULT_MATCHED] };
	if ({ _x select 0 >= 0 } count _parameters == 0) exitWith { [format ["Usage: %1", [OP_COMMAND__OperationSelect_Usage] call OP_COMMAND_UsageDescription]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	private _areaParameter = [_parameters, "-area"] call OP_COMMAND_GetParsedParameter;
	private _nameParameter = [_parameters, "-name"] call OP_COMMAND_GetParsedParameter;

	private _count = { _x } count [_areaParameter select 0 == 0, _nameParameter select 0 == 0];
	if (_count == 0) exitWith { ["select: either -area or -name must be specified"] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };
	if (_count == 2) exitWith { ["select: only one of -area or -name may be specified"] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

	if (_areaParameter select 0 == 0) then
	{
		private _area = _areaParameter select 2;

		private _selection = [OO_NULL, [_area select 0, _area select 1, 0], _area select 2, "", if (isServer) then { objNull } else { player }];
		[_selection] remoteExec ["OP_C_SetSelection", remoteExecutedOwner];
	};

	if (_nameParameter select 0 == 0) then
	{
		private _name = _nameParameter select 2;
		private _missions = [];
		private _code =
			{
				if (OO_GET(_x,Strongpoint,Name) find _name >= 0) then { _missions pushBack _x };
				false
			};
		OO_FOREACHINSTANCE(Mission,[],_code);

		if (count _missions == 0) exitWith { [format ["There is no operation called '%1'", _name]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };
		if (count _missions > 1) exitWith { [format ["'%1' is an ambiguous operation name", _name]] call SPM_Util_MessageCaller; [OP_COMMAND_RESULT_MATCHED] };

		private _mission = _missions select 0;
		private _selection = [OO_REFERENCE(_mission), OO_GET(_mission,Strongpoint,Position), OO_GET(_mission,Strongpoint,ActivityRadius), OO_GET(_mission,Strongpoint,Name), if (isServer) then { objNull } else { player }];
		[_selection] remoteExec ["OP_C_SetSelection", remoteExecutedOwner];
	};

	[OP_COMMAND_RESULT_MATCHED]
};

OO_TRACE_DECL(OP_COMMAND__Operation) =
{
	params ["_commandWords"];

	private _commands =
	[
		["start", OP_COMMAND__OperationStart],
		["surrender", OP_COMMAND__OperationSurrender],
		["stop", OP_COMMAND__OperationStop],
		["rename", OP_COMMAND__OperationRename],
		["create", OP_COMMAND__OperationCreate],
		["delete", OP_COMMAND__OperationDelete],
		["add", OP_COMMAND__OperationAdd],
		["set", OP_COMMAND__OperationSet],
		["show", OP_COMMAND__OperationShow],
		["hide", OP_COMMAND__OperationHide],
		["select", OP_COMMAND__OperationSelect],
		["spawn", OP_COMMAND__OperationSpawn]
	];

	private _match = [_commandWords select 0, _commands] call OP_COMMAND_Match;

	if (_match select 0 < 0) exitWith { _match };

	private _command = _match select 1;

	[_commandWords select [1, 1e3]] call (_command select 1);
};
