(_this select 0) setAmmoCargo 0;

private _capacity = 50000;
private _ammo = [];
if (isServer) then
{
	private _weight = [SERVER_Ammo_Vehicle] call JBA_StoresMass;
	private _copies = floor (_capacity / _weight);
	_ammo = SERVER_Ammo_Vehicle apply { [_x select 0, (_x select 1) * _copies] };
};

[_this select 0, _capacity,	[4, AmmoFilter_TransferInLoadingBay], _ammo] call JB_fnc_ammoInit;
