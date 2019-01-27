_this spawn
{
	params ["_player"];

    private _can = "Land_Can_V3_F" createVehicleLocal [-10000 + random 10000, -10000 + random 10000, random 10000];
    _can setMass 1e10;
    _can attachTo [_player, [0,0,0], "spine3"];
    _can setVelocity [0,0,6];
    _player allowDamage false;
    detach _can;

    [_player, _can] spawn
    {
        deleteVehicle (_this select 1);
        (_this select 0) allowDamage true;
    };
};