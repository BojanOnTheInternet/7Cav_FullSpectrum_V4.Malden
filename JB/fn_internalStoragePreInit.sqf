#include "..\OO\oo.h"

JB_IS_C_CONTAINER_OBJECTFILTER = 0;
JB_IS_C_CONTAINER_CANUNLOAD = 1;

JB_IS_IsContainer =
{
	params ["_container"];

	count (_container getVariable ["JB_IS_ClientData", []]) > 0
};

OO_TRACE_DECL(JB_IS_ContainerCanStoreObjectType) =
{
	params ["_container", "_objectType"];

	private _filter = [];

	if (count _filter == 0) then
	{
		private _data = _container getVariable ["JB_IS_ClientData", []];
		if (count _data > 0) then { _filter = _data select JB_IS_C_CONTAINER_OBJECTFILTER };
	};

	if (count _filter == 0) then
	{
		private _data = _container getVariable ["JB_IS_ServerData", []];
		if (count _data > 0) then { _filter = _data select JB_IS_S_CONTAINER_OBJECTFILTER };
	};

	if (count _filter == 0) exitWith { false };

	([_objectType, _filter] call JB_fnc_passesTypeFilter)
};

OO_TRACE_DECL(JB_IS_ObjectVolume) =
{
	params ["_object"];

	if (_object isEqualType []) exitWith { [_object select 0] call JB_fnc_objectVolume };

	[_object] call JB_fnc_objectVolume
};

JB_IS_GetNearestContainer =
{
	params ["_position", "_range"];

	private _nearbyContainers = (_position nearObjects 20) select { alive _x && { [_x] call JB_IS_IsContainer } };

	if (count _nearbyContainers == 0) exitWith { objNull };

	private _intersections = _nearbyContainers apply { [[_position, _x, _range] call JB_fnc_distanceToObjectSurface, _x] };

	_intersections = _intersections select { _x select 0 select 2 != -1 }; // Remove non-intersections
	if (count _intersections == 0) exitWith { objNull };

	_intersections = _intersections apply { [_x select 0 select 2, _x select 1] }; // Reduce to distance and object
	_intersections sort true;

	_intersections select 0 select 1
};

JB_IS_LoadSetUserActionText =
{
	params ["_item", "_container"];

	private _action = "Load";

	private _data = _container getVariable ["JB_IS_ClientData", []];
	if (not (_data select JB_IS_C_CONTAINER_CANUNLOAD)) then { _action = "Discard" };

	player setUserActionText [JB_IS_LoadAction, format ["%1 %2 into %3", _action, getText (configFile >> "CfgVehicles" >> typeOf _item >> "displayName"), getText (configFile >> "CfgVehicles" >> typeOf _container >> "displayName")]];
};

// Can the player's carried object be loaded into the cursorObject?
JB_IS_LoadCarriedCondition =
{
	params ["_target", "_carriedObject"];

	if (not ([_target] call JB_IS_IsContainer)) exitWith { false };

	[_carriedObject, _target] call JB_IS_LoadSetUserActionText;

	true
};

// Can the cursorObject can be loaded into a nearby container?
JB_IS_LoadNearbyCondition =
{
	params ["_target"];

	if (not ([_target, player] call JB_CO_ObjectCanBeCarried)) exitWith { false };

	private _nearestContainer = [ASLtoAGL eyePos player, 5.0] call JB_IS_GetNearestContainer;

	if (isNull _nearestContainer) exitWith { false };

	[_target, _nearestContainer] call JB_IS_LoadSetUserActionText;

	true
};

JB_IS_LoadCondition =
{
	params ["_target"];

	if (vehicle player != player) exitWith { false };
	
	if (not (lifeState player in ["HEALTHY", "INJURED"])) exitWith { false };

	if (isNull _target) exitWith { false };

	private _carriedObject = [player] call JB_CO_CarriedObject;
	if (isNull _carriedObject) exitWith { [_target] call JB_IS_LoadNearbyCondition };

	[_target, _carriedObject] call JB_IS_LoadCarriedCondition
};

OO_TRACE_DECL(JB_IS_Load) =
{
	params ["_target"];

	private _carriedObject = [player] call JB_CO_CarriedObject;

	if (not isNull _carriedObject) exitWith
	{
		if (not ([_target, typeOf _carriedObject] call JB_IS_ContainerCanStoreObjectType)) then
		{
			titleText [format ["The %1 will not accept a %2", getText (configFile >> "CfgVehicles" >> typeOf _target >> "displayName"), getText (configFile >> "CfgVehicles" >> typeOf _carriedObject >> "displayName")], "plain down", 0.3];
		}
		else
		{
			[] call JB_CO_DropAction;
			[_target, _carriedObject] remoteExec ["JB_IS_S_PushObject", 2]
		};
	};

	private _nearestContainer = [ASLtoAGL eyePos player, 5.0] call JB_IS_GetNearestContainer;

	if (not ([_nearestContainer, typeOf _target] call JB_IS_ContainerCanStoreObjectType)) then
	{
		titleText [format ["The %1 will not accept a %2", getText (configFile >> "CfgVehicles" >> typeOf _nearestContainer >> "displayName"), getText (configFile >> "CfgVehicles" >> typeOf _target >> "displayName")], "plain down", 0.3];
	}
	else
	{
		[_nearestContainer, _target] remoteExec ["JB_IS_S_PushObject", 2];
	};
};

OO_TRACE_DECL(JB_IS_C_PickUpObject) =
{
	params ["_object"];

	if ([_object] call JB_CO_PickUpActionCondition) then
	{
		[_object] call JB_CO_PickUpAction;
	};
};

JB_IS_UnloadCondition =
{
	params ["_target"];

	if (isNull _target) exitWith { false };

	if (vehicle player != player) exitWith { false };
	
	if (not (lifeState player in ["HEALTHY", "INJURED"])) exitWith { false };

	if (not ([_target] call JB_IS_IsContainer)) exitWith { false };

	private _data = _target getVariable ["JB_IS_ClientData", []];
	if (not (_data select JB_IS_C_CONTAINER_CANUNLOAD)) exitWith { false };

	if (not isNull ([player] call JB_CO_CarriedObject)) exitWith { false };

	//TODO: Have the server functions update a global variable on the container giving the type of the object which would be popped.  Reference that here.
	player setUserActionText [JB_IS_UnloadAction, format ["Unload from %1", getText (configFile >> "CfgVehicles" >> typeOf _target >> "displayName")]];
	
	true
};

OO_TRACE_DECL(JB_IS_Unload) =
{
	params ["_target"];

	// Switch to no weapon
	switch ([animationState player, "P"] call JB_fnc_getAnimationState) do
	{
		case "erc": { player playMoveNow "amovpercmstpsnonwnondnon" };
		case "knl": { player playMoveNow "amovpknlmstpsnonwnondnon" };
		case "pne": { player playMoveNow "amovppnemstpsnonwnondnon" };
	};
	player action ["switchweapon", player, player, -1];
	waitUntil { ([animationState player, "W"] call JB_fnc_getAnimationState) == "non" };

	[_target, getPos player] remoteExec ["JB_IS_S_PopObject", 2];
};

OO_TRACE_DECL(JB_IS_DeleteAllObjects) =
{
	params ["_container"];

	[_container] remoteExec ["JB_IS_S_DeleteAllObjects", 2];
};

OO_TRACE_DECL(JB_IS_DestroyAllObjects) =
{
	params ["_container"];

	[_container] remoteExec ["JB_IS_S_DestroyAllObjects", 2];
};

JB_IS_ContainerAddActions =
{
	params ["_container"];

	_container addEventHandler ["Deleted", { _this call JB_IS_DeleteAllObjects }];
	_container addEventHandler ["Killed", { _this call JB_IS_DestroyAllObjects }];
	//_container addEventHandler ["HandleDamage", {}]; //TODO: On a spike in global damage, destroy a fraction of the objects
};

if (not isServer && hasInterface) exitWith {};

JB_IS_S_CONTAINER_CS = 0;
JB_IS_S_CONTAINER_TOTALVOLUME = 1;
JB_IS_S_CONTAINER_ALLOCATEDVOLUME = 2;
JB_IS_S_CONTAINER_OBJECTFILTER = 3;
JB_IS_S_CONTAINER_CONTENTS = 4;

OO_TRACE_DECL(JB_IS_S_InitContainer) =
{
	params ["_container", "_volume", "_objectFilter"];

	private _data = [];
	_data set [JB_IS_S_CONTAINER_CS, call JB_fnc_criticalSectionCreate];
	_data set [JB_IS_S_CONTAINER_TOTALVOLUME, _volume];
	_data set [JB_IS_S_CONTAINER_ALLOCATEDVOLUME, 0];
	_data set [JB_IS_S_CONTAINER_OBJECTFILTER, _objectFilter];
	_data set [JB_IS_S_CONTAINER_CONTENTS, []];

	_container setVariable ["JB_IS_ServerData", _data];

	_data = [];
	_data set [JB_IS_C_CONTAINER_OBJECTFILTER, _objectFilter];
	_data set [JB_IS_C_CONTAINER_CANUNLOAD, _volume > 0];

	_container setVariable ["JB_IS_ClientData", _data, true];
};

OO_TRACE_DECL(JB_IS_S_PushObject) =
{
	params ["_container", "_object"];

	private _data = _container getVariable "JB_IS_ServerData";
	if (isNil "_data") exitWith { diag_log "JB_IS_S_PushObject called on non-container" };

	private _objectVolume = [_object] call JB_IS_ObjectVolume;

	(_data select JB_IS_S_CONTAINER_CS) call JB_fnc_criticalSectionEnter;

		switch (true) do
		{
			case (_data select JB_IS_S_CONTAINER_TOTALVOLUME == -1):
			{
				deleteVehicle _object;
			};

			case ((_data select JB_IS_S_CONTAINER_ALLOCATEDVOLUME) + _objectVolume <= _data select JB_IS_S_CONTAINER_TOTALVOLUME):
			{
				_data set [JB_IS_S_CONTAINER_ALLOCATEDVOLUME, (_data select JB_IS_S_CONTAINER_ALLOCATEDVOLUME) + _objectVolume];

				if (_object isEqualType []) then // Direct push of a collapsible object
				{
					(_data select JB_IS_S_CONTAINER_CONTENTS) pushBack _object; // [type-name, object-init, simple-object]
				}
				else
				{
					_object enableSimulationGlobal false;
					_object hideObjectGlobal true;

					private _objectInit = _object getVariable "JB_IS_S_OBJECT_INIT";
					if (not isNil "_objectInit") then // Collapsible object
					{
						(_data select JB_IS_S_CONTAINER_CONTENTS) pushBack [typeOf _object, _objectInit, isSimpleObject _object];
						deleteVehicle _object;
					}
					else
					{
						(_data select JB_IS_S_CONTAINER_CONTENTS) pushBack _object;
						_object setpos [-10000 + random 10000, -10000 + random 10000, random 10000];
					};
				};
			};
		};

	(_data select JB_IS_S_CONTAINER_CS) call JB_fnc_criticalSectionLeave;
};

OO_TRACE_DECL(JB_IS_S_PopObject) =
{
	params ["_container", "_position"];

	private _data = _container getVariable "JB_IS_ServerData";
	if (isNil "_data") exitWith { diag_log "JB_IS_S_PopObject called on non-container" };

	private _object = nil;

	(_data select JB_IS_S_CONTAINER_CS) call JB_fnc_criticalSectionEnter;

		private _contents = _data select JB_IS_S_CONTAINER_CONTENTS;

		if (count _contents > 0) then
		{
			_object = _contents deleteAt (count _contents - 1);

			_data set [JB_IS_S_CONTAINER_ALLOCATEDVOLUME, (_data select JB_IS_S_CONTAINER_ALLOCATEDVOLUME) - ([_object] call JB_IS_ObjectVolume)];
		};

	(_data select JB_IS_S_CONTAINER_CS) call JB_fnc_criticalSectionLeave;

	if (isNil "_object") exitWith {};

	if (_object isEqualType []) then // Collapsible object
	{
		private _createdObject = objNull;

		if (_object select 2) then
		{
			ATLtoASL (_position findEmptyPosition [0, 20, _object select 0]); // Find a clear spot
			_createdObject = createSimpleObject [_object select 0, ATLtoASL _position];
		}
		else
		{
			_createdObject = (_object select 0) createVehicle _position; // Will naturally find a clear spot
		};

		_createdObject setVariable ["JB_IS_S_OBJECT_INIT", _object select 1];

		[_createdObject] call (_object select 1); // reinitialize object

		if (not simulationEnabled _createdObject) then
		{
			_createdObject setPos [_position select 0, _position select 1, 0];
			_createdObject setVectorUp (surfaceNormal getPos _createdObject);
		};

		[_createdObject] remoteExec ["JB_IS_C_PickUpObject", remoteExecutedOwner];
	}
	else // Normal object that we've spirited away off-map
	{
		_object setPos (_position findEmptyPosition [0, 20, typeOf _object]); // Move it to a clear spot
		_object enableSimulationGlobal true;
		_object hideObjectGlobal false;

		[_object] remoteExec ["JB_IS_C_PickUpObject", remoteExecutedOwner];
	};
};

OO_TRACE_DECL(JB_IS_S_DeleteAllObjects) =
{
	params ["_container"];

	private _data = _container getVariable "JB_IS_ServerData";
	if (isNil "_data") exitWith { diag_log "JB_IS_S_DeleteAllObjects called on non-container" };

	(_data select JB_IS_S_CONTAINER_CS) call JB_fnc_criticalSectionEnter;

		private _contents = _data select JB_IS_S_CONTAINER_CONTENTS;

		while { count _contents > 0 } do
		{
			private _object = _contents deleteAt 0;

			if (_object isEqualType []) then
			{
				// Do nothing because no object exists
			}
			else
			{
				deleteVehicle _object;
			};
		};

		_data set [JB_IS_S_CONTAINER_ALLOCATEDVOLUME, 0];

	(_data select JB_IS_S_CONTAINER_CS) call JB_fnc_criticalSectionLeave;
};

OO_TRACE_DECL(JB_IS_S_DestroyAllObjects) =
{
	params ["_container"];

	private _data = _container getVariable "JB_IS_ServerData";
	if (isNil "_data") exitWith { diag_log "JB_IS_S_DestroyAllObjects called on non-container" };

	(_data select JB_IS_S_CONTAINER_CS) call JB_fnc_criticalSectionEnter;

		private _contents = _data select JB_IS_S_CONTAINER_CONTENTS;

		while { count _contents > 0 } do
		{
			private _object = _contents deleteAt 0;

			if (_object isEqualType []) then
			{
				// Do nothing because no object exists
			}
			else
			{
				// Bring the object to the container and destroy it.  Keep it hidden.
				_object enableSimulationGlobal true;
				_object setPos (getPos _container);
				_object setDamage 1;
			};
		};

	_data set [JB_IS_S_CONTAINER_ALLOCATEDVOLUME, 0];

	(_data select JB_IS_S_CONTAINER_CS) call JB_fnc_criticalSectionLeave;
};