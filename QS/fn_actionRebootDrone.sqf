params ["_target"];

private _skillNames = (configProperties [configFile >> "CfgAiSkill"]) apply { configName _x };
private _skills = _skillNames apply { [_x, (driver _target) skill _x] };

{ deleteVehicle _x } forEach crew _target;

player playAction "PutDown";

createVehicleCrew _target;

{
	private _crew = _x;
	{ _crew setSkill _x } forEach _skills;
} forEach crew _target;

group driver _target allowFleeing 0.0;

if (hasInterface) then { systemchat format ["New drone software loaded into %1", getText (configFile >> "CfgVehicles" >> typeOf _target >> "displayName")] };