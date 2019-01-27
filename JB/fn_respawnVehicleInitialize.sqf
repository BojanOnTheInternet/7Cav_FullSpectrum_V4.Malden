/*

[vehicle, vehicleInit] call JB_fnc_respawnVehicleInitialize

Set up a vehicle for respawn

_null = [MyVehicle, { MyVehicle engineOn true }] call JB_fnc_respawnVehicleInitialize;

vehicle			- the vehicle to be respawned (required)
vehicleInit		- the script which is executed whenever the vehicle is created. (optional)

				  vehicleInit is called by this function as part of respawn initialization:

						[newVehicle, oldVehicle] call vehicleInit;
*/

if (!isServer) exitWith {};

#define DEFAULT_VEHICLEINIT nil

private _vehicle = param [0, objNull, [objNull]];
private _vehicleInit = param [1, DEFAULT_VEHICLEINIT, [{}]];

diag_log format ["RespawnVehicleInitialize: %1", typeOf _vehicle];

[[_vehicle]] call SERVER_CurateEditableObjects;

_vehicle setVariable ["JB_RV_StartPosition", getPosASL _vehicle];
_vehicle setVariable ["JB_RV_StartDirection", getDir _vehicle];
_vehicle setVariable ["JB_RV_VehiclePylonMagazines", getPylonMagazines _vehicle];
_vehicle setVariable ["JB_RV_VehicleTextures", getObjectTextures _vehicle];

private _animationSources = ("getText (_x >> 'source') == 'user'" configClasses (configFile >> "CfgVehicles" >> typeOf _vehicle >> "AnimationSources")) apply { [configName _x, _vehicle animationPhase configName _x] };
_vehicle setVariable ["JB_RV_AnimationSources", _animationSources];

if (!isNil "_vehicleInit") then
{
	[_vehicle, "JB_RespawnVehicleInitialize", _vehicleInit] call JB_RV_SetInitializer;
	[_vehicle, objNull] call _vehicleInit;
};

[_vehicle] spawn JB_RV_Monitor;