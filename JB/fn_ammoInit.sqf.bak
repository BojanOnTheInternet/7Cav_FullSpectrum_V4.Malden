/*

Initialize a vehicle for use with the ammo transfer system.

[unit, capacity, transfers, stores] call JB_fnc_ammoInit;

	unit		- the vehicle or player being initialized
	capacity	- the kilogram weight capacity that can be transported by the unit
	transfers	- a number and code pair.  The number indicates the maximum distance
				  that an ammo source will be considered for transfers.  The code
				  is responsible for returning a boolean indication if the unit will
				  transfer ammo to/from that source.  This code is invoked as

				  [unit, candidate] call code
	stores		- an array of pairs that specifies the initial stores of ammo in this
				  unit.  Each pair consists of a magazine type and a count of rounds.

See also JB_fnc_ammoInitPlayer and JB_fnc_ammoInitTrolley

*/
private _unit = param [0, objNull, [objNull]];
private _capacity = param [1, 0, [0]];

// The ammo storage capacity of the object, expressed in kg.
_unit setVariable ["JBA_TransportCapacity", _capacity, true]; // everyone needs to know this

// If the unit is killed, have the owning client tell the server to detonate the unit's internal stores
private _addHandlers =
{
	params ["_unit"];

	_unit addEventHandler ["Killed", { [_this select 0, 0.2 + random 0.3] remoteExec ["JBA_S_DetonateStores", 2] }];
};
[_unit, _addHandlers] remoteExec ["call", 0, true]; //JIP

if (count _this > 2) then
{
	// Given a source of ammo, the filter on that source tells us to which objects it can make direct ammo transfers
	_unit setVariable ["JBA_DirectTransferFilter", _this select 2];
};

if (count _this > 3 && isServer) then
{
	_unit setVariable ["JBA_S_TransportStores", _this select 3];
};

