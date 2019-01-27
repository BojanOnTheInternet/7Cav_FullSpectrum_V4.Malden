JB_DE_Explosives =
[
	[100000,	"ammo_Missile_Cruise_01",		"HeavyBombExplosion",				false],
	[6000,		"HelicopterExploBig",			"HelicopterExplosionEffects2",		false],
	[3000,		"SatchelCharge_Remote_Ammo",	"MineNondirectionalExplosion",		false],
	[2000,		"IEDUrbanBig_Remote_Ammo",		"IEDMineBigExplosion",				false],
	[2000,		"ATMine_Range_Ammo",			"ATMineExplosion",					false],
	[1500,		"HelicopterExploSmall",			"HelicopterExplosionEffects",		false],
	[1100,		"Bo_Mk82",						"BombExplosion",					false],
	[1000,		"SLAMDirectionalMine_Wire_Ammo","DirectionalMineExplosionBig",		false],
	[1000,		"IEDUrbanSmall_Remote_Ammo",	"IEDMineSmallExplosion",			false],
	[1000,		"DemoCharge_Remote_Ammo",		"MineNondirectionalExplosionSmall",	false],
	[150,		"RocketBase",					"HERocketExplosion",				true],
	[60,		"M_Titan_AA",					"AAMissileExplosion",				true],
	[52,		"Sh_82mm_AMOS",					"MortarExplosion",					false],
	[40,		"M_PG_AT",						"ATMissileExplosion",				true],
	[35,		"BombDemine_01_Ammo_F",			"DeminingExplosiveExplosion",		false],
	[25,		"Mo_cluster_AP_UXO3_Ammo_F",	"ClusterExplosionEffects",			false],
	[20,		"APERSBoundingMine_Range_Ammo",	"BoundingMineExplosion",			false],
	[10,		"APERSMine_Range_Ammo",			"MineExplosion",					false],
	[2,			"SmallSecondary",				"SencondaryExplosion",				false]
];

JB_DE_GetExplosives =
{
	params [["_includeMissiles", true, [true]]];

	if (not _includeMissiles) exitWith { JB_DE_Explosives select { not (_x select 3) } };

	+JB_DE_Explosives
};

JB_DE_GetExplosivesEquivalent =
{
	params ["_source", ["_includeMissiles", true, [true]]];

	if (_source isEqualType objNull) exitWith { (_source getVariable ["JB_DE_ExplosiveDamage", [0, false]]) call JB_DE_GetExplosivesEquivalent };

	private _damage = 0;

	switch (typeName _source) do
	{
		case typeName []: // Pairs of [magazing-type, magazine-count]
		{
			private _ammo = "";
			{
				_ammo = getText (configFile >> "CfgMagazines" >> _x select 0 >> "ammo");
				_hit = if (getNumber (configFile >> "CfgAmmo" >> _ammo >> "explosive") == 1) then { getNumber (configFile >> "CfgAmmo" >> _ammo >> "indirectHit") } else { getNumber (configFile >> "CfgAmmo" >> _ammo >> "hit") * 0.25 };
				_hit = _hit * (_x select 1);
				_damage = _damage + _hit;
			} forEach _magazines;
		};

		case typeName 0:
		{
			_damage = _source;
		};
	};

	if (_damage == 0) exitWith { [] };

	private _explosives = [_includeMissiles] call JB_fnc_detonateGetExplosives;

	private _equivalent = [];
	while { _damage > 10 } do
	{
		private _index = _explosives findIf { _x select 0 < _damage };
		if (_index == -1) exitWith {};
		_equivalent pushBack (_explosives select _index);
		_damage = _damage - (_explosives select _index select 0);
	};

	_equivalent
};

JB_DE_DetonateExplosives =
{
	_this spawn
	{
		params ["_explosives", "_position", "_duration"];

		if (count _explosives == 0) exitWith {};
		if (count _explosives == 1) exitWith { [_explosives select 0, _position] call JB_fnc_detonateExplosive };

		private _largest = log (_explosives select 0 select 0);
		private _smallest = log (_explosives select (count _explosives - 1) select 0);
		private _span = (_largest - _smallest) max 1.0; // If no span, just throw in a number.  All of the explosives will go up immediately.

		private _startTime = diag_tickTime;
		{
			_detonationTime = _startTime + (_largest - log (_x select 0)) / _span * _duration;
			_delay = _detonationTime - diag_tickTime;
			if (_delay > 0) then { sleep _delay };
			[_x, _position] call JB_fnc_detonateExplosive;
		} forEach _explosives;
	};
};

JB_DE_DetonateExplosive =
{
	params ["_explosive", "_position"];

	private _object = (_explosive select 1) createVehicle _position;
	[_object, random 180, random 180] call BIS_fnc_setPitchBank;
	if (not (_explosive select 3)) then { _object setDamage 1 };
};

