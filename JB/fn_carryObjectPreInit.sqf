#include "..\OO\oo.h"

#define MASS_CHECK_INTERVAL 5

JB_CO_ActionsUpdateTime = 0;

OO_TRACE_DECL(JB_CO_PickUpAction) =
{
	_this spawn
	{
		params ["_object"];

		// Switch to no weapon
		switch ([animationState player, "P"] call JB_fnc_getAnimationState) do
		{
			case "erc": { player playMoveNow "amovpercmstpsnonwnondnon" };
			case "knl": { player playMoveNow "amovpknlmstpsnonwnondnon" };
			case "pne": { player playMoveNow "amovppnemstpsnonwnondnon" };
		};
		player action ["switchweapon", player, player, -1];
		waitUntil { ([animationState player, "W"] call JB_fnc_getAnimationState) == "non" };

		private _dimensions = (boundingBoxReal _object) select 1;
		private _rotate = (_dimensions select 0) < (_dimensions select 1);
		private _offset = if (_rotate) then { _dimensions select 0 } else { _dimensions select 1 };
		_offset = _offset + 0.2; // Body thickness

		if (not local _object) then
		{
			[[_object, player], { (_this select 0) setOwner owner (_this select 1) }] remoteExec ["call", 2];
			[{ local _object }, 2.0] call JB_fnc_timeoutWaitUntil;
		};
		if (not local _object) exitWith {};

		_object setVelocity [0,0,1]; sleep 0.1; // Jostle the object to cause nearby objects to react to its movement
		_object attachto [player, [0, _offset, 0], "pelvis"];
		if (_rotate) then { _object setDir 90 };

		private _continueMonitor = true;
		private _player = player;
		private _massCheckTime = 0;
		while { _continueMonitor && alive _object && { attachedTo _object == _player } } do
		{
			if (not (lifeState _player in ["HEALTHY", "INJURED"])) exitWith {};
			if (vehicle _player != _player) exitWith {};
			if (currentWeapon _player != "") exitWith {};

			if (diag_tickTime > _massCheckTime) then
			{
				private _carry = _object getVariable "JB_CO_Object";
				private _limits = _player getVariable "JB_CO_Player";
				private _objectMass = [_object] call (_carry select 1);
				_player allowSprint (if (_objectMass > 0) then { false } else { true });
				_player forceWalk (if (_objectMass > (_limits select 0)) then { true } else { false });

				if (_objectMass > (_limits select 1)) exitWith { titleText [format ["The %1 is too heavy for you to carry", getText (configFile >> "CfgVehicles" >> typeOf _object >> "displayName")], "plain down", 0.3]; _continueMonitor = false };

				_massCheckTime = diag_tickTime + MASS_CHECK_INTERVAL;
			};

			sleep 1;
		};

		if (attachedTo _object == _player) then
		{
			[] call JB_CO_DropAction;

			if (vehicle _player != _player) then
			{
				private _getInPoint = ([vehicle _player, [assignedVehicleRole _player select 0]] call JB_fnc_getInPoints) select 0 select 1 select 0 select 0;
				_object setPos (_getInPoint vectorAdd [0,0,1]); // Add the rough drop height
			};
		};
	};

	0
};

JB_CO_PickUpActionCondition =
{
	params ["_object"];

	if (vehicle player != player) exitWith { false };

	if (not (lifeState player in ["HEALTHY", "INJURED"])) exitWith { false };

	if (not isNull ([player] call JB_CO_CarriedObject)) exitWith { false };

	if (not ([_object, player] call JB_CO_ObjectCanBeCarried)) exitWith { false };

	private _actionID = (player getVariable "JB_CO_Player") select 2;
	player setUserActionText [_actionID, format ["Pick up %1", getText (configFile >> "CfgVehicles" >> typeOf _object >> "displayName")]];

	true;
};

JB_CO_ObjectCanBeCarried =
{
	params ["_object", "_player"];

	if (not isNull attachedTo _object) exitWith { false };

	private _objectCarry = _object getVariable ["JB_CO_Object", []];
	if (count _objectCarry == 0) exitWith { false };

	if (not ([_player] call (_objectCarry select 0))) exitWith { false };

	private _playerCarry = _player getVariable ["JB_CO_Player", []];
	if (count _playerCarry == 0) exitWith { false };

	true
};

JB_CO_CarriedObject =
{
	params ["_player"];

	private _objects = (attachedObjects _player) select { not isNull _x };
	private _carriedIndex = _objects findIf { count (_x getVariable ["JB_CO_Object", []]) > 0 };

	if (_carriedIndex == -1) exitWith { objNull };

	_objects select _carriedIndex
};

OO_TRACE_DECL(JB_CO_DropAction) =
{
	private _object = [player] call JB_CO_CarriedObject;

	detach _object;

	if (not simulationEnabled _object) then
	{
		private _positionATL = getPosATL _object;
		_positionATL set [2, 0];
		_object setPosATL _positionATL;

		_object setVectorUp (surfaceNormal getPos _object);
	};

	player forceWalk false;
	player allowSprint true;
};

JB_CO_DropActionCondition =
{
	if (vehicle player != player) exitWith { false };

	if (not (lifeState player in ["HEALTHY", "INJURED"])) exitWith { false };

	private _object = [player] call JB_CO_CarriedObject;

	if (isNull _object) exitWith { false };

	if (isObjectHidden _object) exitWith { false };

	private _actionID = (player getVariable "JB_CO_Player") select 3;
	player setUserActionText [_actionID, format ["Drop %1", getText (configFile >> "CfgVehicles" >> typeOf _object >> "displayName")]];

	true
};
