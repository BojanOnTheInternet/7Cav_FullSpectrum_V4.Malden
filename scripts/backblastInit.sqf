player addEventHandler ["FiredMan",
{
	params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_vehicle"];
	
	if (_weapon != secondaryWeapon _unit) exitWith {};

	private _orientation = [_unit] call JB_fnc_weaponOrientation;

	private _position = _orientation select 0;
	private _forward = _orientation select 1;

	private _blastDirection = _forward vectorMultiply -1.0;
	private _blastPosition = _position vectorAdd (_blastDirection vectorMultiply 0.5);

	[player, _blastPosition, _blastDirection, 5, 80, 10, 180] call JB_fnc_concussBlastArea;
}];
