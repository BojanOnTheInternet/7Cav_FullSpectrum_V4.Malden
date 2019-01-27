// Derived from XENO's Taru pod handling script

#define DISTANCE_FROM_POD 5

JBTPI_HasParentClass =
{
	params ["_unit", "_parentClasses"];

	private _hasParentClass = false;
	{
		if (_x in _parentClasses) exitwith { _hasParentClass = true };
	} foreach ([(configfile >> "CfgVehicles" >> typeOf _unit), true] call BIS_fnc_returnParents);

	_hasParentClass;
};

JBTPI_PositionedPod =
{
	params ["_taru"];

	private _pod = objNull;
	{
		if (_x != _taru && { [_x, ["Pod_Heli_Transport_04_base_F", "Pod_Heli_Transport_04_crewed_base_F"]] call JBTPI_HasParentClass }) then
		{
			private _relativeDirection = ([_x, _taru] call BIS_fnc_relativeDirTo);
			if (_relativeDirection > 330 || _relativeDirection < 30) then { _pod = _x };
		};
		if (not isNull _pod) exitWith {};
	} forEach nearestObjects [_taru, ["All"], 5];

	_pod;
};

JBTPI_AttachPodCondition =
{
	params ["_taru", "_pilot"];

	if (vehicle _pilot != _taru) exitWith { false };

	if (not isNull ([_taru] call JBTPI_AttachedPod)) exitWith { false };

	if (count ropes _taru > 0) exitWith { false };

	not isNull ([_taru] call JBTPI_PositionedPod)
};

JBTPI_AttachPod =
{
	params ["_taru", "_pilot"];

	private _taruMass = getMass _taru;

	private _pod = ([_taru] call JBTPI_PositionedPod);
	private _podMass = getMass _pod;

	if (_pod isKindOf "Land_Pod_Heli_Transport_04_bench_F") exitwith
	{
		_pod attachTo [_taru, [0, 0, -1.38]];
		_taru setCustomWeightRTD 680;
		_taru setmass _taruMass + _podMass;
	};

	if (_pod isKindOf "Land_Pod_Heli_Transport_04_covered_F") exitwith
	{
		_pod attachTo [_taru, [0, -1.05, -0.95]];
		_taru setCustomWeightRTD 1413;
		_taru setmass _taruMass + _podMass;
	};

	if (_pod isKindOf "Land_Pod_Heli_Transport_04_fuel_F") exitwith
	{
		_pod attachTo [_taru, [0, -0.4, -1.32]];
		_taru setCustomWeightRTD 13311;
		_taru setmass _taruMass + _podMass;
	};

	if (_pod isKindOf "Land_Pod_Heli_Transport_04_medevac_F") exitwith
	{
		_pod attachTo [_taru, [0, -1.05, -1.05]];
		_taru setCustomWeightRTD 1321;
		_taru setmass _taruMass + _podMass;
	};

	// "Land_Pod_Heli_Transport_04_repair_F", "Land_Pod_Heli_Transport_04_box_F", "Land_Pod_Heli_Transport_04_ammo_F"

	_pod attachTo [_taru, [0, -1.12, -1.22]];
	[[_pod, _taru], { (_this select 0) setOwner owner (_this select 1) }] remoteExec ["call", 2];
	_taru setCustomWeightRTD 1270;
	_taru setmass _taruMass + _podMass;
};

JBTPI_AttachedPod =
{
	params ["_taru"];

	private _pod = objNull;
	{
		if ([_x, ["Pod_Heli_Transport_04_base_F", "Pod_Heli_Transport_04_crewed_base_F"]] call JBTPI_HasParentClass) exitWith { _pod = _x };
	} forEach attachedObjects _taru;

	_pod
};

JBTPI_ReleasePodCondition =
{
	params ["_taru", "_pilot"];

	if (vehicle _pilot != _taru) exitWith { false };

	not isNull ([_taru] call JBTPI_AttachedPod);
};

JBTPI_ReleasePod =
{
	params ["_taru", "_pilot"];

	private _pod = [_taru] call JBTPI_AttachedPod;

	if (isNull _pod) exitWith {};

	[_taru, false] remoteExec ["allowDamage", _taru];
	[_pod, false] remoteExec ["allowDamage", _pod];

	detach _pod;

	_taru setCustomWeightRTD 0;
	_taru setmass (getMass _taru) - (getMass _pod);

	[_taru, _pod] call JB_fnc_popCargoChute;

	// Introduce a delay before allowing damage so the pod can get clear of the Taru's cargo hook.  Without
	// such a delay, the two objects intersect, producing explosions, ejections, and other mayhem.

	[_taru, _pod] spawn
	{
		params ["_taru", "_pod"];

		sleep 2;

		[_taru, true] remoteExec ["allowDamage", _taru];
		[_pod, true] remoteExec ["allowDamage", _pod];
	};
};

JBTPI_SetupClient =
{
	params ["_taru", "_cargoTypes"];

	if (not alive _taru) exitWith {};

	_taru setVariable ["JBPCC_CargoData", _cargoTypes];

	if (not hasInterface) exitWith {};

	_taru addAction ["Attach pod", { _this call JBTPI_AttachPod }, nil, 0, false, true, "", "[_target, _this] call JBTPI_AttachPodCondition"];
	_taru addAction ["Release pod", { _this call JBTPI_ReleasePod }, nil, 0, false, true, "", "[_target, _this] call JBTPI_ReleasePodCondition"];
};