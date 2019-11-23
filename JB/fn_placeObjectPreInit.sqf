#include "\a3\editor_f\Data\Scripts\dikCodes.h"

JB_PO_MAX_INTERACTION_RANGE = 50;
JB_PO_CONFIGURATION_NULL = [0,-1e30,[]];
JB_PO_RESOURCES_NULL = [0];
JB_PO_OBJECT_NULL = ["",objNull];
JB_PO_STEP_ANGLE_MULTIPLIER = 5;
JB_PO_ACTION_CONFIRM = "action";
JB_PO_ACTION_CANCEL = "closeContext";
JB_PO_ACTION_ROTATELEFT = "nextAction";
JB_PO_ACTION_ROTATERIGHT = "prevAction";

JB_PO_TYPE_NAME = 0;
JB_PO_TYPE_CLASS = 1;
JB_PO_TYPE_COST = 2;
JB_PO_TYPE_LOAD = 3;
JB_PO_TYPE_LOADPASSTHROUGH = 4;
JB_PO_TYPE_STORE = 5;
JB_PO_TYPE_STOREPASSTHROUGH = 6;

JB_PO_OBJECT_OBJECT = 0;
JB_PO_OBJECT_SIZE = 1;
JB_PO_OBJECT_ROTATION = 2;
JB_PO_OBJECT_TYPE = 3;
JB_PO_OBJECT_SOURCE = 4;
JB_PO_OBJECT_HANDLER_EF = 5;
JB_PO_OBJECT_HANDLER_CONFIRM = 6;
JB_PO_OBJECT_HANDLER_CANCEL = 7;
JB_PO_OBJECT_HANDLER_RL = 8;
JB_PO_OBJECT_HANDLER_RR = 9;
JB_PO_OBJECT_SIMULATION = 10;

// Source has the following variables:
// JB_PO_Configuration: [storage-capacity, interaction-range, supported-type-names]
// JB_PO_Resources: [current-capacity]

// Player has the following variables:
// JB_PO_ObjectBeingPlaced: [object-being-placed, radius-of-object, rotation-of-object, eachframe-handler-index, buttondown-handler-index, mousewheel-handler-index, type, source]

// Objects have the following variables:
// JB_PO_Object: [type-name]

// Type [type-name, type, type-cost, initializer, initializer-passthrough, destructor, destructor-passthrough]
JB_PO_Types = [];

JB_PO_C_RegisterTypes =
{
	params ["_types"];

	private _type = [];
	private _newTypes = _types select { _type = _x; JB_PO_Types findIf { (_type select JB_PO_TYPE_NAME) == (_x select 0) } == -1 };
	JB_PO_Types append _newTypes;
};

JB_PO_CreateType =
{
	params ["_name", "_class", "_cost", "_load", "_loadPassthrough", "_store", "_storePassthrough"];

	if (_class isEqualType "") then { _class = [_class, getText (configFile >> "CfgVehicles" >> _class >> "displayName")] };

	private _type = [];
	_type set [JB_PO_TYPE_NAME, _name];
	_type set [JB_PO_TYPE_CLASS, _class];
	_type set [JB_PO_TYPE_COST, _cost];
	_type set [JB_PO_TYPE_LOAD, _load];
	_type set [JB_PO_TYPE_LOADPASSTHROUGH, _loadPassthrough];
	_type set [JB_PO_TYPE_STORE, _store];
	_type set [JB_PO_TYPE_STOREPASSTHROUGH, _storePassthrough];

	_type
};

JB_PO_RegisterTypes =
{
	[_this select 0] remoteExec ["JB_PO_C_RegisterTypes", 0, true]; //JIP
};

JB_PO_InitializeSource =
{
	params ["_source", "_range", "_capacity", "_typeNames"];

	_range = _range min JB_PO_MAX_INTERACTION_RANGE;

	_source setVariable ["JB_PO_Configuration", [_capacity, _range, _typeNames], true]; //JIP
	_source setVariable ["JB_PO_Resources", [_capacity], true]; //JIP
};

JB_PO_IsTemporaryObject =
{
	params ["_object"];

	_object getVariable ["JB_PO_Temporary", false]
};

JB_PO_SetSourceResources =
{
	params ["_source", "_resources"];

	_source setVariable ["JB_PO_Resources", +_resources, true]; //JIP
};

JB_PO_GetSourceResources =
{
	params ["_source"];

	+(_source getVariable "JB_PO_Resources")
};

JB_PO_SourceIsInRange =
{
	params ["_source", "_position"];

	if (not alive _source) exitWith { false };

	[_source worldToModel _position, boundingBoxReal _source] call JB_fnc_distanceToBoundingBox < ((_source getVariable ["JB_PO_Configuration", JB_PO_CONFIGURATION_NULL]) select 1)
};

JB_PO_SourcesInRange =
{
	params ["_position"];

	private _candidates = (_position nearEntities JB_PO_MAX_INTERACTION_RANGE) select { [_x, _position] call JB_PO_SourceIsInRange };
	
	_candidates select { speed _x < 0.1 }
};

JB_PO_CurrentMessage = [];

JB_PO_ShowMessage =
{
	params ["_message"];

	if (_message isEqualTo JB_PO_CurrentMessage) exitWith {};

	if (count _message == 0 && count JB_PO_CurrentMessage != 0) then
	{
		titleFadeOut 0;
	};

	JB_PO_CurrentMessage = +_message;

	if (count _message != 0) then
	{
		[_message] spawn
		{
			params ["_message"];

			titleText [_message joinString "\n", "plain down", 0.3];
			sleep 4;
			if (JB_PO_CurrentMessage isEqualTo _message) then { JB_PO_CurrentMessage = [] };
		};
	};
};

JB_PO_SourceCanStoreType =
{
	params ["_source", "_typeName"];

	// If not known typeName, false
	private _typeIndex = JB_PO_Types findIf { _x select 0 == _typeName };
	if (_typeIndex == -1) exitWith { false };

	private _configuration = _source getVariable ["JB_PO_Configuration", JB_PO_CONFIGURATION_NULL];
	private _typeNames = _configuration select 2;

	// If source doesn't provide the typeName, false
	if (not (_typeName in _typeNames)) exitWith { false };

	private _type = JB_PO_Types select _typeIndex;

	private _resources = _source getVariable ["JB_PO_Resources", JB_PO_RESOURCES_NULL];

	// Final answer is based on whether the source has room to store the type's cost
	(_resources select 0) + (_type select JB_PO_TYPE_COST) <= (_configuration select 0)
};

JB_PO_SourceCanPlaceType =
{
	params ["_source", "_typeName"];

	// If not known typeName, false
	private _typeIndex = JB_PO_Types findIf { _x select 0 == _typeName };
	if (_typeIndex == -1) exitWith { false };

	private _configuration = _source getVariable ["JB_PO_Configuration", JB_PO_CONFIGURATION_NULL];
	private _typeNames = _configuration select 2;

	// If source doesn't provide the typeName, false
	if (not (_typeName in _typeNames)) exitWith { false };

	private _type = JB_PO_Types select _typeIndex;

	private _resources = _source getVariable ["JB_PO_Resources", JB_PO_RESOURCES_NULL];

	// Final answer is based on whether the source has resources to place the type
	(_resources select 0) >= (_type select JB_PO_TYPE_COST)
};

JB_PO_ClosestSource =
{
	params ["_position", "_criteria", "_passthrough"];

	private _candidates = [_position] call JB_PO_SourcesInRange;

	if (not isNil "_criteria") then
	{
		_candidates = _candidates select { [_x, _passthrough] call _criteria };
	};

	if (count _candidates == 0) exitWith { objNull };

	// Get the closest source
	_candidates = _candidates apply { [player distance _x, _x] };
	_candidates sort true;

	_candidates select 0 select 1
};

JB_PO_StartPlacement =
{
	params ["_typeName"];

	private _source = player getVariable "JB_PO_SelectedSource";
	[_source, _typeName] remoteExec ["JB_PO_S_RequestDebit", 2];
};

JB_PO_PlaceObject_Cleanup =
{
	private _parameters = +(player getVariable "JB_PO_ObjectBeingPlaced");
	player setVariable ["JB_PO_ObjectBeingPlaced", nil];

	removeMissionEventHandler ["EachFrame", _parameters select JB_PO_OBJECT_HANDLER_EF];
	[46, _parameters select JB_PO_OBJECT_HANDLER_CONFIRM] call JB_fnc_actionHandlerRemove;
	[46, _parameters select JB_PO_OBJECT_HANDLER_CANCEL] call JB_fnc_actionHandlerRemove;
	[46, _parameters select JB_PO_OBJECT_HANDLER_RL] call JB_fnc_actionHandlerRemove;
	[46, _parameters select JB_PO_OBJECT_HANDLER_RR] call JB_fnc_actionHandlerRemove;

	call CLIENT_EnableActionMenu;
};

JB_PO_IntersectingNeighbor =
{
	params ["_object", "_size", "_position", "_direction", "_onlySimulated"];

	_size = _size + 20;

	private _objects = [];
	if (_onlySimulated) then
	{
		_objects = (_position nearEntities _size) - [_object, player] - attachedObjects _object;
	}
	else
	{
		private _terrainObjects = nearestTerrainObjects [_position, ["tree", "small tree", "wall", "fence", "rock", "hide"], _size];

		private _nearObjects = (_position nearObjects _size) select { typeOf _x find "#" == -1 };
		_nearObjects = _nearObjects select { not (getText (configFile >> "CfgVehicles" >> typeOf _x >> "simulation") == "") };

		_objects = _terrainObjects + (_nearobjects - [_object, player] - attachedObjects _object);
	};

	_object hideObject true;
	_object setDir _direction;
	_object setPosATL _position;
	_object setVectorUp (surfaceNormal _position);

	private _intersectingIndex = _objects findIf { [_object, _x] call JB_fnc_objectBoundsIntersect };

	// The whole "current placement" nonsense exists because (_object setPosATL (getPosATL _object)) will move an object a small amount.  Various objects will
	// then drift away if we keep doing that over and over again.  So "current placement" exists to provide stability.  The alternative is to use a different
	// local copy of the object that is always hidden and can be used to test possible placement locations.

	private _currentPlacement = _object getVariable "JB_PO_CurrentPlacement";

	_object setDir (_currentPlacement select 1);
	_object setPosATL (_currentPlacement select 0);
	_object setVectorUp (surfaceNormal (_currentPlacement select 0));
	_object hideObject false;

	if (_intersectingIndex == -1) exitWith { objNull };

	_objects select _intersectingIndex;
};

JB_PO_PlaceObject_EachFrame =
{
	if (vehicle player != player || not (lifeState player in ["HEALTHY", "INJURED"])) exitWith { call JB_PO_PlaceObject_Cancel };

	private _parameters = player getVariable "JB_PO_ObjectBeingPlaced";
	private _source = _parameters select JB_PO_OBJECT_SOURCE;

	private _messages = [];
	if (not ([_source, getPos player] call JB_PO_SourceIsInRange)) then { _messages pushBack format ["You are too far from the %1", getText (configFile >> "CfgVehicles" >> typeOf _source >> "displayName")] };

	private _object = _parameters select JB_PO_OBJECT_OBJECT;
	private _simulation = _parameters select JB_PO_OBJECT_SIMULATION;
	private _size = _parameters select JB_PO_OBJECT_SIZE;
	private _rotation = _parameters select JB_PO_OBJECT_ROTATION;

	private _direction = getDir player;
	private _position = getPosATL player;
	_position set [2, 0];
	_position = _position vectorAdd [sin _direction * _size, cos _direction * _size, 0];

	_direction = _direction + 180 + _rotation;

	private _update = true;
	private _neighbor = [_object, _size, _position, _direction, _simulation in ["house", ""]] call JB_PO_IntersectingNeighbor;

	if (not isNull _neighbor) then
	{
		_update = false;

		if ((toLower getText (configFile >> "CfgVehicles" >> typeOf _neighbor >> "simulation")) in ["thingx", "house", ""]) then
		{
			_messages pushBack format ["Ground clutter is blocking placement"]; 
		}
		else
		{
			_messages pushBack format ["A %1 is blocking placement", getText (configFile >> "CfgVehicles" >> typeOf _neighbor >> "displayName")]; 
		};
	};

	if (_update) then
	{
		_object setDir _direction;
		_object setPosATL _position;
		_object setVectorUp (surfaceNormal _position);
		_object setVariable ["JB_PO_CurrentPlacement", [_position, _direction]];
	};

	if (count _messages > 0) then { [_messages] call JB_PO_ShowMessage };
};

JB_PO_PlaceObject_Confirm =
{
	private _parameters = +(player getVariable "JB_PO_ObjectBeingPlaced");

	private _source = _parameters select JB_PO_OBJECT_SOURCE;

	private _messages = [];
	if (not ([_source, getPos player] call JB_PO_SourceIsInRange)) then { _messages pushBack format ["You are too far from the %1", getText (configFile >> "CfgVehicles" >> typeOf _source >> "displayName")] };

	private _object = _parameters select JB_PO_OBJECT_OBJECT;
	private _type = _parameters select JB_PO_OBJECT_TYPE;
	private _simulation = _parameters select JB_PO_OBJECT_SIMULATION;
	private _size = _parameters select JB_PO_OBJECT_SIZE;

	private _neighbor = [_object, _size, getPosATL _object, getDir _object, _simulation in ["thingx", "house", ""]] call JB_PO_IntersectingNeighbor;
	if (not isNull _neighbor) then { _messages pushBack format ["A %1 is blocking placement", getText (configFile >> "CfgVehicles" >> typeOf _neighbor >> "displayName")] };

	if (count _messages > 0) exitWith { [_messages] call JB_PO_ShowMessage };

	titleText [format ["%1 placed", _type select JB_PO_TYPE_CLASS select 1], "plain down", 0.2];

	call JB_PO_PlaceObject_Cleanup;

	private _final = createVehicle [_type select JB_PO_TYPE_CLASS select 0, call JB_MDI_RandomSpawnPosition, [], 0, "can_collide"];
	_final disableCollisionWith _object;

	[_source, _final, _type select JB_PO_TYPE_LOADPASSTHROUGH] call (_type select JB_PO_TYPE_LOAD);

	_final setVectorDirAndUp [vectorDir _object, vectorUp _object];
	_final setVariable ["JB_PO_Object", [_type select JB_PO_TYPE_NAME], true]; //JIP

	private _position = getPosATL _object;

	[_source, _object, _type select JB_PO_TYPE_STOREPASSTHROUGH] call (_type select JB_PO_TYPE_STORE);
	deleteVehicle _object;

	_final setPosATL _position;
};

JB_PO_PlaceObject_Cancel =
{
	private _parameters = +(player getVariable "JB_PO_ObjectBeingPlaced");

	titleText ["Placement canceled", "plain down", 0.2];

	call JB_PO_PlaceObject_Cleanup;

	private _object = _parameters select JB_PO_OBJECT_OBJECT;
	private _type = _parameters select JB_PO_OBJECT_TYPE;
	private _source = _parameters select JB_PO_OBJECT_SOURCE;

	// Pass objNull because the object is local
	[_source, objNull, _type select JB_PO_TYPE_NAME] remoteExec ["JB_PO_S_RequestCredit", 2];

	// Delete it regardless of whether we can actually get credit
	[_source, _object, _type select JB_PO_TYPE_STOREPASSTHROUGH] call (_type select JB_PO_TYPE_STORE);
	deleteVehicle _object;
};

JB_PO_PlaceObject_ActionHandler_Confirm =
{
	[] spawn JB_PO_PlaceObject_Confirm;

	true
};

JB_PO_PlaceObject_ActionHandler_Cancel =
{
	[] spawn JB_PO_PlaceObject_Cancel;

	true
};

JB_PO_PlaceObject_ActionHandler_Rotate =
{
	params ["_display", "_actionName", "_change", "_passthrough"];

	private _parameters = player getVariable "JB_PO_ObjectBeingPlaced";
	_parameters set [JB_PO_OBJECT_ROTATION, (_parameters select JB_PO_OBJECT_ROTATION) + (_change * _passthrough * JB_PO_STEP_ANGLE_MULTIPLIER)];

	true
};

JB_PO_ObjectSize =
{
	params ["_object"];

	private _boundingBox = boundingBoxReal _object;
	private _length = (_boundingBox select 1 select 0) - (_boundingBox select 0 select 0);
	private _width = (_boundingBox select 1 select 1) - (_boundingBox select 0 select 1);

	((_length max _width) / 2.0) + 2.0
};

JB_PO_C_ResponseDebit =
{
	params ["_source", "_typeName", "_problem"];

	if (_problem != "") exitWith { titleText [_problem, "plain down", 0.3] };

	private _type = JB_PO_Types select (JB_PO_Types findIf { (_x select 0) == _typeName });

	private _object = (_type select JB_PO_TYPE_CLASS select 0) createVehicleLocal call JB_MDI_RandomSpawnPosition;
	_object disableCollisionWith player;

	_object setVariable ["JB_PO_Temporary", true];
	_object setVariable ["JB_PO_CurrentPlacement", [getPosATL _object, getDir _object]];

	[_source, _object, _type select JB_PO_TYPE_LOADPASSTHROUGH] call (_type select JB_PO_TYPE_LOAD);

	private _size = [_object] call JB_PO_ObjectSize;
	private _simulation = toLower getText (configFile >> "CfgVehicles" >> typeOf _object >> "simulation");

	call CLIENT_DisableActionMenu;
	private _eachFrameHandler = addMissionEventHandler ["EachFrame", JB_PO_PlaceObject_EachFrame];
	private _confirmHandler = [46, JB_PO_ACTION_CONFIRM, JB_PO_PlaceObject_ActionHandler_Confirm] call JB_fnc_actionHandlerAdd;
	private _cancelHandler = [46, JB_PO_ACTION_CANCEL, JB_PO_PlaceObject_ActionHandler_Cancel] call JB_fnc_actionHandlerAdd;
	private _rotateLeftHandler = [46, JB_PO_ACTION_ROTATELEFT, JB_PO_PlaceObject_ActionHandler_Rotate, 1] call JB_fnc_actionHandlerAdd;
	private _rotateRightHandler = [46, JB_PO_ACTION_ROTATERIGHT, JB_PO_PlaceObject_ActionHandler_Rotate, -1] call JB_fnc_actionHandlerAdd;

	private _objectBeingPlaced = [];
	_objectBeingPlaced set [JB_PO_OBJECT_OBJECT, _object];
	_objectBeingPlaced set [JB_PO_OBJECT_SIZE, _size];
	_objectBeingPlaced set [JB_PO_OBJECT_ROTATION, 0];
	_objectBeingPlaced set [JB_PO_OBJECT_TYPE, _type];
	_objectBeingPlaced set [JB_PO_OBJECT_SOURCE, _source];
	_objectBeingPlaced set [JB_PO_OBJECT_HANDLER_EF, _eachFrameHandler];
	_objectBeingPlaced set [JB_PO_OBJECT_HANDLER_CONFIRM, _confirmHandler];
	_objectBeingPlaced set [JB_PO_OBJECT_HANDLER_CANCEL, _cancelHandler];
	_objectBeingPlaced set [JB_PO_OBJECT_HANDLER_RL, _rotateLeftHandler];
	_objectBeingPlaced set [JB_PO_OBJECT_HANDLER_RR, _rotateRightHandler];
	_objectBeingPlaced set [JB_PO_OBJECT_SIMULATION, _simulation];
	player setVariable ["JB_PO_ObjectBeingPlaced", _objectBeingPlaced];

	private _actionDescription =
	{
		params ["_keys", "_description"];

		_keys = _keys apply { ((keyName _x) splitString """") select 0 }; //ARMA: Do not use '"' notation for a quote character here because it will bug the ARMA parser

		if (count _keys == 1) exitWith { _description + " - " + (_keys select 0) + "\n" };

		private _exceptLast = (_keys select [0, count _keys - 1]) joinString ", ";

		_description + " - " + _exceptLast + " or " + (_keys select (count _keys - 1)) + "\n"
	};

	private _place = actionKeys JB_PO_ACTION_CONFIRM;
	private _cancel = actionKeys JB_PO_ACTION_CANCEL;
	private _rotateRight = actionKeys JB_PO_ACTION_ROTATELEFT;
	private _rotateLeft = actionKeys JB_PO_ACTION_ROTATERIGHT;

	titleText [([_place, "Place"] call _actionDescription) + ([_cancel, "Cancel"] call _actionDescription) + ([_rotateRight, "Rotate right"] call _actionDescription) + ([_rotateLeft, "Rotate left"] call _actionDescription), "plain down", 1];
};

JB_PO_C_ResponseCredit =
{
	params ["_source", "_object", "_problem"];

	if (_problem != "") exitWith { titleText [_problem, "plain down", 0.3] };

	if (isNull _object) exitWith {};

	private _data = _object getVariable ["JB_PO_Object", JB_PO_OBJECT_NULL];
	private _typeName = _data select 0;
	private _type = JB_PO_Types select (JB_PO_Types findIf { (_x select 0) == _typeName });
	
	[_source, _object, _type select JB_PO_TYPE_STOREPASSTHROUGH] call (_type select JB_PO_TYPE_STORE);
	deleteVehicle _object;
};

JB_PO_PlaceObjectCondition =
{
	if (vehicle player != player) exitWith { false };

	if (not (lifeState player in ["HEALTHY", "INJURED"])) exitWith { false };

	private _source = [getPos player] call JB_PO_ClosestSource;

	if (isNull _source) exitWith { false };

	private _sourceType = getText (configFile >> "CfgVehicles" >> typeOf _source >> "displayName");
	player setUserActionText [(player getVariable "JB_PO_Actions") select 0, format ["Place object from %1", _sourceType]];

	true
};

JB_PO_PlaceObject =
{
	JB_PO_Menu = [["Available objects", true]];

	private _source = [getPos player] call JB_PO_ClosestSource;
	private _resources = _source getVariable ["JB_PO_Resources", JB_PO_RESOURCES_NULL];
	private _configuration = _source getVariable ["JB_PO_Configuration", JB_PO_CONFIGURATION_NULL];
	private _types = _configuration select 2;
	private _typeName = "";
	private _type = -1;
	private _key = 1;
	{
		_typeName = _x;

		_key = _key + 1;
		_type = JB_PO_Types select (JB_PO_Types findIf { (_x select 0) == _typeName });

		JB_PO_Menu pushBack [format ["%2 (%1 points)", str (_type select JB_PO_TYPE_COST), _type select JB_PO_TYPE_CLASS select 1], [_key], "", -5, [["expression", format ["['%1'] call JB_PO_StartPlacement", _type select JB_PO_TYPE_NAME]]], "1", if (_type select JB_PO_TYPE_COST <= _resources select 0) then { "1" } else { "0" }];
	} forEach _types;

	player setVariable ["JB_PO_SelectedSource", _source];

	showCommandingMenu "";
	showCommandingMenu "#USER:JB_PO_Menu";
};

JB_PO_StoreObjectCondition =
{
	if (vehicle player != player) exitWith { false };

	if (not (lifeState player in ["HEALTHY", "INJURED"])) exitWith { false };

	// The 0.1 is to ensure that the player is within "Store" distance immediately after placing an object
	if ((player distance2D cursorObject) - 0.1 > ([cursorObject] call JB_PO_ObjectSize)) exitWith { false };

	private _data = cursorObject getVariable ["JB_PO_Object", JB_PO_OBJECT_NULL];
	if (_data select 0 == "") exitWith { false };

	private _source = [getPos player, JB_PO_SourceCanStoreType, _data select 0] call JB_PO_ClosestSource;
	if (isNull _source) exitWith { false };

	private _type = JB_PO_Types select (JB_PO_Types findIf { _x select JB_PO_TYPE_NAME == _data select 0 });

	private _sourceType = getText (configFile >> "CfgVehicles" >> typeOf _source >> "displayName");
	player setUserActionText [(player getVariable "JB_PO_Actions") select 1, format ["Store %1 into %2", _type select JB_PO_TYPE_CLASS select 1, _sourceType]];

	true
};

JB_PO_StoreObject =
{
	private _data = cursorObject getVariable ["JB_PO_Object", JB_PO_OBJECT_NULL];
	[[getPos player, JB_PO_SourceCanStoreType, _data select 0] call JB_PO_ClosestSource, cursorObject, _data select 0] remoteExec ["JB_PO_S_RequestCredit", 2];
};

JB_PO_InitializePlayer =
{
	params ["_placeAction", "_storeAction"];

	private _placeActionID = player addAction [_placeAction, { call JB_PO_PlaceObject }, [], 0, false, true, "", "call JB_PO_PlaceObjectCondition"];
	private _storeActionID = player addAction [_storeAction, { call JB_PO_StoreObject }, [], 0, false, true, "", "call JB_PO_StoreObjectCondition"];
	player setVariable ["JB_PO_Actions", [_placeActionID, _storeActionID]];
};

if (not isServer && hasInterface) exitWith {};

JB_PO_CS = call JB_fnc_criticalSectionCreate;

JB_PO_S_RequestDebit =
{
	params ["_source", "_typeName"];

	private _problem = "";
	private _type = JB_PO_Types select (JB_PO_Types findIf { (_x select 0) == _typeName });
	private _configuration = _source getVariable ["JB_PO_Configuration", JB_PO_CONFIGURATION_NULL];

	JB_PO_CS call JB_fnc_criticalSectionEnter;

		//TODO: Check to see that destination position is still in range of _source (need new parameter)

		private _resources = _source getVariable ["JB_PO_Resources", JB_PO_RESOURCES_NULL];
		if (_resources select 0 < _type select JB_PO_TYPE_COST) then
		{
			_problem = format ["Insufficient resources available in '%1' to create a '%2'", getText (configFile >> "CfgVehicles" >> typeOf _source >> "displayName"), _type select JB_PO_TYPE_CLASS select 1];
		}
		else
		{
			_resources set [0, (_resources select 0) - (_type select JB_PO_TYPE_COST)];
			_source setVariable ["JB_PO_Resources", _resources, true]; //JIP
		};

	JB_PO_CS call JB_fnc_criticalSectionLeave;

	[_source, _typeName, _problem] remoteExec ["JB_PO_C_ResponseDebit", remoteExecutedOwner];
};

JB_PO_S_RequestCredit =
{
	params ["_source", "_object", "_typeName"];

	private _problem = "";

	JB_PO_CS call JB_fnc_criticalSectionEnter;

		//TODO: Check to see that _object is within range of _source

		private _configuration = _source getVariable ["JB_PO_Configuration", JB_PO_CONFIGURATION_NULL];
		private _resources = _source getVariable ["JB_PO_Resources", JB_PO_RESOURCES_NULL];

		private _type = JB_PO_Types select (JB_PO_Types findIf { (_x select 0) == _typeName });
		private _cost = _type select JB_PO_TYPE_COST;

		if ((_resources select 0) + _cost > _configuration select 0) then
		{
			_problem = format ["Insufficient space available in the '%1' to store '%2'", getText (configFile >> "CfgVehicles" >> typeOf _source >> "displayName"), getText (configFile >> "CfgVehicles" >> _type select JB_PO_TYPE_NAME >> "displayName")];
		}
		else
		{
			_resources set [0, (_resources select 0) + _cost];
			_source setVariable ["JB_PO_Resources", _resources, true]; //JIP
		};

	JB_PO_CS call JB_fnc_criticalSectionLeave;

	[_source, _object, _problem] remoteExec ["JB_PO_C_ResponseCredit", remoteExecutedOwner];
};
